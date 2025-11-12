codeunit 137159 "SCM Warehouse VII"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        isInitialized := false;
    end;

    var
        LocationWhite: Record Location;
        LocationBlue: Record Location;
        LocationSilver: Record Location;
        LocationRed: Record Location;
        LocationGreen: Record Location;
        LocationYellow: Record Location;
        LocationBlack: Record Location;
        LocationOrange: Record Location;
        LocationInTransit: Record Location;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalBatch: Record "Job Journal Batch";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        InventoryMovementConfirmMessage: Label 'Do you want to create Inventory Movement?';
        InventoryMovementCreated: Label 'Invt. Movement activity number';
        InternalMovementHeaderDelete: Label '%1 must be deleted.';
        QuantityMustBeSame: Label 'Quantity must be same.';
        PostJobJournalLines: Label 'Do you want to post the journal lines';
        JobJournalPosted: Label 'The journal lines were successfully posted';
        ReservationConfirmMessage: Label 'Automatic reservation is not possible.';
        ReservationNotPossibleMessage: Label 'Full automatic Reservation is not possible.';
        InventoryMovementCreatedMessage: Label 'Number of Invt. Movement activities created';
        TotalBaseQuantityError: Label 'The total base quantity to take %1 must be equal to the total base quantity to place', Comment = '%1 = Quantity.';
        PostJournalLinesConfirmationMessage: Label 'Do you want to post the journal lines';
        JournalLinesPostedMessage: Label 'The journal lines were successfully posted';
        ItemNotOnInventoryError: Label 'Item %1 is not in inventory.', Comment = '%1 = Item No.';
        UndoShipmentConfirmationMessage: Label 'Do you really want to undo the selected Shipment lines?';
        UndoReceiptConfirmationMessage: Label 'Do you really want to undo the selected Receipt lines?';
        WarehouseShipmentRequiredError: Label 'Warehouse Shipment is required';
        WarehouseReceiveRequiredError: Label 'Warehouse Receive is required';
        UndoReturnReceiptConfirmationMessage: Label 'Do you really want to undo the selected Return Receipt lines?';
        NotMadeOrderErr: Label '%1 of %2 %3 in %4 %5 cannot be more than %6.', Comment = '%1 = PurchaseLine."Qty. to Receive (Base)",%2 = PurchaseLine.Type,%3 = PurchaseLine."No.",%4 = PurchaseLine."Line No."';
        UndoShipmentAfterPickedConfirmationMsg: Label 'The items have been picked. If you undo line';
        SpecificReservationTxt: Label 'Do you want to reserve specific';
        WarehouseEntryMsg: Label 'The Warehouse Entry is not correct after undo Sales Shipment Lines.';
        WrongQuantityBaseErr: Label 'Quantity (Base) must not be';
        WrongQtyToHandleBaseErr: Label 'Qty. to Handle (Base) in the item tracking';
        ItemTrackingQuantityMsg: Label 'The corrections cannot be saved as excess quantity has been defined.\Close the form anyway?';
        BlankCodeErr: Label 'Code must be filled in. Enter a value.';
        UsageNotLinkedToBlankLineTypeMsg: Label 'Usage will not be linked to the project planning line because the Line Type field is empty';
        ReservationSpecificTrackingConfirmMessage: Label 'Do you want to reserve specific tracking numbers?';
        CrossDockQtyIsNotCalculatedMsg: Label 'Cross-dock quantity is not calculated';
        JobIsNotFoundErr: Label 'Job is not found.';
        PickQtyAndQtyPickedMustMatchErr: Label 'PickQty and Qty. Picked must match.';
        RegInvtMovementHdrDoesNotExistErr: Label 'Registered Invt. Movement Hdr. does not exist.';
        RegisterWhseMessageLbl: Label 'The journal lines were successfully registered.You are now';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        ILEMustNotBeFoundMoreThanErr: Label 'Item Ledger Entry must not be found more than %1', Comment = 'Count of Item Ledger Entry';
        TrackingOption: Option AssignLotNoWithExpirationDate,VerifyExpirationDate;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePutAwayFromPurchaseOrderOnLocationWithBins()
    begin
        // Setup.
        Initialize();
        PostShipmentAfterRegisterPickWithReservedQuantity(false, false, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPutAwayFromPurchaseOrderOnLocationWithBins()
    begin
        // Setup.
        Initialize();
        PostShipmentAfterRegisterPickWithReservedQuantity(true, false, false, false);  // Register Put-away as TRUE.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickWithReservedQuantityOnLocationWithBins()
    begin
        // Setup.
        Initialize();
        PostShipmentAfterRegisterPickWithReservedQuantity(true, true, false, false);  // Register Put-away and Create Pick as TRUE.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickWithReservedQuantityOnLocationWithBins()
    begin
        // Setup.
        Initialize();
        PostShipmentAfterRegisterPickWithReservedQuantity(true, true, true, false);  // Register Put-away, Create Pick and Register Pick as TRUE.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PostShipmentWithReservedQuantityOnLocationWithBins()
    begin
        // Setup.
        Initialize();
        PostShipmentAfterRegisterPickWithReservedQuantity(true, true, true, true);  // Register Put-away, Create Pick, Register Pick and Post Shipment as TRUE.
    end;

    local procedure PostShipmentAfterRegisterPickWithReservedQuantity(RegisterPutAway: Boolean; CreatePickFromSalesOrder: Boolean; RegisterPick: Boolean; PostShipment: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
    begin
        // Create and release Purchase Order. Create Warehouse Receipt from Purchase Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Item."No.", Quantity, LocationSilver.Code, false);

        // Exercise.
        PostWarehouseReceipt(PurchaseHeader."No.");

        // Verify.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, ItemLedgerEntry."Document Type"::"Purchase Receipt", LocationSilver.Code, Item."No.", '',
          '', Quantity);

        if RegisterPutAway then begin
            // Exercise.
            FindBin(Bin, LocationSilver);
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::"Put-away");

            // Verify.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Source Document"::"P. Order", Item."No.",
              LocationSilver."Receipt Bin Code", '', -Quantity, false);
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Source Document"::"P. Order", Item."No.", Bin.Code, '', Quantity, false);
        end;

        if CreatePickFromSalesOrder then begin
            // Exercise.
            CreateWarehouseShipmentFromSalesOrder(
              SalesHeader, SalesLine, '', Item."No.", Quantity, LocationSilver.Code, true);  // TRUE for Reserve.
            CreatePick(SalesHeader."No.");

            // Verify.
            VerifyWarehousePickLine(WarehouseActivityLine."Action Type"::Take, SalesHeader."No.", Item."No.", Quantity, Bin.Code);
            VerifyWarehousePickLine(
              WarehouseActivityLine."Action Type"::Place, SalesHeader."No.", Item."No.", Quantity, LocationSilver."Shipment Bin Code");
        end;

        if RegisterPick then begin
            // Exercise.
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

            // Verify.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Source Document"::"S. Order", Item."No.", Bin.Code, '', -Quantity, false);
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Source Document"::"S. Order", Item."No.",
              LocationSilver."Shipment Bin Code", '', Quantity, false);
        end;

        if PostShipment then begin
            // Exercise.
            PostWarehouseShipment(SalesHeader."No.");

            // Verify.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::"Negative Adjmt.", WarehouseEntry."Source Document"::"S. Order", Item."No.",
              LocationSilver."Shipment Bin Code", '', -Quantity, false);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReservationPageHandler,MessageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure PickWithUnreservedQuantityWithAlwaysCreatePickLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Quantity: Decimal;
        OldAlwaysCreatePickLine: Boolean;
    begin
        // Setup: Update Always Create Pick Line on Location. Create Warehouse Shipment from Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        OldAlwaysCreatePickLine := UpdateAlwaysCreatePickLineOnLocation(LocationWhite, true);
        CreateItem(Item, Item.Reserve::Always, Item."Reordering Policy");
        CreateAndReleaseSalesOrderByPage(SalesHeader, Item."No.", LocationWhite.Code, Quantity);
        CreateWarehouseShipment(SalesHeader);

        // Exercise.
        CreatePick(SalesHeader."No.");

        // Verify.
        VerifyWarehousePickLine(WarehouseActivityLine."Action Type"::Take, SalesHeader."No.", Item."No.", Quantity, '');
        VerifyWarehousePickLine(
          WarehouseActivityLine."Action Type"::Place, SalesHeader."No.", Item."No.", Quantity, LocationWhite."Shipment Bin Code");

        // Tear Down.
        UpdateAlwaysCreatePickLineOnLocation(LocationWhite, OldAlwaysCreatePickLine);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentFromSalesOrder()
    begin
        // Setup.
        Initialize();
        PostSalesInvoiceWithItemChargeAndGetShipmentLines(false);  // Post Sales Invoice as FALSE.
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesPageHandler,ItemChargeAssignmentSalesPageHandler,SalesShipmentLinePageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithPostedShipmentNoWithItemCharge()
    begin
        // Setup.
        Initialize();
        PostSalesInvoiceWithItemChargeAndGetShipmentLines(true);  // Post Sales Invoice as TRUE.
    end;

    local procedure PostSalesInvoiceWithItemChargeAndGetShipmentLines(PostSalesInvoice: Boolean)
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostngSetup: Record "VAT Posting Setup";
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Quantity: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Create Customer. Create Warehouse Shipment from Sales Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        CreateWarehouseShipmentFromSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", Quantity, LocationBlue.Code, false);

        // Exercise.
        PostWarehouseShipment(SalesHeader."No.");

        // Verify.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Sale, ItemLedgerEntry."Document Type"::"Sales Shipment", LocationBlue.Code, Item."No.", '', '',
          -Quantity);

        if PostSalesInvoice then begin
            // Exercise: Create and post Sales Invoice with same No. as Posted Sales Shipment.
            PostedDocumentNo :=
              PostSalesInvoiceWithGetShipmentLinesAndItemCharge(
                SalesLine2, FindPostedSalesShipment(Customer."No.", SalesHeader."No."), Customer."No.");

            // Verify item charge entry
            ItemCharge.Get(SalesLine2."No.");
            CustomerPostingGroup.Get(Customer."Customer Posting Group");
            GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", ItemCharge."Gen. Prod. Posting Group");
            VATPostngSetup.Get(Customer."VAT Bus. Posting Group", ItemCharge."VAT Prod. Posting Group");
            VerifyGLEntryByGenPostingGroups(
                GeneralPostingSetup, VATPostngSetup, PostedDocumentNo, GeneralPostingSetup."Sales Account", -SalesLine2."Line Amount");

            // Verify item entry
            CustomerPostingGroup.Get(Customer."Customer Posting Group");
            GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
            VATPostngSetup.Get(Customer."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
            VerifyGLEntryByGenPostingGroups(
                GeneralPostingSetup, VATPostngSetup, PostedDocumentNo, GeneralPostingSetup."Sales Account", -SalesLine."Line Amount");
            VerifyGLEntry(
              PostedDocumentNo, CustomerPostingGroup."Receivables Account",
              SalesLine."Amount Including VAT" + SalesLine2."Amount Including VAT", false);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemSelectedOnItemsByLocationMatrixPage()
    var
        Item: Record Item;
        ItemsbyLocation: TestPage "Items by Location";
    begin
        // [SCENARIO 278254] Stan opens "Items by Location" page from Item List and can see that matrix subform is positioned to item selected in Item List
        Initialize();
        LibraryInventory.CreateItem(Item);

        ItemsbyLocation.Trap();
        OpenItemsByLocationPageFromItemCard(Item."No.");

        ItemsbyLocation.MatrixForm."No.".AssertEquals(Item."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemIsNotModifiedAfterItemByLocationsPageIsOpened()
    var
        Item: Record Item;
        ItemsbyLocation: TestPage "Items by Location";
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);

        Item."Last DateTime Modified" := 0DT;
        Item."Last Date Modified" := 0D;
        Item."Last Time Modified" := 0T;
        Item.Modify();

        ItemsbyLocation.Trap();
        OpenItemsByLocationPageFromItemCard(Item."No.");

        Item.Find();
        Item.TestField("Last DateTime Modified", 0DT);
        Item.TestField("Last Date Modified", 0D);
        Item.TestField("Last Time Modified", 0T);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingLocationOnInventoryMovement()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Location: Record Location;
    begin
        // Setup.
        Initialize();
        LibraryWarehouse.CreateInventoryMovementHeader(WarehouseActivityHeader, '');

        // Exercise.
        asserterror WarehouseActivityHeader.Validate("Location Code", LocationWhite.Code);

        // Verify.
        Assert.ExpectedTestFieldError(Location.FieldCaption("Directed Put-away and Pick"), Format(false));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure GetBinContentOnInternalMovementWithSerial()
    begin
        // Setup.
        Initialize();
        InvtMovementFromInternalMovementWithSerial(false);  // Inventory Movement as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventorytMovementAfterGetBinContentWithSerial()
    begin
        // Setup.
        Initialize();
        InvtMovementFromInternalMovementWithSerial(true);  // Inventory Movement as TRUE.
    end;

    local procedure InvtMovementFromInternalMovementWithSerial(InventoryMovement: Boolean)
    var
        Item: Record Item;
        Bin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin2: Record Bin;
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
        Quantity: Decimal;
    begin
        // Create Item with Serial Item Tracking Code. Create Item Journal Line and update Expiration Date on Reservation Entry. Post Item Journal Line. Create Internal Movement with Get Bin Content.
        Quantity := LibraryRandom.RandInt(100);
        CreateTrackedItemAndUpdateInventoryOnLocationWithBin(
          Item, Bin, Quantity, false, true, true, '', LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingMode::AssignSerialNo, true);

        // Exercise.
        CreateInternalMovementWithGetBinContent(InternalMovementHeader, Bin2, Bin, Item."No.");

        // Verify.
        VerifyInternalMovementLine(Bin, Item."No.", Bin2.Code, Quantity);

        if InventoryMovement then begin
            // Exercise.
            CreateInventoryMovementFromInternalMovement(InternalMovementHeader);

            // Verify: Verify Empty Internal Movement Header and Inventory Movement Lines for Serial.
            VerifyInternalMovementHeaderExists(LocationSilver.Code, Bin2.Code);
            VerifyInventoryMovementLinesForSerial(Bin, WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);
            VerifyInventoryMovementLinesForSerial(Bin2, WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GetBinContentOnInternalMovementWithLot()
    begin
        // Setup.
        Initialize();
        InvtMovementFromInternalMovementWithLot(false);  // Inventory Movement as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementAfterGetBinContentWithLot()
    begin
        // Setup.
        Initialize();
        InvtMovementFromInternalMovementWithLot(true);  // Inventory Movement as TRUE.
    end;

    local procedure InvtMovementFromInternalMovementWithLot(InventoryMovement: Boolean)
    var
        Item: Record Item;
        Bin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin2: Record Bin;
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // Create Item with Lot Item Tracking Code. Create Item Journal Line and update Expiration Date on Reservation Entry. Post Item journal Line. Create Internal Movement with Get Bin Content.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateTrackedItemAndUpdateInventoryOnLocationWithBin(
          Item, Bin, Quantity, true, false, true, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingMode::AssignLotNo, true);
        GetLotNoFromItemTrackingPageHandler(LotNo);

        // Exercise.
        CreateInternalMovementWithGetBinContent(InternalMovementHeader, Bin2, Bin, Item."No.");

        // Verify.
        VerifyInternalMovementLine(Bin, Item."No.", Bin2.Code, Quantity);

        if InventoryMovement then begin
            // Exercise.
            CreateInventoryMovementFromInternalMovement(InternalMovementHeader);

            // Verify: Verify Empty Internal Movement Header Inventory Movement Lines for Lot.
            VerifyInternalMovementHeaderExists(LocationSilver.Code, Bin2.Code);
            VerifyInventoryMovementLineForLot(Bin, WarehouseActivityLine."Action Type"::Take, Item."No.", LotNo, Quantity);
            VerifyInventoryMovementLineForLot(Bin2, WarehouseActivityLine."Action Type"::Place, Item."No.", LotNo, Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,WhseItemTrackingLinesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventorytMovementAfterInternalMovementWithSerial()
    var
        Item: Record Item;
        Bin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin2: Record Bin;
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
        WhseItemTrackingMode: Option SelectSerialNo,SelectLotNo;
        Quantity: Decimal;
    begin
        // Setup: Create Item with Serial Item Tracking Code. Create Item Journal Line and update Expiration Date on Reservation Entry. Post Item Journal Line. Create Internal Movement.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);
        CreateTrackedItemAndUpdateInventoryOnLocationWithBin(
          Item, Bin, Quantity, false, true, true, '', LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingMode::AssignSerialNo, true);
        CreateInternalMovement(InternalMovementHeader, Bin2, Bin, Item."No.", Quantity, WhseItemTrackingMode::SelectSerialNo);

        // Exercise.
        CreateInventoryMovementFromInternalMovement(InternalMovementHeader);

        // Verify: Verify Empty Internal Movement Header and Inventory Movement Lines for Serial.
        VerifyInternalMovementHeaderExists(LocationSilver.Code, Bin2.Code);
        VerifyInventoryMovementLinesForSerial(Bin, WarehouseActivityLine."Action Type"::Take, Item."No.", Quantity);
        VerifyInventoryMovementLinesForSerial(Bin2, WarehouseActivityLine."Action Type"::Place, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhseItemTrackingLinesPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementAfterInternalMovementWithLot()
    var
        Item: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
        WhseItemTrackingMode: Option SelectSerialNo,SelectLotNo;
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // Setup: Create Item with Lot Item Tracking Code. Create Item Journal Line and update Expiration Date on Reservation Entry. Post Item Journal Line. Create Internal Movement.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateTrackedItemAndUpdateInventoryOnLocationWithBin(
          Item, Bin, Quantity, true, false, true, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingMode::AssignLotNo, true);
        GetLotNoFromItemTrackingPageHandler(LotNo);
        CreateInternalMovement(InternalMovementHeader, Bin2, Bin, Item."No.", Quantity, WhseItemTrackingMode::SelectLotNo);

        // Exercise.
        CreateInventoryMovementFromInternalMovement(InternalMovementHeader);

        // Verify: Verify Empty Internal Movement Header Inventory Movement Lines for Lot.
        VerifyInternalMovementHeaderExists(LocationSilver.Code, Bin2.Code);
        VerifyInventoryMovementLineForLot(Bin, WarehouseActivityLine."Action Type"::Take, Item."No.", LotNo, Quantity);
        VerifyInventoryMovementLineForLot(Bin2, WarehouseActivityLine."Action Type"::Place, Item."No.", LotNo, Quantity);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceUsingBlanketSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Setup: Create Sales Order with Partial Quantity from Blanket Sales Order. Post Sales Order. Get Shipment Line on Sales Invoice. Create Sales Order with Remaining Quantity from Blanket Sales Order.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        CreateSOFromBlanketSalesOrderWithPartialQuantity(SalesHeader, SalesLine);
        PostSalesOrder(SalesHeader."Sell-to Customer No.");
        GetShipmentLineOnSalesInvoice(SalesHeader2, SalesHeader."Sell-to Customer No.");
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // Exercise:
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader2, false, false);  // Post Sales Invoice.

        // Verify.
        VerifySalesInvoiceLine(DocumentNo, SalesLine."No.", SalesLine.Quantity / 2);  // Calculated Value Required.
    end;

    [Test]
    [HandlerFunctions('OrderTrackingDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnReqLineAndSOAfterCalcRegenPlan()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup: Create Lot for Lot Item. Create and Update Multiple Stocks Keeping Unit. Create Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item.Reserve, Item."Reordering Policy"::"Lot-for-Lot");
        CreateMultipleStockkeepingUnit(Item."No.", LocationBlue.Code, LocationRed.Code);
        UpdateReplenishmentSystemAsTransferOnSKU(LocationBlue.Code, Item."No.", LocationRed.Code);
        UpdateVendorNoOnStockkeepingUnit(LocationRed.Code, Item."No.");
        CreateSalesOrder(SalesHeader, SalesLine, '', Item."No.", Quantity, LocationBlue.Code, false);  // Reserve as FALSE.

        // Exercise.
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()),
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        // Verify: Verification is done in OrderTrackingDetailsPageHandler.
        VerifyOrderTrackingOnReqLineAndSalesOrder(Item."No.", Quantity, SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostJobJournalWithLotItemTracking()
    var
        Item: Record Item;
        Bin: Record Bin;
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        LotNo: Variant;
        LotNo2: Variant;
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
        Quantity: Decimal;
    begin
        // Setup: Create Item with Lot Item Tracking. Create and Post Item Journal Line.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateTrackedItemAndUpdateInventoryOnLocationWithBin(
          Item, Bin, Quantity, true, false, false, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingMode::AssignMultipleLotNo, false);
        GetLotNoFromItemTrackingPageHandler(LotNo);
        GetLotNoFromItemTrackingPageHandler(LotNo2);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);   // Enqueue for ItemTrackingLinesPageHandler.

        // Exercise.
        CreateAndPostJobJournalLine(Bin, Item."No.", Quantity);

        // Verify: Verify Item Ledger Entry and Warehouse Entry.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemLedgerEntry."Document Type", LocationSilver.Code, Item."No.", LotNo, '',
          Quantity / 2);  // Calculated Value Required.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemLedgerEntry."Document Type", LocationSilver.Code, Item."No.", LotNo2, '',
          Quantity / 2);  // Calculated Value Required.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", ItemLedgerEntry."Document Type", LocationSilver.Code, Item."No.", LotNo, '',
          -Quantity / 2);  // Calculated Value Required.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", ItemLedgerEntry."Document Type", LocationSilver.Code, Item."No.", LotNo2, '',
          -Quantity / 2);  // Calculated Value Required.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Negative Adjmt.", WarehouseEntry."Source Document"::"Job Jnl.", Item."No.", Bin.Code, LotNo,
          -Quantity / 2, false);  // Calculated Value Required.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Negative Adjmt.", WarehouseEntry."Source Document"::"Job Jnl.", Item."No.", Bin.Code, LotNo2,
          -Quantity / 2, false);  // Calculated Value Required.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", WarehouseEntry."Source Document"::"Item Jnl.", Item."No.", Bin.Code, LotNo,
          Quantity / 2, false);  // Calculated Value Required.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", WarehouseEntry."Source Document"::"Item Jnl.", Item."No.", Bin.Code, LotNo2,
          Quantity / 2, false);  // Calculated Value Required.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementFromRPOWithBOMAndSerial()
    begin
        // Setup.
        Initialize();
        PostConsumpAfterRegisterMovementFromRPOWithSerial(false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnRegisterMovementWithWrongSerial()
    begin
        // Setup.
        Initialize();
        PostConsumpAfterRegisterMovementFromRPOWithSerial(true, false, false, false);  // Register Movement Error as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterInventoryMovementFromRPOWithSerial()
    begin
        // Setup.
        Initialize();
        PostConsumpAfterRegisterMovementFromRPOWithSerial(true, true, false, false);  // Register Movement Error and Register Movement as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,MessageHandler,ProductionJournalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostingConsumptionWithWrongSerial()
    begin
        // Setup.
        Initialize();
        PostConsumpAfterRegisterMovementFromRPOWithSerial(true, true, true, false);  // Register Movement Error, Register Movement and Post Consumption Error as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,MessageHandler,ProductionJournalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostConsumptionJournalWithSerial()
    begin
        // Setup.
        Initialize();
        PostConsumpAfterRegisterMovementFromRPOWithSerial(true, true, true, true);  // Register Movement Error, Register Movement, Post Consumption Error and Post Consumption as TRUE.
    end;

    local procedure PostConsumpAfterRegisterMovementFromRPOWithSerial(RegisterMovementError: Boolean; RegisterMovement: Boolean; PostConsumptionError: Boolean; PostConsumption: Boolean)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProdOrderLine: Record "Prod. Order Line";
        BinCode: Code[20];
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
        Quantity: Decimal;
    begin
        // Create Item with Serial Item Tracking code. Create Item with Production BOM. Create and Post Item Journal Line. Create and Refresh Released Production Order. Update Bin on Production Order Component Line.
        Quantity := 1 + LibraryRandom.RandInt(5);  // Value required for multiple Serial Nos.
        CreateItemWithProductionBOM(ParentItem, ChildItem, Quantity, false, true, LibraryUtility.GetGlobalNoSeriesCode());  // TRUE for Serial.
        FindBin(Bin, LocationGreen);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateAndPostItemJournalLine(Bin."Location Code", Bin.Code, ChildItem."No.", '', Quantity * Quantity * 2, true, true);  // Large Quantity required for test. Update Expiration Date and Use Tracking as TRUE.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Bin, ParentItem."No.", Quantity);
        BinCode := UpdateBinCodeOnProductionOrderComponent(ProdOrderComponent, Bin, ProductionOrder);

        // Exercise.
        CreateInventoryMovement(ProductionOrder."No.");

        // Verify:
        VerifyInventoryMovementLinesForProdConsumption(
          WarehouseActivityLine."Action Type"::Take, ChildItem."No.", ProductionOrder."No.", BinCode, 1, Quantity * Quantity);  // Value 1 required for Serial Quantity.
        VerifyInventoryMovementLinesForProdConsumption(
          WarehouseActivityLine."Action Type"::Place, ChildItem."No.", ProductionOrder."No.", Bin.Code, 1, Quantity * Quantity);  // Value 1 required for Serial Quantity.

        if RegisterMovementError then begin
            // Exercise: Update Wrong Serial No. on Inventory Movement Lines and handle the Error.
            UpdateSerialNoOnInventoryMovementLines(ChildItem."No.", WarehouseActivityLine."Action Type"::Take, ProductionOrder."No.", false);  // Move Next as FALSE.
            UpdateSerialNoOnInventoryMovementLines(ChildItem."No.", WarehouseActivityLine."Action Type"::Place, ProductionOrder."No.", true);  // Move Next as TRUE.
            asserterror RegisterWarehouseActivity(
                WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
                WarehouseActivityLine."Activity Type"::"Invt. Movement");

            // Verify: Error message.
            Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(TotalBaseQuantityError, 1)) > 0, GetLastErrorText);  // Value 1 required for Serial Quantity.
        end;

        if RegisterMovement then begin
            // Exercise: Update Serial No. on Inventory Movement Lines and Register Inventory Movement.
            UpdateSerialNoOnInventoryMovementLines(ChildItem."No.", WarehouseActivityLine."Action Type"::Take, ProductionOrder."No.", false);  // Move Next as FALSE.
            UpdateSerialNoOnInventoryMovementLines(ChildItem."No.", WarehouseActivityLine."Action Type"::Place, ProductionOrder."No.", false);  // Move Next as FALSE.
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
              WarehouseActivityLine."Activity Type"::"Invt. Movement");

            // Verify.
            VerifyProductionOrderComponent(ProdOrderComponent, Quantity * Quantity, Quantity * Quantity, Bin.Code);  // Value required for test.
        end;

        if PostConsumptionError then begin
            // Exercise: Open Production Journal from Production Order Line and Update Wrong Serial No. on Consumption.
            FindProductionOrderLine(ProdOrderLine, ProductionOrder);
            EnqueueValuesForProductionJournalHandler(ItemTrackingMode::SelectSerialNo, ChildItem."No.", 0);
            asserterror LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

            // Verify.
            Assert.ExpectedError(WrongQuantityBaseErr);
        end;

        if PostConsumption then begin
            // Exercise: Open Production Journal from Production Order Line and Update Serial No. on Consumption.
            LibraryVariableStorage.Enqueue(ItemTrackingMode);  // Enqueue for ItemTrackingLinesPageHandler.
            LibraryVariableStorage.Enqueue(PostJournalLinesConfirmationMessage);  // Enqueue for ConfirmHandler.
            LibraryVariableStorage.Enqueue(JournalLinesPostedMessage);  // Enqueue for MessageHandler.
            LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");  // Posting is done in ProductionJournalPageHandler.

            // Verify.
            VerifyProductionOrderComponent(ProdOrderComponent, Quantity * Quantity, 0, Bin.Code);  // Value required for test.
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryMovementFromRPOWithBOMAndLot()
    begin
        // Setup.
        Initialize();
        PostConsumptionAfterRegisterMovementFromRPOWithLot(false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnRegisterMovementWithWrongLot()
    begin
        // Setup.
        Initialize();
        PostConsumptionAfterRegisterMovementFromRPOWithLot(true, false, false, false);  // Register Movement Error as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterInventoryMovementFromRPOWithLot()
    begin
        // Setup.
        Initialize();
        PostConsumptionAfterRegisterMovementFromRPOWithLot(true, true, false, false);  // Register Movement Error and Register Movement as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,ProductionJournalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostingConsumptionWithWrongLot()
    begin
        // Setup.
        Initialize();
        PostConsumptionAfterRegisterMovementFromRPOWithLot(true, true, true, false);  // Register Movement Error, Register Movement and Post Consumption Error as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,ProductionJournalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostConsumptionJournalWithLot()
    begin
        // Setup.
        Initialize();
        PostConsumptionAfterRegisterMovementFromRPOWithLot(true, true, true, true);  // Register Movement Error, Register Movement, Post Consumption Error and Post Consumption as TRUE.
    end;

    local procedure PostConsumptionAfterRegisterMovementFromRPOWithLot(RegisterMovementError: Boolean; RegisterMovement: Boolean; PostConsumptionError: Boolean; PostConsumption: Boolean)
    var
        Bin: Record Bin;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ChildItem: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Variant;
        LotNo2: Variant;
        Quantity: Decimal;
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
        BinCode: Code[20];
    begin
        // Create Item with Lot Item Tracking code. Create Item with Production BOM. Create and Post Item Journal Line. Create and Refresh Released Production Order. Update Bin on Production Order Component Line.
        Quantity := LibraryRandom.RandInt(10);
        FindBin(Bin, LocationGreen);
        CreateItemWithProductionBOM(ParentItem, ChildItem, Quantity, true, false, '');  // TRUE for Lot.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignMultipleLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        CreateAndPostItemJournalLine(Bin."Location Code", Bin.Code, ChildItem."No.", '', Quantity * Quantity * 2, true, true);  // Value required for test. Update Expiration Date and Use Tracking as TRUE.
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryVariableStorage.Dequeue(LotNo2);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Bin, ParentItem."No.", Quantity);
        BinCode := UpdateBinCodeOnProductionOrderComponent(ProdOrderComponent, Bin, ProductionOrder);

        // Exercise.
        CreateInventoryMovement(ProductionOrder."No.");

        // Verify.
        VerifyInventoryMovementLinesForProdConsumption(
          WarehouseActivityLine."Action Type"::Take, ChildItem."No.", ProductionOrder."No.", BinCode, Quantity * Quantity,
          Quantity * Quantity);  // Value required for verification.
        VerifyInventoryMovementLinesForProdConsumption(
          WarehouseActivityLine."Action Type"::Place, ChildItem."No.", ProductionOrder."No.", Bin.Code, Quantity * Quantity,
          Quantity * Quantity);  // Value required for verification.

        if RegisterMovementError then begin
            // Exercise: Update wrong Lot No. and handle the Error.
            UpdateLotNoOnInventoryMovementLine(WarehouseActivityLine."Action Type"::Take, ProductionOrder."No.", LotNo);
            UpdateLotNoOnInventoryMovementLine(WarehouseActivityLine."Action Type"::Place, ProductionOrder."No.", LotNo2);
            asserterror RegisterWarehouseActivity(
                WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
                WarehouseActivityLine."Activity Type"::"Invt. Movement");

            // Verify: Error message.
            Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(TotalBaseQuantityError, Quantity * Quantity)) > 0, GetLastErrorText);  // Value required for test.
        end;

        if RegisterMovement then begin
            // Exercise.
            UpdateLotNoOnInventoryMovementLine(WarehouseActivityLine."Action Type"::Take, ProductionOrder."No.", LotNo);
            UpdateLotNoOnInventoryMovementLine(WarehouseActivityLine."Action Type"::Place, ProductionOrder."No.", LotNo);
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
              WarehouseActivityLine."Activity Type"::"Invt. Movement");

            // Verify.
            VerifyProductionOrderComponent(ProdOrderComponent, Quantity * Quantity, Quantity * Quantity, Bin.Code);  // Value required for verification.
        end;

        if PostConsumptionError then begin
            // Exercise.
            FindProductionOrderLine(ProdOrderLine, ProductionOrder);
            EnqueueValuesForProductionJournalHandler(ItemTrackingMode::SelectLotNo, LotNo2, Quantity);
            asserterror LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

            // Verify.
            Assert.ExpectedError(WrongQtyToHandleBaseErr);
        end;

        if PostConsumption then begin
            // Exercise.
            EnqueueValuesForProductionJournalHandler(ItemTrackingMode::SelectLotNo, LotNo, Quantity * Quantity);
            LibraryVariableStorage.Enqueue(JournalLinesPostedMessage);  // Enqueue for MessageHandler.
            LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");  // Posting is done in ProductionJournalPageHandler.

            // Verify.
            VerifyProductionOrderComponent(ProdOrderComponent, Quantity * Quantity, 0, Bin.Code);  // Value required for verification.
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentLineAfterPostSalesOrder()
    begin
        // Setup.
        Initialize();
        PostTransferOrderAfterUndoSalesShipment(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnPostingTransferOrderAfterUndoShipment()
    begin
        // Setup.
        Initialize();
        PostTransferOrderAfterUndoSalesShipment(true);  // TRUE for Transfer Order.
    end;

    local procedure PostTransferOrderAfterUndoSalesShipment(TransferOrder: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TransferHeader: Record "Transfer Header";
        PostedDocumentNo: Code[20];
    begin
        // Create Item. Create and Post Sales Order as SHIP.
        LibraryInventory.CreateItem(Item);
        CreateSalesOrder(SalesHeader, SalesLine, '', Item."No.", LibraryRandom.RandDec(10, 2), '', false);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as SHIP.

        // Exercise.
        UndoSalesShipmentLine(PostedDocumentNo);

        // Verify.
        VerifySalesShipmentLine(PostedDocumentNo, Item."No.", SalesLine.Quantity, false);
        VerifySalesShipmentLine(PostedDocumentNo, Item."No.", -SalesLine.Quantity, true);  // MoveNext as TRUE.

        if TransferOrder then begin
            // Exercise.
            asserterror CreateAndPostTransferOrder(TransferHeader, SalesLine, LocationBlack.Code, LocationOrange.Code);

            // Verify.
            Assert.ExpectedError(StrSubstNo(ItemNotOnInventoryError, Item."No."));
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPostedPurchaseReceiptWithLocationAndSerial()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Setup: Update Use Put-away Worksheet on Location. Create and post Warehouse Receipt from Purchase Order with Serial No.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItemWithItemTrackingCode(Item, false, false, false, '', LibraryUtility.GetGlobalNoSeriesCode());
        UpdateUsePutAwayWorksheetOnLocation(LocationYellow, true);
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Item."No.", Quantity, LocationYellow.Code, true);  // Use Tracking as TRUE.
        PostWarehouseReceipt(PurchaseHeader."No.");

        // Exercise.
        UndoPurchaseReceiptLine(Item."No.");

        // Verify.
        VerifyPurchRcptLine(PurchaseHeader."No.", Item."No.", LocationYellow.Code, Quantity, false);
        VerifyPurchRcptLine(PurchaseHeader."No.", Item."No.", LocationYellow.Code, -Quantity, true);  // MoveNext as TRUE.

        // Tear Down.
        UpdateUsePutAwayWorksheetOnLocation(LocationYellow, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingQuantityToShipOnSalesOrder()
    var
        SalesOrder: TestPage "Sales Order";
    begin
        // Setup: Create Sales Order by page.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        CreateSalesOrderByPage(SalesOrder, LocationWhite.Code);

        // Exercise.
        asserterror SalesOrder.SalesLines."Qty. to Ship".SetValue(LibraryRandom.RandDec(10, 2));

        // Verify.
        Assert.ExpectedError(WarehouseShipmentRequiredError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingQuantityOnSalesInvoice()
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Setup: Create Sales Invoice by page.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        CreateSalesInvoiceWithSalesLineByPage(SalesInvoice, LocationWhite.Code);

        // Exercise.
        asserterror SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));

        // Verify.
        Assert.ExpectedError(WarehouseShipmentRequiredError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingReturnQuantityOnSalesReturnOrder()
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // Setup: Create Sales Return Order by page.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        CreateSalesReturnOrderByPage(SalesReturnOrder, LocationWhite.Code);

        // Exercise.
        Commit();
        asserterror SalesReturnOrder.SalesLines."Return Qty. to Receive".SetValue(LibraryRandom.RandDec(10, 2));

        // Verify.
        Assert.ExpectedError(WarehouseReceiveRequiredError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingQuantityOnSalesCreditMemo()
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // Setup: Create Sales Credit Memo by page.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        CreateSalesCreditMemoByPage(SalesCreditMemo, LocationWhite.Code);

        // Exercise.
        asserterror SalesCreditMemo.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));

        // Verify.
        Assert.ExpectedError(WarehouseReceiveRequiredError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingQuantityOnPurchaseInvoice()
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Setup: Create Purchase Invoice by page.
        Initialize();
        CreatePurchaseInvoiceByPage(PurchaseInvoice, LocationWhite.Code);

        // Exercise.
        Commit();
        asserterror PurchaseInvoice.PurchLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));

        // Verify.
        Assert.ExpectedError(WarehouseReceiveRequiredError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingReturnQuantityOnPurchaseReturnOrder()
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // Setup: Create Purchase Return Order by page.
        Initialize();
        CreatePurchaseReturnOrderByPage(PurchaseReturnOrder, LocationWhite.Code);

        // Exercise.
        asserterror PurchaseReturnOrder.PurchLines."Return Qty. to Ship".SetValue(LibraryRandom.RandDec(10, 2));

        // Verify.
        Assert.ExpectedError(WarehouseShipmentRequiredError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnUpdatingQuantityOnPurchaseCreditMemo()
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup: Create Purchase Credit Memo by page.
        Initialize();
        CreatePurchaseCreditMemoByPage(PurchaseCreditMemo, LocationWhite.Code);

        // Exercise.
        asserterror PurchaseCreditMemo.PurchLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));

        // Verify.
        Assert.ExpectedError(WarehouseShipmentRequiredError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderAsInvoice()
    begin
        // Setup.
        Initialize();
        SalesReturnOrderWithGetPostedDocLinesToReverse(false, false);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderAsReceive()
    begin
        // Setup.
        Initialize();
        SalesReturnOrderWithGetPostedDocLinesToReverse(true, false);  // Receive Return Order as TRUE.
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderAfterUndoReturnReceipt()
    begin
        // Setup.
        Initialize();
        SalesReturnOrderWithGetPostedDocLinesToReverse(true, true);  // Invoice Return Order as TRUE.
    end;

    local procedure SalesReturnOrderWithGetPostedDocLinesToReverse(ReceiveReturnOrder: Boolean; InvoiceReturnOrder: Boolean)
    var
        Item: Record Item;
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Create Item. Create Customer. Create Sales Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", Quantity, '', false);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

        // Exercise.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as SHIP and INVOICE.

        // Verify.
        VerifyGLEntry(PostedDocumentNo, GeneralPostingSetup."Sales Account", -SalesLine."Line Amount", false);
        VerifyGLEntry(PostedDocumentNo, CustomerPostingGroup."Receivables Account", SalesLine."Amount Including VAT", false);

        if ReceiveReturnOrder then begin
            // Exercise.
            PostedDocumentNo := PostSalesReturnOrderWithGetPostedDocLinesToReverse(SalesHeader2, Customer."No.");

            // Verify.
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Entry Type"::Sale, ItemLedgerEntry."Document Type"::"Sales Return Receipt", '', Item."No.", '', '', Quantity);
        end;

        if InvoiceReturnOrder then begin
            // Exercise.
            UndoReturnReceiptLine(PostedDocumentNo);
            LibrarySales.ReopenSalesDocument(SalesHeader2);
            FindSalesReturnOrderLine(SalesLine, SalesHeader2."No.", Item."No.");
            UpdateQuantityOnSalesLine(SalesLine, Quantity / 2);  // Partial value required for test.
            PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader2, true, true);  // Post as RECEIVE and INVOICE.

            // Verify.
            VerifyGLEntry(PostedDocumentNo, GeneralPostingSetup."Sales Account", SalesLine."Line Amount", false);
            VerifyGLEntry(PostedDocumentNo, CustomerPostingGroup."Receivables Account", -SalesLine."Amount Including VAT", false);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithLot()
    begin
        // Setup.
        Initialize();
        SalesReturnOrderWithGetPostedDocLinesAndLot(false, false, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithLot()
    begin
        // Setup.
        Initialize();
        SalesReturnOrderWithGetPostedDocLinesAndLot(true, false, false);  // Post Sales Order as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderAsReceiveWithLot()
    begin
        // Setup.
        Initialize();
        SalesReturnOrderWithGetPostedDocLinesAndLot(true, true, false);  // Post Sales Order and Receive Return Order as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,PostedSalesDocumentLinesHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrderAfterUndoReturnReceiptWithLot()
    begin
        // Setup.
        Initialize();
        SalesReturnOrderWithGetPostedDocLinesAndLot(true, true, true);  // Post Sales Order, Receive Return Order and Invoice Return Order as TRUE.
    end;

    local procedure SalesReturnOrderWithGetPostedDocLinesAndLot(PostSalesOrder: Boolean; ReceiveReturnOrder: Boolean; InvoiceReturnOrder: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LotNo: Variant;
        PostedDocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // Create Item with Lot specific tracking. Create Purchase Order and assign Lot No.
        Quantity := LibraryRandom.RandInt(50);
        CreateItemWithItemTrackingCode(Item, true, false, false, LibraryUtility.GetGlobalNoSeriesCode(), '');  // TRUE for Lot.
        CreatePurchaseOrderWithLot(PurchaseHeader, Item."No.", Quantity);
        LibraryVariableStorage.Dequeue(LotNo);

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as RECEIVE and INVOICE.

        // Verify.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, ItemLedgerEntry."Document Type"::"Purchase Receipt", '', Item."No.", LotNo, '', Quantity);

        if PostSalesOrder then begin
            // Exercise.
            LibrarySales.CreateCustomer(Customer);
            CreateAndPostSalesOrderWithItemTracking(SalesHeader, Customer."No.", Item."No.", Quantity);

            // Verify.
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Entry Type"::Sale, ItemLedgerEntry."Document Type"::"Sales Shipment", '', Item."No.", LotNo, '', -Quantity);
        end;

        if ReceiveReturnOrder then begin
            // Exercise.
            PostedDocumentNo := PostSalesReturnOrderWithGetPostedDocLinesToReverse(SalesHeader2, Customer."No.");

            // Verify.
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Entry Type"::Sale, ItemLedgerEntry."Document Type"::"Sales Return Receipt", '', Item."No.", LotNo, '', Quantity);
        end;

        if InvoiceReturnOrder then begin
            // Exercise.
            UndoReturnReceiptLine(PostedDocumentNo);
            UpdateQuantityOnSalesAndReservationLine(SalesHeader2, SalesLine, Item."No.", Quantity / 2);  // Partial value required for test.

            PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader2, true, true);  // Post as RECEIVE and INVOICE.
            CustomerPostingGroup.Get(Customer."Customer Posting Group");
            GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

            // Verify.
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Entry Type"::Sale, ItemLedgerEntry."Document Type"::"Sales Return Receipt", '', Item."No.", LotNo, '',
              Quantity / 2);  // Partial value required for verification.
            VerifyGLEntry(PostedDocumentNo, GeneralPostingSetup."Sales Account", SalesLine."Line Amount", false);
            VerifyGLEntry(PostedDocumentNo, CustomerPostingGroup."Receivables Account", -SalesLine."Amount Including VAT", false);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseReceiptWithMultipleLines()
    begin
        // Setup.
        Initialize();
        CalcCrossDockOnWhseReceiptAndRegisterPutAway(false, false, false);  // Cross Dock, Post Receipt and Register Put Away as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcCrossDockOnWarehouseReceiptWithMultipleLines()
    begin
        // Setup.
        Initialize();
        CalcCrossDockOnWhseReceiptAndRegisterPutAway(true, false, false);  // Cross Dock as TRUE. Post Receipt and Register Put Away as FALSE.
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    [Scope('OnPrem')]
    procedure CalcCrossDockOnWhseRcptWthLineBasedOnSpecOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        WhseRcptNo: Code[20];
        MaxInventoryQty: Decimal;
        SalesQty: Decimal;
    begin
        // [FEATURE] [Warehouse Receipt] [Cross-Docking] [Special Order] [Requisition Worksheet]
        // [SCENARIO 378380] "Qty To Cross-Dock" should be equal to "Qty. to Receive" in Whse Receipt Line with Special Order after Calculating Cross-Dock if this line goes after line with Max Inventory
        Initialize();

        // [GIVEN] Item with Reordering Policy as "Maximum Qty.".
        CreateItemWithReorderPolicyAsMaxQty(Item, MaxInventoryQty, SalesQty);
        // [GIVEN] Create and release Sales Order as Special Order.
        CreateAndReleaseSpecialOrder(SalesHeader, Item."No.", SalesQty);
        // [GIVEN] Create Warehouse Receipt based on Purchase Orders with first line according to Reordering Policy and second based on Special Order.
        WhseRcptNo := CreateWhseRcpt(Item);

        // [WHEN] Calc Cross-Dock
        LibraryWarehouse.CalculateCrossDockLines(WhseCrossDockOpportunity, '', WhseRcptNo, LocationWhite.Code);

        // [THEN] "Qty To Cross-Dock" = 0 in Warehouse Receipt Line for Maximum Inventory.
        VerifyQtyToCrossDock(Item."No.", MaxInventoryQty, 0);
        // [THEN] "Qty To Cross-Dock" = "Qty. to Receive" in Warehouse Receipt Line based on Special Order.
        VerifyQtyToCrossDock(Item."No.", SalesQty, SalesQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWhseReceiptAfterCalcCrossDockWithMultipleLines()
    begin
        // Setup.
        Initialize();
        CalcCrossDockOnWhseReceiptAndRegisterPutAway(true, true, false);  // Cross Dock and Post Receipt as TRUE. Register Put Away as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPutAwayAfterCalcCrossDockWithMultipleLines()
    begin
        // Setup.
        Initialize();
        CalcCrossDockOnWhseReceiptAndRegisterPutAway(true, true, true);  // Cross Dock, Post Receipt and Register Put Away as TRUE.
    end;

    local procedure CalcCrossDockOnWhseReceiptAndRegisterPutAway(CrossDock: Boolean; PostReceipt: Boolean; RegisterPutaway: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Create Item, Find Pick Bin. Create and Release Purchase Order with Multiple Lines. Create Warehouse Receipt.
        Quantity := LibraryRandom.RandDec(10, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);  // Value Required for test.
        LibraryInventory.CreateItem(Item);
        FindPickBin(Bin, LocationWhite.Code);
        CreateAndReleasePurchaseOrderWithMultipleLines(PurchaseHeader, Item."No.", Quantity * 2, LocationWhite.Code, Quantity2);  // Value Required for test.
        CreateWarehouseReceipt(PurchaseHeader);

        // Exercise.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, '', Item."No.", Quantity, LocationWhite.Code, false);  // Reserve as FALSE.

        // Verify.
        VerifyWarehouseReceiptLine(PurchaseHeader."No.", Item."No.", Quantity * 2, 0, LocationWhite.Code, false);  // Value Required for test. Move Next as FALSE.
        VerifyWarehouseReceiptLine(PurchaseHeader."No.", Item."No.", Quantity2, 0, LocationWhite.Code, true);  // Value Required for test. Move Next as TRUE.

        if CrossDock then begin
            // Exercise.
            CalculateCrossDock(PurchaseHeader."No.");

            // Verify.
            VerifyWarehouseReceiptLine(PurchaseHeader."No.", Item."No.", Quantity * 2, Quantity, LocationWhite.Code, false);  // Value Required for test. Move Next as FALSE.
            VerifyWarehouseReceiptLine(PurchaseHeader."No.", Item."No.", Quantity2, 0, LocationWhite.Code, true);  // Value Required for test. Move Next as TRUE.
        end;

        if PostReceipt then begin
            // Exercise.
            PostWarehouseReceipt(PurchaseHeader."No.");

            // Verify.
            // Take line for Receipt line that feeds the cross-dock.
            VerifyPutAwayLine(
              WarehouseActivityLine."Action Type"::Take, PurchaseHeader."No.", Item."No.", LocationWhite.Code, Quantity * 2,
              WarehouseActivityLine."Cross-Dock Information"::"Some Items Cross-Docked");
            // Take line for Receipt line that is not cross-docked.
            VerifyPutAwayLine(
              WarehouseActivityLine."Action Type"::Take, PurchaseHeader."No.", Item."No.", LocationWhite.Code, Quantity2,
              WarehouseActivityLine."Cross-Dock Information"::" ");

            // Place line for Cross-dock bin.
            VerifyPutAwayLine(
              WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Item."No.", LocationWhite.Code, Quantity,
              WarehouseActivityLine."Cross-Dock Information"::"Cross-Dock Items");
            // Place line for normal Pick bin.
            VerifyPutAwayLine(
              WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Item."No.", LocationWhite.Code, Quantity,
              WarehouseActivityLine."Cross-Dock Information"::"Some Items Cross-Docked");
            // Place line for non cross-docked Receipt line.
            VerifyPutAwayLine(
              WarehouseActivityLine."Action Type"::Place, PurchaseHeader."No.", Item."No.", LocationWhite.Code, Quantity2,
              WarehouseActivityLine."Cross-Dock Information"::" ");
        end;

        if RegisterPutaway then begin
            // Exercise: Update Bin Code on place Line and Register Put Away.
            UpdateBinCodeOnPutAwayLine(Bin, PurchaseHeader."No.");
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::"Put-away");

            // Verify.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Source Document"::"P. Order", Item."No.",
              LocationWhite."Receipt Bin Code", '', -Quantity * 2, false);  // Value Required for test. Move Next as FALSE.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Source Document"::"P. Order", Item."No.",
              LocationWhite."Cross-Dock Bin Code", '', Quantity, false);  // Move Next as FALSE.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Source Document"::"P. Order", Item."No.", Bin.Code, '', Quantity, false);  // Move Next as FALSE.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Source Document"::"P. Order", Item."No.",
              LocationWhite."Receipt Bin Code", '', -Quantity2, true);  // Move Next as TRUE.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, WarehouseEntry."Source Document"::"P. Order", Item."No.", Bin.Code, '', Quantity2, true);  // Move Next as TRUE.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrderWithVariantCode()
    begin
        // Setup.
        Initialize();
        CreateAndPostTransferOrderWithVariantCode(false);  // Post Transfer as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostTransferOrderWithVariantCode()
    begin
        // Setup.
        Initialize();
        CreateAndPostTransferOrderWithVariantCode(true);  // Post Transfer as TRUE.
    end;

    local procedure CreateAndPostTransferOrderWithVariantCode(PostTransferOrder: Boolean)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
    begin
        // Create Item with Variant. Create and Post Item Journal Line with Variant. Create Transfer Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithVariant(Item, ItemVariant);
        CreateAndPostItemJournalLine(LocationBlack.Code, '', Item."No.", ItemVariant.Code, Quantity, false, false);  // Update Expiration Date and Use Tracking as FALSE.
        CreateTransferOrder(TransferHeader, TransferLine, LocationBlack.Code, LocationOrange.Code, Item."No.", Quantity);

        // Exerise.
        UpdateVariantCodeOnTransferLine(TransferLine, ItemVariant.Code);

        // Verify.
        TransferLine.TestField("Variant Code", ItemVariant.Code);

        if PostTransferOrder then begin
            // Exercise.
            LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);  // Post as Ship and Receive.

            // Verify.
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Entry Type"::Transfer, ItemLedgerEntry."Document Type"::"Transfer Shipment", LocationBlack.Code, Item."No.",
              '', ItemVariant.Code, -Quantity);
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Entry Type"::Transfer, ItemLedgerEntry."Document Type"::"Transfer Shipment", LocationInTransit.Code,
              Item."No.", '', ItemVariant.Code, Quantity);
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Entry Type"::Transfer, ItemLedgerEntry."Document Type"::"Transfer Receipt", LocationInTransit.Code,
              Item."No.", '', ItemVariant.Code, -Quantity);
            VerifyItemLedgerEntry(
              ItemLedgerEntry."Entry Type"::Transfer, ItemLedgerEntry."Document Type"::"Transfer Receipt", LocationOrange.Code, Item."No.",
              '', ItemVariant.Code, Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobLedgerEntryWithManExpirDateEntryReqdTrue()
    begin
        // Test No Error will appear while Posting Job Journal with Item Reversal when Man. Expir. Date Entry Reqd. is True.
        VerifyNoErrorForJobJnlReversal(true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure JobLedgerEntryWithManExpirDateEntryReqdFalse()
    begin
        // Test No Error will appear while Posting Job Journal with Item Reversal when Man. Expir. Date Entry Reqd. is False.
        VerifyNoErrorForJobJnlReversal(false);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure MakeSalesOrderAfterCreateInvoiceAndOrderLinkBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        BlanketOrderSalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PartialInvoicedQty: Decimal;
    begin
        // Setup: Create Blanket Sales Order, create Sales Invoice and Sales Order link to Blanket Sales Order with Partial quantity.
        Initialize();
        CreateSalesBlanketOrder(SalesHeader, BlanketOrderSalesLine, ''); // Set Location to blank.
        PartialInvoicedQty := BlanketOrderSalesLine.Quantity / 2;
        CreateSalesDocumentLinkBlanketOrder(
          SalesHeader2, BlanketOrderSalesLine, PartialInvoicedQty / 2, SalesHeader2."Document Type"::Invoice);
        CreateSalesDocumentLinkBlanketOrder(
          SalesHeader3, BlanketOrderSalesLine, PartialInvoicedQty / 2, SalesHeader3."Document Type"::Order);

        // Exercise and Verify: Pops up an error that Sales Order cannot be made.
        MakeSalesOrderAndVerifyErr(SalesHeader, BlanketOrderSalesLine, (BlanketOrderSalesLine.Quantity - PartialInvoicedQty));

        // Reduce the Quantity to Ship on Sales Line then Make Sales Order.
        BlanketOrderSalesLine.Validate("Qty. to Ship", (BlanketOrderSalesLine.Quantity - PartialInvoicedQty));
        BlanketOrderSalesLine.Modify(true);
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // Post Sales Invoice and the Sales Order linked Blanket Order.
        LibrarySales.PostSalesDocument(SalesHeader2, false, false);
        LibrarySales.PostSalesDocument(SalesHeader3, true, true);

        // Exercise and Verify: Post the Sales Order made from Blanket Order successfully.
        PostSalesOrder(BlanketOrderSalesLine."Sell-to Customer No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakePurchOrderAfterCreateInvoiceAndOrderLinkBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseHeader3: Record "Purchase Header";
        BlanketOrderPurchaseLine: Record "Purchase Line";
        PartialInvoicedQty: Decimal;
    begin
        // Setup: Create Blanket Purchase Order, create Purchase Invoice and Sales Order link to Blanket Purchase Order with Partial quantity.
        Initialize();
        CreatePurchaseBlanketOrder(PurchaseHeader, BlanketOrderPurchaseLine, ''); // Set Location to blank.
        PartialInvoicedQty := BlanketOrderPurchaseLine.Quantity / 2;
        CreatePurchaseDocumentLinkBlanketOrder(
          PurchaseHeader2, BlanketOrderPurchaseLine, PartialInvoicedQty / 2, PurchaseHeader2."Document Type"::Invoice);
        CreatePurchaseDocumentLinkBlanketOrder(
          PurchaseHeader3, BlanketOrderPurchaseLine, PartialInvoicedQty / 2, PurchaseHeader3."Document Type"::Order);

        // Exercise and Verify: Pops up an error that Purchase Order cannot be made.
        MakePurchaseOrderAndVerifyErr(PurchaseHeader, BlanketOrderPurchaseLine, (BlanketOrderPurchaseLine.Quantity - PartialInvoicedQty));

        // Reduce the Quantity to Receive on Purchase Line then Make Purchase Order.
        BlanketOrderPurchaseLine.Validate("Qty. to Receive", (BlanketOrderPurchaseLine.Quantity - PartialInvoicedQty));
        BlanketOrderPurchaseLine.Modify(true);
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);

        // Post Purchase Invoice and the Sales Order linked Blanket Order.
        PostPurchaseDocument(PurchaseHeader2."Buy-from Vendor No.", PurchaseHeader2."Document Type"::Invoice, false, false);
        PostPurchaseDocument(PurchaseHeader3."Buy-from Vendor No.", PurchaseHeader3."Document Type"::Order, true, true);

        // Exercise and Verify: Post the Purchase Order made from Blanket Order successfully.
        PostPurchaseDocument(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader3."Document Type"::Order, true, true);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure MakeSalesOrderAfterCreateReturnOrderAndCreditMemoLinkBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        BlanketOrderSalesLine: Record "Sales Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PartialShipQty: Integer;
    begin
        // Setup: Create Blanket Sales Order, create Sales Credit Memo link to Blanket Sales Order.
        // Make Sales Order from Blanket Sales Order.
        Initialize();
        CreateSalesBlanketOrder(SalesHeader, BlanketOrderSalesLine, ''); // Set Location to blank.
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // Partial Post Sales Order, make the "Qty. to Ship" on Blanket Sales Order more than PartialShipQty.
        PartialShipQty := Round(BlanketOrderSalesLine.Quantity / 3, 1);
        UpdateQtyToShipOnSalesLine(BlanketOrderSalesLine."Sell-to Customer No.", PartialShipQty);
        PostSalesOrder(BlanketOrderSalesLine."Sell-to Customer No.");
        CreateSalesDocumentLinkBlanketOrder(
          SalesHeader2, BlanketOrderSalesLine, PartialShipQty / 2, SalesHeader."Document Type"::"Return Order");
        CreateSalesDocumentLinkBlanketOrder(
          SalesHeader3, BlanketOrderSalesLine, PartialShipQty / 2, SalesHeader."Document Type"::"Credit Memo");

        // Exercise and Verify: Verify the error message when making Sales Order as
        // "Qty. to Ship" is more than the Quantity on the Sales Credit Memo add the Quantity on Sales Return Order.
        BlanketOrderSalesLine.Find();
        BlanketOrderSalesLine.Validate("Qty. to Ship", BlanketOrderSalesLine.Quantity - PartialShipQty);
        BlanketOrderSalesLine.Modify();
        MakeSalesOrderAndVerifyErr(SalesHeader, BlanketOrderSalesLine, PartialShipQty);

        // Reduce the Quantity to Ship on Sales Line then Make Sales Order.
        BlanketOrderSalesLine.Validate("Qty. to Ship", PartialShipQty);
        BlanketOrderSalesLine.Modify(true);
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);

        // Post Sales Return Order and Sales Credit Memo.
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);
        LibrarySales.PostSalesDocument(SalesHeader3, false, false);

        // Exercise and Verify: the Sales Order made can be post successfully.
        PostSalesOrder(BlanketOrderSalesLine."Sell-to Customer No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakePurchOrderAfterCreateReturnOrderAndCreditMemoLinkBlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseHeader3: Record "Purchase Header";
        BlanketOrderPurchaseLine: Record "Purchase Line";
        PartialReceiveQty: Integer;
    begin
        // Setup: Create Blanket Purchase Order,
        // create Purchase Credit Memo link to Blanket Purchase Order.
        // Make Purchase Order from Blanket Purchase Order.
        Initialize();
        CreatePurchaseBlanketOrder(PurchaseHeader, BlanketOrderPurchaseLine, ''); // Set Location to blank.
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);

        // Partial Post Purchase Order, make the "Qty. to Receive" on the Blanket Purchase Order more than PartialReceiveQty.
        PartialReceiveQty := Round(BlanketOrderPurchaseLine.Quantity / 3, 1);
        UpdateQtyToReceiveOnPurchaseLine(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Document Type"::Order, PartialReceiveQty);
        PostPurchaseDocument(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Document Type"::Order, true, false);
        CreatePurchaseDocumentLinkBlanketOrder(
          PurchaseHeader2, BlanketOrderPurchaseLine, PartialReceiveQty / 2, PurchaseHeader."Document Type"::"Return Order");
        CreatePurchaseDocumentLinkBlanketOrder(
          PurchaseHeader3, BlanketOrderPurchaseLine, PartialReceiveQty / 2, PurchaseHeader."Document Type"::"Credit Memo");

        // Exercise and Verify: Verify the error message when making Purchase Order
        // as "Qty. to Receive" is more than the Quantity on the Purchase Return Order add the Quantity on Purchase Credit Memo.
        BlanketOrderPurchaseLine.Find();
        BlanketOrderPurchaseLine.Validate("Qty. to Receive", BlanketOrderPurchaseLine.Quantity - PartialReceiveQty);
        BlanketOrderPurchaseLine.Modify();
        MakePurchaseOrderAndVerifyErr(PurchaseHeader, BlanketOrderPurchaseLine, PartialReceiveQty);

        // Reduce the Quantity to Receive on Purchase Line then Make Purchase Order.
        BlanketOrderPurchaseLine.Validate("Qty. to Receive", PartialReceiveQty);
        BlanketOrderPurchaseLine.Modify(true);
        LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);

        // Post Purchase Return Order and Purchase Credit Memo.
        PostPurchaseDocument(PurchaseHeader2."Buy-from Vendor No.", PurchaseHeader2."Document Type"::"Return Order", true, true);
        PostPurchaseDocument(PurchaseHeader3."Buy-from Vendor No.", PurchaseHeader2."Document Type"::"Credit Memo", false, false);

        // Exercise and Verify: the Purchase Order made can be post successfully.
        PostPurchaseDocument(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Document Type"::Order, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcConsumptionWhenItemIsNotInTheBin()
    var
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ChildItemNo: Code[20];
    begin
        // Test Calc. Consumption is run successfully without any errors when the Bin Code
        // filled in Prod. Order Component does not include the child item.

        // Setup: Create Item With ProductionBOM. Post Item Journal with ChildItem with Bin.
        // Uncheck Fixed and Default in Bin Content for ChildItem. Create RPO and fill another
        // bin which does not include the ChildItem in Production Component.
        Initialize();
        ChildItemNo := PreparationForCalcConsumptionAndOpeningProductionJournal(ProductionOrder);

        // Exercise & Verify: Verify Calc. Consumption is run successfully with the line generated.
        CalcConsumptionInConsumptionJournal(ProductionOrder."No.");
        SelectConsumptionLine(ItemJournalLine, ProductionOrder."No.");
        ItemJournalLine.TestField("Item No.", ChildItemNo);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler2')]
    [Scope('OnPrem')]
    procedure OpenProductionJournalWhenItemIsNotInTheBin()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ChildItemNo: Code[20];
    begin
        // Test Production Journal can be opened successfully without any errors when
        // the Bin Code filled in Prod. Order Component does not include the child item.

        // Setup: Create Item With ProductionBOM. Post Item Journal with ChildItem with Bin.
        // Uncheck Fixed and Default in Bin Content for ChildItem. Create RPO and fill another
        // bin which does not include the ChildItem in Prod. Order Component.
        Initialize();
        ChildItemNo := PreparationForCalcConsumptionAndOpeningProductionJournal(ProductionOrder);

        // Exercise & Verify: Verify no error pops up when opening Production Journal.
        // Verify the line in ProductionJournalPageHandler2.
        LibraryVariableStorage.Enqueue(ChildItemNo);
        FindProductionOrderLine(ProdOrderLine, ProductionOrder);
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoMultipleSalesShipmentLinesAfterRegisterWhseShipment()
    var
        Bin: Record Bin;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Test Warehouse Entry is correct after undo multiple Sales Shipment Lines with warehouse.

        // Setup: Create and post Item Journal Line with Location and Bin. Create and post Warehouse Shipment From Sales Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateAndPostItemJournalLine(Bin."Location Code", Bin.Code, Item."No.", '', LibraryRandom.RandDec(10, 2) + 100, false, false);
        CreateAndPostWarehouseShipmentFromSalesOrder(
          SalesLine, '', Item."No.", LibraryRandom.RandDec(50, 2), LocationSilver.Code);

        // Exercise: Undo multiple Sales Shipment Lines.
        UndoMultipleShipmentLines(SalesLine."Document No.");

        // Verify: Verify Warehouse Entry has two lines after undo multiple Sales Shipment Lines.
        VerifyWarehouseEntryWithTotalLines(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", WarehouseEntry."Source Document"::"S. Order", Item."No.", 2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure ReducingQuantityInTrackingLinesDoesNotClearLedgerEntryRelations()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Customer: Record Customer;
        ItemNo: Code[20];
        LotNo: Code[50];
        ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,SetQuantity;
        QuantityToInvoice: Decimal;
        DeltaQty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Sales Invoice]
        // [SCENARIO 363510] Reducing Quantity (Base) in Tracking Lines does not clear "Appl.-to Item Entry" if Quantity to Invoice is sufficient
        Initialize();

        // [GIVEN] Item Ledger Entry "L" for Item with Tracking
        DeltaQty := LibraryRandom.RandDec(10, 2);
        QuantityToInvoice := LibraryRandom.RandDec(10, 2) + DeltaQty;

        ItemNo := CreateItemOnInventoryWithTracking(LotNo, QuantityToInvoice);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();

        // [GIVEN] Sales Order with Quantity to Invoice = "Q"
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", ItemNo, QuantityToInvoice, LocationOrange.Code, false);

        // [GIVEN] Tracking Specification for Item with Quantity = "Q" and "Appl.-to Item Entry" = "L"
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries); // Enqueue for ItemTrackingLinesHandler
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(QuantityToInvoice);
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Entry No.");
        SalesLine.OpenItemTrackingLines();

        // [WHEN] Set "Quantity (Base)" on Tracking Line to "X", "X" < "Q"
        // [THEN] "Appl.-to Item Entry" = "L"
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SetQuantity);
        LibraryVariableStorage.Enqueue(QuantityToInvoice - DeltaQty);
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Entry No.");
        SalesLine.OpenItemTrackingLines();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure IncreasingQuantityInTrackingLinesClearsLedgerEntryRelations()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Customer: Record Customer;
        ItemNo: Code[20];
        LotNo: Code[50];
        ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,SetQuantity;
        QuantityToInvoice: Decimal;
        DeltaQty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Sales Invoice]
        // [SCENARIO 363510] Increasing Quantity (Base) in Tracking Lines clears "Appl.-to Item Entry"
        Initialize();

        // [GIVEN] Item Ledger Entry "L" for Item with Tracking
        DeltaQty := LibraryRandom.RandDec(10, 2);
        QuantityToInvoice := LibraryRandom.RandDec(10, 2) + DeltaQty;

        ItemNo := CreateItemOnInventoryWithTracking(LotNo, QuantityToInvoice + DeltaQty);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();

        // [GIVEN] Sales Order with Quantity to Invoice = "Q"
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", ItemNo, QuantityToInvoice, LocationOrange.Code, false);

        // [GIVEN] Tracking Specification for Item with Quantity = "Q" and "Appl.-to Item Entry" = "L"
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries); // Enqueue for ItemTrackingLinesHandler
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(QuantityToInvoice);
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Entry No.");
        SalesLine.OpenItemTrackingLines();

        // [WHEN] Set "Quantity (Base)" on Tracking Line to "X", "X" > "Q"
        // [THEN] "Appl.-to Item Entry" = 0
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SetQuantity);
        LibraryVariableStorage.Enqueue(QuantityToInvoice + DeltaQty);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(ItemTrackingQuantityMsg);
        SalesLine.OpenItemTrackingLines();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    procedure ReducingQuantityInTrackingLinesDoesNotClearLedgerEntryRelations4Purch()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
        LotNo: Code[20];
        ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,SetQuantity;
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Return Order]
        // [SCENARIO 420366] Reducing Quantity (Base) in Item Tracking Lines does not clear "Appl.-to Item Entry" if Qty. to Invoice is sufficient.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Create lot-tracked item.
        // [GIVEN] Post some inventory, note the item ledger entry "X".
        ItemNo := CreateItemOnInventoryWithTracking(LotNo, Qty);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();

        // [GIVEN] Purchase return order for quantity = "Q".
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', ItemNo, Qty, LocationOrange.Code, WorkDate());

        // [GIVEN] Open item tracking lines, select lot no., set quantity = "Q" and "Appl.-to Item Entry" = "X"
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Entry No.");
        PurchaseLine.OpenItemTrackingLines();

        // [WHEN] Reopen item tracking lines and set "Quantity (Base)" to "q", "q" <= "Q".

        // [THEN] "Appl.-to Item Entry" remains "X".
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SetQuantity);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandIntInRange(20, 50));
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Entry No.");
        PurchaseLine.OpenItemTrackingLines();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankCodeInReturnReasonTable()
    var
        ReturnReason: TestPage "Return Reasons";
    begin
        // [FEATURE] [Return Reason]
        // [SCENARIO 374829] It should not be possible to insert a record in Return Reason table with field "Code" blank

        // [WHEN] Insert record with "Code" = '' in Return Reason table
        ReturnReason.OpenNew();
        asserterror ReturnReason.Code.SetValue('');

        // [THEN] Error is thrown: 'Code must be filled in. Enter a value.'
        Assert.ExpectedError(BlankCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoProdOrderForComponentWhenSKUReorderingPolicyAsLotForLot()
    var
        Item: Record Item;
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemQty: Decimal;
        ComponentQty: Decimal;
        QtyPer: Decimal;
        Direction: Option Forward,Backward;
        CalcMethod: Option "No Levels","One level","All levels";
    begin
        // [FEATURE] [Production Order] [Production BOM] [Stockkeeping Unit]
        // [SCENARIO 378606] Production Order for Component shouldn't be created when Replan PO with enough Inventory and "Reordering Policy" at SKU is equal to "Lot-for-Lot".
        Initialize();

        // [GIVEN] Item called ComponentItem with "Replenishment System" as "Prod. Order" and "Reordering Policy" as "Lot-for-Lot" at Stockkeeping Unit.
        LibraryManufacturing.SetComponentsAtLocation('');
        QtyPer := LibraryRandom.RandInt(10);
        ItemQty := LibraryRandom.RandInt(20);
        ComponentQty := ItemQty * QtyPer + LibraryRandom.RandInt(100);
        CreateItemWithSKU(ComponentItem, LocationBlue.Code);
        // [GIVEN] Created Inventory of "X" for Component.
        CreateAndPostItemJournalLine(LocationBlue.Code, '', ComponentItem."No.", '', ComponentQty, false, false);
        // [GIVEN] Parent Item with Component as a child item.
        CreateItemWithComponent(Item, ComponentItem, QtyPer);
        // [GIVEN] Created Production Order for Parent Item with Component Item of Quantity < "X".
        CreateProdOrderForParentItem(ProductionOrder, LocationBlue.Code, Item."No.", ItemQty);

        // [WHEN] Replan Production Order for Parent Item.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] Production Order for Component doesn't exist.
        VerifyProdOrderLineNotExists(ComponentItem."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMovementReservedLotCanBeSelected()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
    begin
        // [FEATURE] [Inventory Movement] [Item Tracking] [Reservation]
        // [SCENARIO 381324] Reserved lot can be selected on inventory movement line.
        Initialize();
        // [GIVEN] Lot-tracked Item with inventory in bin "B1". Lot No. = "L".
        // [GIVEN] Inventory Movement of Item from bin "B1" to "B2".
        // [GIVEN] Lot "L" is reserved for Sales Order.
        CreateInventoryMovementForReservedLot(WarehouseActivityLine, LotNo);
        WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity);
        // [WHEN] Select "L" on Inventory Movement "take" line.
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        // [THEN] Reserved lot "L" can be selected.
        WarehouseActivityLine.TestField("Lot No.", LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvtMovementCanBeRegisteredWhenLotIsReserved()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        LotNo: Code[50];
    begin
        // [FEATURE] [Inventory Movement] [Item Tracking] [Reservation]
        // [SCENARIO 381324] Inventory movement of reserved lot can be registered.
        Initialize();
        // [GIVEN] Lot-tracked Item with inventory in bin "B1". Lot No. = "L".
        // [GIVEN] Inventory Movement of Item from bin "B1" to "B2".
        // [GIVEN] Lot "L" is reserved for Sales Order.
        CreateInventoryMovementForReservedLot(WarehouseActivityLine, LotNo);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.FindFirst();
        // [WHEN] Autofill qty. to handle and register Inventory Movement.
        RegisterWarehouseActivity(WarehouseActivityLine."Source Document", WarehouseActivityLine."Source No.", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        // [THEN] Reserved lot "L" is successfully moved to bin "B2".
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::Movement, "Warehouse Journal Source Document".FromInteger(0), WarehouseActivityLine."Item No.", WarehouseActivityLine."Bin Code", LotNo, WarehouseActivityLine.Quantity, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SinglePutawayLineForCrossDockReceipt()
    var
        Location: Record Location;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        Qty: Decimal;
    begin
        // [FEATURE] [Receipt] [Put-away] [Cross-Docking]
        // [SCENARIO 208108] At Location with enabled "Use Cross-Docking", without bins, put-away and receive are required, only single "Warehouse Activity Line" with "Activity Type" = "Put-away" is created for single line of Cross-Dock receipt.
        Initialize();

        // [GIVEN] Location "L" without bins with enabled "Use Cross-Docking", put-away and receive are required;
        CreateCrossDockLocationWithoutBins(Location);

        LibraryInventory.CreateItem(Item);
        Qty := LibraryRandom.RandInt(1000);

        // [GIVEN] Released Sales Order "SO" of Item "I" at "L" with Quantity "Q";
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Released Purchase Order "PO" of Item "I" at "L" with Quantity "Q" and Warehouse Receipt "WR" for "PO";
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, Location.Code, WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceipt(WarehouseReceiptHeader, Item."No.");

        // [WHEN] Calculate Cross-Dock Lines for "WR" and post "WR"
        LibraryWarehouse.CalculateCrossDockLines(WhseCrossDockOpportunity, '', WarehouseReceiptHeader."No.", Location.Code);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // [THEN] Only single Warehouse Activity Line "AL" for "I" is created, "AL"."Activity Type" = "Put-away","AL"."Action Type" is blank, "AL"."Cross-Dock Information" = "Cross-Dock Items","AL".Quantity = "Q".
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.TestField("Action Type", WarehouseActivityLine."Action Type"::" ");
        WarehouseActivityLine.TestField(Quantity, Qty);
        WarehouseActivityLine.TestField("Cross-Dock Information", WarehouseActivityLine."Cross-Dock Information"::"Cross-Dock Items");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MovementFromInternalMvmtWithAutoHandlingItemTrackingByFEFO()
    var
        Item: Record Item;
        Location: Record Location;
        FromBin: array[2] of Record Bin;
        ToBin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        InternalMovementLine: Record "Internal Movement Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[20];
        ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,SetQuantity;
        Qty: Decimal;
    begin
        // [FEATURE] [Internal Movement] [Inventory Movement] [Item Tracking] [FEFO]
        // [SCENARIO 373187] Creating inventory movement from internal movement with automatic item tracking assignment by FEFO.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, true, LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location set up for FEFO picking.
        CreateAndUpdateLocation(Location, false, true, false, false, true);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);

        // [GIVEN] Bins "A1", "A2" and "B".
        LibraryWarehouse.CreateBin(FromBin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(FromBin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(ToBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Post inventory to bin "A1". Lot No. = "L1", expiration date = "D1".
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        CreateAndPostItemJournalLine(Location.Code, FromBin[1].Code, Item."No.", '', Qty, true, true);
        LotNos[1] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNos[1]));

        // [GIVEN] Post inventory to bin "A2". Lot No. = "L2", expiration date = "D2" >= "D1".
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        CreateAndPostItemJournalLine(Location.Code, FromBin[2].Code, Item."No.", '', Qty, true, true);
        LotNos[2] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNos[2]));

        // [GIVEN] Create internal movement.
        // [GIVEN] Populate inventory movement line: "From Bin Code" = "A2", "To Bin Code" = "B".
        // [GIVEN] Do not assign item tracking.
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Location.Code, ToBin.Code);
        LibraryWarehouse.CreateInternalMovementLine(
          InternalMovementHeader, InternalMovementLine, Item."No.", FromBin[2].Code, ToBin.Code, Qty);

        // [WHEN] Create inventory movement from the internal movement.
        CreateInventoryMovementFromInternalMovement(InternalMovementHeader);

        // [THEN] An inventory movement has been created.
        // [THEN] Lot no. "L2" has been automatically selected.
        FindInventoryMovementLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, Item."No.", WarehouseActivityLine."Source Document"::" ", '');
        WarehouseActivityLine.TestField("Lot No.", LotNos[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesSNHandler,EnterQuantityToCreatePageHandler,ItemTrackingListPageHandler,ReserveFromCurrentLineHandler,ConfirmHandler,WhseSrcCreateDocReqHandler,DummyMessageHandler')]
    procedure VerifyWhseItemTrackingLineIsDeletedWhenWarehousePickCreatedFromJobIsDeleted()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
        SerialNo: Code[20];
    begin
        // [SCENARIO 470228] Verify that the warehouse item tracking line is deleted when the warehouse pick created from job is deleted.
        Initialize();

        // [GIVEN] Create full WMS Location
        CreateFullWarehouseSetup(Location);
        UpdateLocation(Location);

        // [GIVEN] Create Item with Item Tracking Code
        CreateItemWithItemTrackingCode(Item, false, true, false, '', LibraryUtility.GetGlobalNoSeriesCode());

        // [GIVEN] Create Purchase Order, Warehouse Receipt and Post Warehouse Receipt
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Item."No.", 1, Location.Code, true);
        PostWarehouseReceipt(PurchaseHeader."No.");
        SerialNo := LibraryVariableStorage.DequeueText();

        // [GIVEN] Create Job with Job Task
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Create Job Planning Line
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        UpdateJobPlanningLine(JobPlanningLine, Item."No.", Location.Code, 1);

        // [GIVEN] Setup Item Tracking information on Job Planning Line
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectSerialNo);
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(1);
        JobPlanningLine.OpenItemTrackingLines();

        // [GIVEN] Reserve Item from Job Planning Line.        
        LibraryVariableStorage.Enqueue(ReservationSpecificTrackingConfirmMessage);  // Enqueue for ConfirmHandler.
        OpenReservationPage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        // [GIVEN] Create Warehouse Pick from Job
        Job.Get(JobTask."Job No.");
        OpenJobAndCreateWarehousePick(Job);

        // [GIVEN] Verify Warehouse Item Tracking Line is created
        SetWhseItemTrackingLineFilters(WhseItemTrackingLine, Item."No.", Location.Code, Job."No.");
        Assert.RecordIsNotEmpty(WhseItemTrackingLine);

        // [GIVEN] Find Warehouse Activity Header
        FindWarehouseActivityHeader(WhseActivityHeader, Location.Code, WhseActivityHeader.Type::Pick);

        // [WHEN] Delete Warehouse Pick
        WhseActivityHeader.Delete(true);

        // [THEN] Verify results
        SetWhseItemTrackingLineFilters(WhseItemTrackingLine, Item."No.", Location.Code, Job."No.");
        Assert.RecordIsEmpty(WhseItemTrackingLine);
    end;

    [Test]
    procedure VerifyCrossDockQtyIsCalcualtedOnWarehouseReceiptForBackflushedComponentOnProductionOrder()
    var
        Location: Record Location;
        CompItem: Record Item;
        ProdItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
    begin
        // [SCENARIO 471933] Verify that the cross-dock quantity is calculated on the warehouse receipt for the backflushed component on the production order 
        Initialize();

        // [GIVEN] Location "L" without bins with enabled "Use Cross-Docking", put-away and receive are required;
        CreateCrossDockLocationWithoutBins(Location);
        Evaluate(Location."Cross-Dock Due Date Calc.", '<10D>');
        Location.Modify(true);

        // [GIVEN] Create Items
        CreateCompItem(CompItem, CompItem."Flushing Method"::Backward);
        LibraryInventory.CreateItemSimple(ProdItem, ProdItem."Costing Method"::FIFO, 0);

        // [GIVEN] Create Released Production Order
        CreateReleasedProdOrder(ProdItem, CompItem, Location, 1);

        // [GIVEN] Create and Release purchase document
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', CompItem."No.", 1, Location.Code, WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt from Purchase Order
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceipt(WarehouseReceiptHeader, CompItem."No.");

        // [WHEN] Calculate cross-dock lines
        LibraryWarehouse.CalculateCrossDockLines(WhseCrossDockOpportunity, '', WarehouseReceiptHeader."No.", Location.Code);

        // [THEN] Verify results
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.");
        Assert.AreEqual(WarehouseReceiptLine."Qty. to Cross-Dock", 1, CrossDockQtyIsNotCalculatedMsg);
    end;

    [Test]
    procedure VerifyBinCodeOnRequisitionLineWhenVendorIsAddedManually()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        Vendor: Record Vendor;
        Bin: Record Bin;
        RequisitionLine: Record "Requisition Line";
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        // [SCENARIO 478663] Verify that the bin code is added on the requisition line when the vendor is added manually 
        Initialize();

        // [GIVEN] Setup Warehouse Employee for Silver Location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, true);

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Vendor with Location Code
        LibraryPurchase.CreateVendorWithLocationCode(Vendor, LocationSilver.Code);

        // [GIVEN] Create Bin with Bin Content
        CreateBinAndBinContent(Bin, LocationSilver.Code, Item."No.", Item."Base Unit of Measure", true); // True for Default Bin.

        // [GIVEN] Create a line in Requisition Worksheet
        CreateRequisitionWorksheetline(RequisitionLine, Item."No.", '');

        // [WHEN] Open Requisition Worksheet and add Vendor
        OpenRequisitionWorksheetPage(ReqWorksheet, RequisitionLine."Journal Batch Name");
        ReqWorksheet."Vendor No.".SetValue(Vendor."No.");
        ReqWorksheet.Close();

        // [THEN] Verify results
        FindRequisitionLine(RequisitionLine, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name");
        RequisitionLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure VerifyFromBinHasValueWhenCalculateBinReplenishmentExecutedWithItemTrackingByFEFO()
    var
        Item: Record Item;
        Location: Record Location;
        FromBin: Record Bin;
        ToBin: Record Bin;
        BinContent: Record "Bin Content";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,SetQuantity;
    begin
        // [SCENARIO 483448] Calculate Bin Replenishment - clears From Bin/Zone fields for items with expiration date
        Initialize();

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, true, false, true, LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location set up for FEFO picking.
        CreateAndUpdateLocation(Location, false, true, false, false, true);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);

        // [GIVEN] Set the Location as default on Warehouse Employee
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create Bins "BinA", and "BinB"
        LibraryWarehouse.CreateBin(ToBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        ToBin.Validate("Bin Ranking", LibraryRandom.RandIntInRange(500, 500));
        ToBin.Modify(true);
        LibraryWarehouse.CreateBin(FromBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        FromBin.Validate("Bin Ranking", LibraryRandom.RandIntInRange(100, 100));
        FromBin.Modify(true);

        // [THEN] Create Bin Content entry for "BinA"
        CreateBinContent(BinContent, ToBin, Item);

        // [GIVEN] Post inventory to bin "BinB". With Lot No. = "L2", and expiration date = "D2" >= "D1".
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        CreateAndPostItemJournalLine(Location.Code, FromBin.Code, Item."No.", '', LibraryRandom.RandInt(10), true, true);

        // [WHEN] Calculate Bin Replenishment executed
        CalculateBinReplenishment(BinContent);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        WhseWorksheetLine.FindFirst();

        // [VERIFY] Verify: From Bin Code filled after Calculate Bin Replenishment executed
        Assert.AreEqual(FromBin.Code, WhseWorksheetLine."From Bin Code", BlankCodeErr);
        Assert.AreEqual(ToBin.Code, WhseWorksheetLine."To Bin Code", BlankCodeErr);
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLineHandler,ConfirmHandlerNo,WhseSrcCreateDocReqHandler,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure ShowWarningWhenDeleteJobPlanningLineHavingQtyPicked()
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        JobNo: Code[20];
        PickQty: Decimal;
    begin
        // [SCENARIO 488261] Warning is shown when stan deletes Job or Job Planning Lines having Qty. Picked greater than Qty. Posted.
        Initialize();

        // [GIVEN] Create full WMS Location.
        CreateFullWarehouseSetup(Location);
        UpdateLocation(Location);

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Purchase Order and Warehouse Receipt.
        CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Item."No.", LibraryRandom.RandInt(0), Location.Code, false);

        // [GIVEN] Post Warehouse Receipt.
        PostWarehouseReceipt(PurchaseHeader."No.");

        // [GIVEN] Create Job with Job Task.
        CreateJobWithJobTask(JobTask);

        // [GIVEN] Generate and save Quantity to be picked in a Variable.
        PickQty := LibraryRandom.RandInt(0);

        // [GIVEN] Create Job Planning Line.
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::"Both Budget and Billable", JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        UpdateJobPlanningLine(JobPlanningLine, Item."No.", Location.Code, PickQty);

        // [GIVEN] Reserve Item from Job Planning Line.        
        LibraryVariableStorage.Enqueue(ReservationSpecificTrackingConfirmMessage);
        OpenReservationPage(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");

        // [GIVEN] Find and save Job No. in a Variable.
        Job.Get(JobTask."Job No.");
        JobNo := Job."No.";

        // [GIVEN] Create Warehouse Pick from Job.
        OpenJobAndCreateWarehousePick(Job);

        // [GIVEN] Validate Qty to Handle in Warehouse Activity Lines.
        ValidateQtyToHandleInWhseActivityLines(Location, PickQty);

        // [GIVEN] Find Warehouse Activity Header.
        FindWarehouseActivityHeader(WhseActivityHeader, Location.Code, WhseActivityHeader.Type::Pick);

        // [GIVEN] Register Pick.
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // [WHEN] Delete Job.
        asserterror Job.Delete(true);

        // [VERIFY] Job is not deleted.
        Assert.IsTrue(Job.Get(JobNo), JobIsNotFoundErr);

        // [GIVEN] Find Job Planning Line.
        JobPlanningLine.SetRange("Location Code", Location.Code);
        JobPlanningLine.FindFirst();

        // [WHEN] Delete Job PLanning Line.
        asserterror JobPlanningLine.Delete(true);

        // [VERIFY] Verify Job Planning Line is not deleted and has Qty. Picked.
        Assert.AreEqual(PickQty, JobPlanningLine."Qty. Picked", PickQtyAndQtyPickedMustMatchErr);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandlerWithLot,RegisterWhseMessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure VerifyWarehouseMovementContainsLotWithLowestBinRankingWithItemTrackingByFEFO()
    var
        Item: Record Item;
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        Bin1: Record Bin;
        ShipmentBin: Record Bin;
        AdjustmentBin: Record Bin;
        BinContent: Record "Bin Content";
        BinContent1: Record "Bin Content";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ExpirationDate: Date;
        LotNo: Text;
        ExpectedLot: Text;
    begin
        // [SCENARIO 522446] The system should not consider the quantity from "To Bin Code" while creating warehouse movement from movement worksheet.
        Initialize();

        // [GIVEN] Create an Item with Item Tracking.
        CreateItemWithItemTrackingCode(Item, true, false, true, LibraryUtility.GetGlobalNoSeriesCode(), '');

        // [GIVEN] Location set up for FEFO picking.
        CreateAndUpdateLocation(Location, true, true, true, true, true);
        Location.Validate("Pick According to FEFO", true);
        Location.Validate("Always Create Pick Line", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Directed Put-away and Pick", true);
        Location.Modify(true);

        // [GIVEN] Create Shipmennt Bin.
        CreateShipmentZone(Zone, Location.Code);
        LibraryWarehouse.CreateBin(ShipmentBin, Location.Code, LibraryUtility.GenerateGUID(), Zone.Code, Zone."Bin Type Code");

        // [GIVEN] Create Adjustment Bin.
        CreateZone(Zone, Location.Code);
        LibraryWarehouse.CreateBin(AdjustmentBin, Location.Code, LibraryUtility.GenerateGUID(), Zone.Code, Zone."Bin Type Code");

        // [GIVEN] Update Adjustment and Shipping Bin in Location.
        Location.Validate("Adjustment Bin Code", AdjustmentBin.Code);
        Location.Validate("Shipment Bin Code", ShipmentBin.Code);
        Location.Modify(true);

        // [GIVEN] Set the Location as default on Warehouse Employee.
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create a Bin with highest bin ranking.
        CreateBinWithZone(Bin, Location.Code);
        Bin.Validate("Bin Ranking", LibraryRandom.RandIntInRange(100, 100));
        Bin.Validate(Empty, true);
        Bin.Modify(true);

        // [GIVEN] Create a Bin with lowest bin ranking.
        LibraryWarehouse.CreateBin(Bin1, Location.Code, '', Bin."Zone Code", Bin."Bin Type Code");
        Bin1.Validate("Bin Ranking", LibraryRandom.RandIntInRange(90, 90));
        Bin1.Validate(Empty, true);
        Bin1.Modify(true);

        // [GIVEN] Create Bin Content for Bin "A".
        CreateBinContentWithBinAndItem(BinContent, Bin, Item);
        BinContent.Validate("Bin Type Code", Bin."Bin Type Code");
        BinContent.Modify();

        // [GIVEN] Create Bin Content for Bin "B".
        CreateBinContentWithBinAndItem(BinContent1, Bin1, Item);
        BinContent1.Validate("Bin Type Code", Bin1."Bin Type Code");
        BinContent1.Modify();

        // [GIVEN] Generate Expiration Date.
        ExpirationDate := CalcDate('<' + Format(LibraryRandom.RandIntInRange(10, 20)) + 'D>', WorkDate());

        // [GIVEN] Create Warehouse journal Line for Bin "A".
        CreateWarehouseJournalLine(
            WarehouseJournalLine,
            Bin."Location Code",
            Bin."Zone Code",
            Bin.Code,
            Item."No.",
            ExpirationDate);

        // [GIVEN] Save Lot No used for for Bin "A".
        LotNo := LibraryVariableStorage.DequeueText();

        // [GIVEN] Generate Expiration Date.
        ExpirationDate := CalcDate('<' + Format(LibraryRandom.RandIntInRange(20, 30)) + 'D>', WorkDate());  // Assign in global variable.

        // [GIVEN] Create Warehouse journal Line for Bin "B".
        CreateWarehouseJournalLine(
            WarehouseJournalLine,
            Bin1."Location Code",
            Bin1."Zone Code",
            Bin1.Code,
            Item."No.",
            ExpirationDate);

        // [GIVEN] Save Lot No used for for Bin "B".
        ExpectedLot := LibraryVariableStorage.DequeueText();

        // [GIVEN] Calculate Warehouse Adjustment Item Journal.
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');

        // [GIVEN] Post Item Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);

        // [GIVEN] Create Sales Line.
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(7, 7), Location.Code);

        // [GIVEN] Release Sales Document.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create Warehouse Shipment.
        CreateWarehouseShipment(SalesHeader);

        // [GIVEN] Create and Register pick from Wareshouse Shipment.
        CreateAndRegisterPickFromWareshouseShipment(SalesHeader."No.");

        // [GIVEN] Calculate Bin Replenishment.
        CalculateBinReplenishment(BinContent);

        // [WHEN] Create movement from Movement Worksheet.
        CreateMovementFromMovementWorksheet();

        // [VERIFY] Verify Warehouse Movement contains Lot with lowest bin ranking.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        if WarehouseActivityLine.FindSet() then
            repeat
                Assert.AreEqual(
                    ExpectedLot,
                    WarehouseActivityLine."Lot No.",
                    StrSubstNo(
                        ValueMustBeEqualErr,
                        WarehouseActivityLine.FieldCaption("Lot No."),
                        ExpectedLot,
                        WarehouseActivityLine.TableCaption()));
            until WarehouseActivityLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseShipmentErrorWhenVATBusPostingOnSalesInvoiceHeaderHasChanged()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 545336] You can assign a location with Directed Put and Pick to the Sales Invoice Lines after changing the VAT Bus. Posting Group and recalculating lines
        Initialize();

        //[GIVEN] SetStockoutWarning to false
        LibrarySales.SetStockoutWarning(false);

        //[GIVEN] Creating VAT Business Posting Group
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);

        //[GIVEN] Create Sales Invoice by page.
        CreateAndOpenSalesInvoicePage(SalesInvoice);

        //[GIVEN] Assigning Location Code
        SalesInvoice."Location Code".SetValue(LocationWhite.Code);

        // [THEN] Set Value to 'VAT Bus. Posting Group'
        asserterror SalesInvoice."VAT Bus. Posting Group".SetValue(VATBusinessPostingGroup.Code);

        // [VERIFY] Verify the Error 'Warehouse Shipment is Required'.
        Assert.ExpectedError(WarehouseShipmentRequiredError);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,ItemTrackingLinesPageHandlerTrackingOption,CalcRegenPlanReqPageHandler,ConfirmHandlerTrue')]
    procedure ExpirationDateShouldNotBeRemovedFromProdOrderLineTracking()
    var
        Customer: Record Customer;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [SCENARIO 560520] After calculating planning worksheet, expiration date field of an item tracking line of a released production order has been cleared
        Initialize();
        LibraryManufacturing.SetComponentsAtLocation('');

        // [GIVEN] Item with "Replenishment System" as "Prod. Order" and Stockkeeping Unit as "Prod. Order" with "Lot-for-Lot" and Transfer with "Fixed Reorder Qty."
        CreateTransferRoute(LocationBlue.Code, LocationRed.Code, LocationInTransit.Code);
        CreateItemWithTwoSKU(Item, LocationBlue.Code, LocationRed.Code);

        // [GIVEN] Create customer with location and a sales order
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", LocationRed.Code);
        Customer.Modify(true);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", LibraryRandom.RandInt(50), '', false);

        // [GIVEN] Create released production order for item and set item tracking information with expiration date
        CreateProdOrderForParentItem(ProductionOrder, LocationRed.Code, Item."No.", 1);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNoWithExpirationDate);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandText(10));
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(WorkDate() + LibraryRandom.RandIntInRange(100, 100));
        ProdOrderLine.OpenItemTrackingLines();

        // [GIVEN] Run "Calculate Regenerative Plan" from planning worksheet
        PlanningWorksheet.OpenEdit();
        Commit();
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(Item."No.");
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();

        // [THEN] Delete Lines from planning worksheet
        PlanningWorksheet."Delete All".Invoke();

        // [THEN] Verify Expiration Date on ItemTrackingEntries Handler.
        LibraryVariableStorage.Enqueue(TrackingOption::VerifyExpirationDate);
        LibraryVariableStorage.Enqueue(WorkDate() + LibraryRandom.RandIntInRange(100, 100));
        ProdOrderLine.OpenItemTrackingLines();
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,DummyMessageHandler,ConfirmHandlerTrue')]
    procedure OneConsumpILEIsPostedWhenPostProdJnlFromRelProdOrderHavingRoutingAndProdBOMWithRoutLinkCodeAndScrapPct()
    var
        Customer: Record Customer;
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RoutingHeader: Record "Routing Header";
        RoutingLink: Record "Routing Link";
        WorkCenter: Record "Work Center";
    begin
        // [SCENARIO 579000] One Consumption Item Ledger Entry is posted when Stan posts Production Journal from a 
        // Released Production Order having Routing and Production BOM with Routing Link Code and Scrap %.
        Initialize();

        // [GIVEN] Create Item [1] and Validate "Replenishment System", "Rounding Precision" 
        // and "Flushing Method".
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::Purchase);
        Item[1].Validate("Rounding Precision", 0.01);
        Item[1].Validate("Flushing Method", Item[1]."Flushing Method"::Backward);
        Item[1].Modify(true);

        // [GIVEN] Create a Work Center with Calendar.
        CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Create a Routing Link.
        LibraryManufacturing.CreateRoutingLink(RoutingLink);

        // [GIVEN] Create a Routing with Work Center and Routing Link.
        CreateRoutingWithWorkCenterAndRoutingLink(RoutingHeader, WorkCenter."No.", RoutingLink.Code);

        // [GIVEN] Create a Production BOM.
        CreateProductionBOM(ProductionBOMHeader, Item[1], RoutingLink.Code);

        // [GIVEN] Create Item [2] and Validate "Replenishment System", "Routing No." 
        // and "Production BOM No.".
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Routing No.", RoutingHeader."No.");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Post an Item Journal Line.
        PostItemJournalLine(Item[1]."No.", '', LibraryRandom.RandIntInRange(2000, 2000), LibraryRandom.RandIntInRange(10, 10), WorkDate(), 0);

        // [GIVEN] Create a Production Order for Item [2].
        CreateProdOrderForParentItem(ProductionOrder, '', Item[2]."No.", LibraryRandom.RandIntInRange(10, 10));

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Open Production Journal.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [WHEN] Find Item Ledger Entry.
        ItemLedgerEntry.SetRange("Item No.", Item[1]."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);

        // [THEN] Only one Consumption Item Ledger Entry is found.
        Assert.AreEqual(
            ItemLedgerEntry.Count(),
            LibraryRandom.RandIntInRange(1, 1),
            StrSubstNo(
                ILEMustNotBeFoundMoreThanErr,
                LibraryRandom.RandIntInRange(1, 1)));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ItemTrkingLinesPageHandler,CreateInvtPutAwayPickMvmtPageHandler,DummyMessageHandler')]
    procedure InvtMvmtIsRegisteredEvenIfQtyInAOIsMoreThanInBinContent()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Bin: array[3] of Record Bin;
        Item: array[3] of Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
        RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        UnitOfMeasure: Record "Unit of Measure";
        AssemblyOrder: TestPage "Assembly Order";
        LotNo: array[2] of Code[50];
    begin
        // [SCENARIO 574710] Registered Invt. Movement is created even if Quanity in Item Tracking of Assembly Line 
        // is more than that in the Bin Content of a particular Lot No.
        Initialize();

        // [GIVEN] Create a Location.
        CreateLocation(Location);

        // [GIVEN] Create three Bins.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, Bin[1].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, Bin[2].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[3], Location.Code, Bin[3].Code, '', '');

        // [GIVEN] Validate "To-Assembly Bin Code", "From-Assembly Bin Code" and 
        // "Asm.-to-Order Shpt. Bin Code" in Location. 
        Location.Validate("To-Assembly Bin Code", Bin[1].Code);
        Location.Validate("From-Assembly Bin Code", Bin[2].Code);
        Location.Validate("Asm.-to-Order Shpt. Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Create Item [1] and Validate "Replenishment System".
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::Assembly);
        Item[1].Modify(true);

        // [GIVEN] Create Item Tracking Code and Validate "Use Expiration Dates".
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Create Item [2] and Validate "Item Tracking Code".
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item[2].Modify(true);

        // [GIVEN] Create Item [3] and Validate "Item Tracking Code".
        LibraryInventory.CreateItem(Item[3]);
        Item[3].Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item[3].Modify(true);

        // [GIVEN] Create Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create Item Unit of Measure.
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item[3]."No.", UnitOfMeasure.Code, LibraryRandom.RandIntInRange(2, 2));

        // [GIVEN] Create two Assembly BOM Components.
        CreateAssemblyBomComponent(Item[2], Item[1]."No.");
        CreateAssemblyBomComponent(Item[3], Item[1]."No.");

        // [GIVEN] Create and Post Item Journal Lines.
        CreateAndPostItemJournalLines(Item[2], Item[3], Location, Bin[3], Bin[1], LotNo[1], LotNo[2]);

        // [GIVEN] Create an Assembly Header.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item[1]."No.", Location.Code, LibraryRandom.RandIntInRange(1, 1), '');

        // [GIVEN] Find Assembly Line.
        AssemblyLine.SetRange("No.", Item[2]."No.");
        AssemblyLine.FindFirst();

        // [GIVEN] Open Item Tracking Lines.
        LibraryVariableStorage.Enqueue(LotNo[1]);
        LibraryVariableStorage.Enqueue(AssemblyLine.Quantity);
        AssemblyLine.OpenItemTrackingLines();

        // [GIVEN] Find Assembly Line.
        AssemblyLine.SetRange("No.", Item[3]."No.");
        AssemblyLine.FindFirst();

        // [GIVEN] Open Item Tracking Lines.
        LibraryVariableStorage.Enqueue(LotNo[2]);
        LibraryVariableStorage.Enqueue(AssemblyLine.Quantity);
        AssemblyLine.OpenItemTrackingLines();

        // [GIVEN] Run Create Inventory Movement action from Assembly Order page.
        AssemblyOrder.OpenEdit();
        AssemblyOrder.GoToRecord(AssemblyHeader);
        AssemblyOrder."Create Inventor&y Movement".Invoke();

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Auto Fill Qty in Inventory Activity.
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // [GIVEN] Register Warehouse Activity.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Find Registered Whse. Activity Hdr.
        RegisteredInvtMovementHdr.SetRange("Location Code", Location.Code);

        // [THEN] Registered Invt. Movement Hdr. is found.
        Assert.IsFalse(RegisteredInvtMovementHdr.IsEmpty(), RegInvtMovementHdrDoesNotExistErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse VII");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse VII");

        NoSeriesSetup();
        LocationSetup();
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        CreateTransferRoute();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse VII");
    end;

    local procedure AddSpecialOrderToReqWsht(var RequisitionLine: Record "Requisition Line"; TemplateName: Code[10]; WshtName: Code[10]; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange("Worksheet Template Name", TemplateName);
        RequisitionLine.SetRange("Journal Batch Name", WshtName);
        RequisitionLine.FindFirst();
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure LocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
        CreateAndUpdateLocation(LocationSilver, true, true, true, true, true);  // Location Silver.
        CreateBinsAndUpdateLocation(LocationSilver);
        CreateAndUpdateLocation(LocationBlue, false, false, false, true, false);  // Location Blue with Require Shipment.
        CreateAndUpdateLocation(LocationRed, false, false, false, true, false);  // Location Red with Require Shipment.
        CreateAndUpdateLocation(LocationGreen, false, true, false, false, true);  // Location Green with Require Pick and Bin Manadatory.
        CreateBins(LocationGreen);
        CreateAndUpdateLocation(LocationYellow, true, true, true, true, false);  // Location Yellow with Require Put Away, Require Pick, Require Receive, Require Shipment.
        CreateAndUpdateLocation(LocationBlack, false, false, false, false, false);  // Location Black.
        CreateAndUpdateLocation(LocationOrange, false, false, false, false, false);  // Location Orange.
        CreateInTransitLocation();
    end;

    local procedure NoSeriesSetup()
    begin
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    local procedure AssignLotNoOnItemTrackingLine(var ItemTrackingLines: TestPage "Item Tracking Lines"; Quantity: Decimal)
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);  // Enqueue Lot No.
    end;

    local procedure CalcPlanForReqWsht(var Item: Record Item; var TemplateName: Code[10]; var WshtName: Code[10])
    var
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        TemplateName := SelectRequisitionTemplateName();
        LibraryPlanning.CreateRequisitionWkshName(ReqWkshName, TemplateName);
        WshtName := ReqWkshName.Name;
        LibraryPlanning.CalculatePlanForReqWksh(Item, TemplateName, WshtName, WorkDate(), WorkDate());
    end;

    local procedure CalculateCrossDock(SourceNo: Code[20])
    var
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo);
        LibraryWarehouse.CalculateCrossDockLines(
          WhseCrossDockOpportunity, '', WarehouseReceiptLine."No.", WarehouseReceiptLine."Location Code");
    end;

    local procedure CreateCrossDockLocationWithoutBins(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, true, true);
        Location.Validate("Use Cross-Docking", true);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal; UpdateExpirationDate: Boolean; UseTracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');  // Use Blank No. Series.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("Variant Code", VariantCode);
        ItemJournalLine.Modify(true);
        if UseTracking then
            ItemJournalLine.OpenItemTrackingLines(false);
        if UpdateExpirationDate then
            UpdateExpirationDateOnReservationEntry(ItemNo);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostJobJournalLine(Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        JobTask: Record "Job Task";
        JobJournalLine: Record "Job Journal Line";
        LibraryJob: Codeunit "Library - Job";
    begin
        CreateJobWithJobTask(JobTask);
        LibraryJob.GetJobJournalTemplate(JobJournalTemplate);
        LibraryJob.CreateJobJournalBatch(JobJournalTemplate.Name, JobJournalBatch);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::"Both Budget and Billable", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", ItemNo);
        JobJournalLine.Validate("Location Code", Bin."Location Code");
        JobJournalLine.Validate("Bin Code", Bin.Code);
        JobJournalLine.Validate(Quantity, Quantity);
        JobJournalLine.Modify(true);
        JobJournalLine.OpenItemTrackingLines(false);
        LibraryVariableStorage.Enqueue(PostJobJournalLines);  // Enqueue for ConfirmMessageHandler.
        LibraryVariableStorage.Enqueue(JobJournalPosted);  // Enqueue for MessageHandler.
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateAndPostSalesOrderWithItemTracking(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
    begin
        CreateSalesOrder(SalesHeader, SalesLine, CustomerNo, ItemNo, Quantity, '', false);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as SHIP and INVOICE.
    end;

    local procedure CreateAndPostTransferOrder(var TransferHeader: Record "Transfer Header"; SalesLine: Record "Sales Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        TransferLine: Record "Transfer Line";
    begin
        CreateTransferOrder(TransferHeader, TransferLine, FromLocationCode, ToLocationCode, SalesLine."No.", SalesLine.Quantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);  // Post as SHIP.
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", Bin."Location Code");
        ProductionOrder.Validate("Bin Code", Bin.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);  // CalcLines, CalcRoutings, CalcComponents as TRUE.
    end;

    local procedure CreateAndReleasePurchaseOrderWithMultipleLines(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Quantity2: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, ItemNo, Quantity, LocationCode);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity2, LocationCode);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchOrdersOnSpecialOrder(Item: Record Item)
    var
        RequisitionLine: Record "Requisition Line";
        TemplateName: Code[10];
        WshtName: Code[10];
    begin
        CalcPlanForReqWsht(Item, TemplateName, WshtName);
        AddSpecialOrderToReqWsht(RequisitionLine, TemplateName, WshtName, Item."No.");
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
        ReleasePurchaseOrders(Item."No.");
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Reserve: Boolean)
    begin
        CreateSalesOrder(SalesHeader, SalesLine, CustomerNo, ItemNo, Quantity, LocationCode, Reserve);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderByPage(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[20]; Quantity: Decimal)
    var
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(ReservationConfirmMessage);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(ReservationNotPossibleMessage);  // Enqueue for MessageHandler.
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);
        SalesOrder.SalesLines.Type.SetValue(SalesOrder.SalesLines.Type.GetOption(3));  // Option 3 is used for Item.
        SalesOrder.SalesLines."No.".SetValue(ItemNo);
        SalesOrder.SalesLines."Location Code".SetValue(LocationCode);
        SalesOrder.SalesLines.Quantity.SetValue(Quantity);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrder."No.".Value);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSpecialOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, '', ItemNo, Quantity, LocationWhite.Code, false);
        UpdatePurchasingCodeOnSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateBins(var Location: Record Location)
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
    end;

    local procedure CreateBinsAndUpdateLocation(var Location: Record Location)
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        Location.Validate("Receipt Bin Code", Bin.Code);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        Location.Validate("Shipment Bin Code", Bin.Code);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateInternalMovement(var InternalMovementHeader: Record "Internal Movement Header"; var Bin2: Record Bin; Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal; WhseItemTrackingMode: Option)
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        CreateInternalMovementHeader(InternalMovementHeader, Bin2, Bin);
        LibraryWarehouse.CreateInternalMovementLine(InternalMovementHeader, InternalMovementLine, ItemNo, Bin.Code, Bin2.Code, Quantity);
        LibraryVariableStorage.Enqueue(WhseItemTrackingMode);   // Enqueue for WhseItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(ItemNo);  // Enqueue for WhseItemTrackingLinesPageHandler.
        InternalMovementLine.OpenItemTrackingLines();
    end;

    local procedure CreateInternalMovementHeader(var InternalMovementHeader: Record "Internal Movement Header"; var Bin2: Record Bin; Bin: Record Bin)
    begin
        LibraryWarehouse.CreateBin(Bin2, Bin."Location Code", LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Bin."Location Code", Bin2.Code);
    end;

    local procedure CreateInternalMovementWithGetBinContent(var InternalMovementHeader: Record "Internal Movement Header"; var Bin2: Record Bin; Bin: Record Bin; ItemNo: Code[20])
    begin
        CreateInternalMovementHeader(InternalMovementHeader, Bin2, Bin);
        LibraryWarehouse.GetBinContentInternalMovement(InternalMovementHeader, Bin."Location Code", ItemNo, Bin.Code);
    end;

    local procedure CreateInventoryMovement(SourceNo: Code[20])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        LibraryVariableStorage.Enqueue(InventoryMovementCreatedMessage);  // Enqueue for MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(WarehouseRequest."Source Document"::"Prod. Consumption", SourceNo, false, false, true);  // TRUE for Movement.
    end;

    local procedure CreateInventoryMovementForReservedLot(var WarehouseActivityLine: Record "Warehouse Activity Line"; var LotNo: Code[50])
    var
        Item: Record Item;
        Bin: Record Bin;
        InternalMovementHeader: Record "Internal Movement Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
        Qty: Decimal;
    begin
        Qty := LibraryRandom.RandInt(100);
        CreateTrackedItemAndUpdateInventoryOnLocationWithBin(
          Item, Bin, Qty, true, false, false, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingMode::AssignLotNo, false);
        GetLotNoFromItemTrackingPageHandler(LotNo);

        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateInternalMovementHeader(InternalMovementHeader, Bin."Location Code", Bin.Code);
        LibraryWarehouse.GetBinContentInternalMovement(InternalMovementHeader, '', Item."No.", '');
        CreateInventoryMovementFromInternalMovement(InternalMovementHeader);

        CreateSalesOrder(SalesHeader, SalesLine, LibrarySales.CreateCustomerNo(), Item."No.", Qty, LocationSilver.Code, false);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        SalesLine.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(SpecificReservationTxt);
        SalesLine.ShowReservation();

        FindInventoryMovementLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, Item."No.", WarehouseActivityLine."Source Document"::" ", '');
    end;

    local procedure CreateInTransitLocation()
    begin
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryInventory.UpdateInventoryPostingSetup(LocationInTransit);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Lot: Boolean; Serial: Boolean; ManExpirDateEntryReqd: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Use Expiration Dates", ManExpirDateEntryReqd);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ManExpirDateEntryReqd);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemWithComponent(var Item: Record Item; ComponentItem: Record Item; QtyPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ComponentItem, QtyPer);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; Lot: Boolean; Serial: Boolean; ManExpirDateEntryReqd: Boolean; LotNos: Code[20]; SerialNos: Code[20])
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, Lot, Serial, ManExpirDateEntryReqd);
        LibraryInventory.CreateTrackedItem(Item, LotNos, SerialNos, ItemTrackingCode.Code);
    end;

    local procedure CreateItemWithProductionBOM(var ParentItem: Record Item; var ChildItem: Record Item; QuantityPer: Decimal; Lot: Boolean; Serial: Boolean; SerialNos: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(ParentItem);
        CreateItemWithItemTrackingCode(ChildItem, Lot, Serial, true, '', SerialNos);  // TRUE for Man. Expir. Date Entry Reqd.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem, QuantityPer);
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateItemWithReorderPolicyAsMaxQty(var Item: Record Item; var MaxInventoryQty: Decimal; var SalesQty: Decimal)
    var
        Vendor: Record Vendor;
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        SalesQty := LibraryRandom.RandInt(10);
        MaxInventoryQty := LibraryRandom.RandInt(90) + SalesQty;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Maximum Qty.");
        Item.Validate("Reorder Point", LibraryRandom.RandInt(SalesQty));
        Item.Validate("Maximum Inventory", MaxInventoryQty);
        Item.Modify(true);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationWhite.Code, Item."No.", '');
    end;

    local procedure CreateItemWithSKU(var ComponentItem: Record Item; LocationCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        CreateItem(ComponentItem, ComponentItem.Reserve, ComponentItem."Reordering Policy"::" ");
        ComponentItem.Validate("Replenishment System", ComponentItem."Replenishment System"::"Prod. Order");
        ComponentItem.Modify(true);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ComponentItem."No.", '');
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateItemWithVariant(var Item: Record Item; var ItemVariant: Record "Item Variant")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
    end;

    local procedure CreateItem(var Item: Record Item; Reserve: Enum "Reserve Method"; ReorderingPolicy: Enum "Reordering Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Reserve);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateTrackedItemAndUpdateInventoryOnLocationWithBin(var Item: Record Item; var Bin: Record Bin; Qty: Decimal; IsLotTracking: Boolean; IsSerialNoTracking: Boolean; ManExpirDateEntryReqd: Boolean; LotNos: Code[20]; SerialNos: Code[20]; ItemTrackingMode: Option; UpdateExpirDate: Boolean)
    begin
        CreateItemWithItemTrackingCode(
          Item, IsLotTracking, IsSerialNoTracking, ManExpirDateEntryReqd, LotNos, SerialNos);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryVariableStorage.Enqueue(ItemTrackingMode);
        CreateAndPostItemJournalLine(Bin."Location Code", Bin.Code, Item."No.", '', Qty, UpdateExpirDate, true);
    end;

    local procedure CreateInventoryMovementFromInternalMovement(InternalMovementHeader: Record "Internal Movement Header")
    begin
        LibraryVariableStorage.Enqueue(InventoryMovementConfirmMessage);  // Enqueue for Confirm Handler.
        LibraryVariableStorage.Enqueue(InventoryMovementCreated);  // Enqueue for Message Handler.
        LibraryWarehouse.CreateInvtMvmtFromInternalMvmt(InternalMovementHeader);
    end;

    local procedure CreateMultipleStockkeepingUnit(ItemNo: Code[20]; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        Item.SetFilter("Location Filter", '%1|%2', LocationCode, LocationCode2);
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);  // Create Per Option as Zero.
    end;

    local procedure CreatePick(SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        GetWarehouseShipmentHeader(WarehouseShipmentHeader, SourceNo);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreateProdOrderForParentItem(var ProductionOrder: Record "Production Order"; LocationCode: Code[10]; ItemNo: Code[20]; ItemQty: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, ItemQty);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);  // CalcLines, CalcRoutings, CalcComponents as TRUE.
    end;

    local procedure CreatePurchaseCreditMemoByPage(var PurchaseCreditMemo: TestPage "Purchase Credit Memo"; LocationCode: Code[10])
    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseCreditMemo.OpenNew();
        PurchaseCreditMemo."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseCreditMemo.PurchLines.Type.SetValue(PurchaseCreditMemo.PurchLines.Type.GetOption(3));  // Option 3 is used for Item.
        PurchaseCreditMemo.PurchLines."No.".SetValue(Item."No.");
        PurchaseCreditMemo.PurchLines."Location Code".SetValue(LocationCode);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity, LocationCode);
    end;

    local procedure CreatePurchaseOrderWithLot(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
    begin
        CreatePurchaseOrder(PurchaseHeader, ItemNo, Quantity, '');
        FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseInvoiceByPage(var PurchaseInvoice: TestPage "Purchase Invoice"; LocationCode: Code[10])
    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        PurchaseInvoice.OpenNew();
        PurchaseInvoice."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseInvoice.PurchLines.Type.SetValue(PurchaseInvoice.PurchLines.Type.GetOption(3));  // Option 3 is used for Item.
        PurchaseInvoice.PurchLines."No.".SetValue(Item."No.");
        PurchaseInvoice.PurchLines."Location Code".SetValue(LocationCode);
    end;

    local procedure CreatePurchaseReturnOrderByPage(var PurchaseReturnOrder: TestPage "Purchase Return Order"; LocationCode: Code[10])
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ReturnReason: Record "Return Reason";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        ReturnReason.FindFirst();
        PurchaseReturnOrder.OpenNew();
        PurchaseReturnOrder."Buy-from Vendor Name".SetValue(Vendor."No.");
        PurchaseReturnOrder.PurchLines.Type.SetValue(PurchaseReturnOrder.PurchLines.Type.GetOption(3));  // Option 3 is used for Item.
        PurchaseReturnOrder.PurchLines."No.".SetValue(Item."No.");
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        PurchaseReturnOrder.PurchLines."Return Reason Code".SetValue(ReturnReason.Code);
        PurchaseReturnOrder.PurchLines."Location Code".SetValue(LocationCode);
    end;

    local procedure CreateSalesCreditMemoByPage(var SalesCreditMemo: TestPage "Sales Credit Memo"; LocationCode: Code[10])
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        SalesCreditMemo.OpenNew();
        SalesCreditMemo."Sell-to Customer Name".SetValue(Customer."No.");
        SalesCreditMemo.SalesLines.Type.SetValue(SalesCreditMemo.SalesLines.Type.GetOption(3));  // Option 3 is used for Item.
        SalesCreditMemo.SalesLines."No.".SetValue(Item."No.");
        SalesCreditMemo.SalesLines."Location Code".SetValue(LocationCode);
    end;

    local procedure CreateSalesInvoiceByPage(No: Code[20]; CustomerNo: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenNew();
        SalesInvoice."No.".SetValue(No);
        SalesInvoice."Sell-to Customer Name".SetValue(CustomerNo);
        SalesInvoice.OK().Invoke();
    end;

    local procedure CreateSalesInvoiceWithSalesLineByPage(var SalesInvoice: TestPage "Sales Invoice"; LocationCode: Code[10])
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(Customer."No.");
        SalesInvoice.SalesLines.Type.SetValue(SalesInvoice.SalesLines.Type.GetOption(3));  // Option 3 is used for Item.
        SalesInvoice.SalesLines."No.".SetValue(Item."No.");
        SalesInvoice.SalesLines."Location Code".SetValue(LocationCode);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(50));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Reserve: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, ItemNo, Quantity, LocationCode);
        if Reserve then
            SalesLine.ShowReservation();
    end;

    local procedure CreateSalesOrderWithMultipleLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, ItemNo, Quantity, LocationCode);
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, ItemNo, Quantity, LocationCode);
    end;

    local procedure CreateSalesBlanketOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[10])
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Customer."No.");
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100), LocationCode);
    end;

    local procedure CreatePurchaseBlanketOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    var
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", Vendor."No.");
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item."No.", LibraryRandom.RandInt(100), LocationCode);
    end;

    local procedure CreateSalesOrderByPage(var SalesOrder: TestPage "Sales Order"; LocationCode: Code[10])
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);
        SalesOrder.SalesLines.Type.SetValue(SalesOrder.SalesLines.Type.GetOption(3));  // Option 3 is used for Item.
        SalesOrder.SalesLines."No.".SetValue(Item."No.");
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        SalesOrder.SalesLines."Location Code".SetValue(LocationCode);
    end;

    local procedure CreateSOFromBlanketSalesOrderWithPartialQuantity(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);  // Making Sales Order of Partial Quantity.
        SalesLine.Modify(true);
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);
    end;

    local procedure CreateSalesReturnOrderByPage(var SalesReturnOrder: TestPage "Sales Return Order"; LocationCode: Code[10])
    var
        Customer: Record Customer;
        Item: Record Item;
        ReturnReason: Record "Return Reason";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        ReturnReason.FindFirst();
        SalesReturnOrder.OpenNew();
        SalesReturnOrder."Sell-to Customer Name".SetValue(Customer."No.");
        SalesReturnOrder.SalesLines.Type.SetValue(SalesReturnOrder.SalesLines.Type.GetOption(3));  // Option 3 is used for Item.
        SalesReturnOrder.SalesLines."No.".SetValue(Item."No.");
        SalesReturnOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        SalesReturnOrder.SalesLines."Return Reason Code".SetValue(ReturnReason.Code);
        SalesReturnOrder.SalesLines."Location Code".SetValue(LocationCode);
    end;

    local procedure CreateTransferRoute()
    var
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationRed.Code, LocationBlue.Code);
        TransferRoute.Validate("In-Transit Code", LocationInTransit.Code);
        TransferRoute.Modify(true);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
    end;

    local procedure CreateWarehouseReceipt(PurchaseHeader: Record "Purchase Header")
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UseTracking: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
    begin
        CreatePurchaseOrder(PurchaseHeader, ItemNo, Quantity, LocationCode);
        if UseTracking then begin
            FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.");
            LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);
            PurchaseLine.OpenItemTrackingLines();
        end;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateWarehouseReceipt(PurchaseHeader);
    end;

    local procedure CreateWarehouseShipment(SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateWarehouseShipmentFromSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Reserve: Boolean)
    begin
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, CustomerNo, ItemNo, Quantity, LocationCode, Reserve);
        CreateWarehouseShipment(SalesHeader);
    end;

    local procedure CreateWhseRcpt(Item: Record Item) WhseRcptNo: Code[20]
    var
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        PurchLine: Record "Purchase Line";
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
    begin
        CreateAndReleasePurchOrdersOnSpecialOrder(Item);
        LibraryWarehouse.CreateWarehouseReceiptHeader(WhseReceiptHeader);
        WhseReceiptHeader.Validate("Location Code", LocationWhite.Code);
        WhseReceiptHeader.Modify(true);
        WhseRcptNo := WhseReceiptHeader."No.";

        PurchLine.SetRange("No.", Item."No.");
        PurchLine.FindSet();
        repeat
            LibraryVariableStorage.Enqueue(PurchLine."Document No.");
            GetSourceDocInbound.GetSingleInboundDoc(WhseReceiptHeader);
        until PurchLine.Next() = 0;
    end;

    local procedure CreateAndPostWarehouseShipmentFromSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrderWithMultipleLines(SalesHeader, SalesLine, CustomerNo, ItemNo, Quantity, LocationCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWarehouseShipment(SalesHeader);
        CreateAndRegisterPick(SalesHeader."No.");
        PostWarehouseShipment(SalesHeader."No.");
    end;

    local procedure CreateAndRegisterPick(SalesHeaderNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreatePick(SalesHeaderNo);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeaderNo, WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CalcConsumptionInConsumptionJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(ProductionOrderNo, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure EnqueueValuesForOrderTrackingDetailsPageHandler(ItemNo: Code[20]; Quantity: Decimal; MultipleLines: Boolean)
    begin
        LibraryVariableStorage.Enqueue(MultipleLines);  // Enqueue for MultipleLines.
        LibraryVariableStorage.Enqueue(ItemNo);  // Enqueue for Item No.
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue for Quantity.
        LibraryVariableStorage.Enqueue(Quantity - Quantity);  // Enqueue for UntrackedQuantity.
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue for Line Quantity.
    end;

    local procedure EnqueueValuesForProductionJournalHandler(ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo; No: Code[20]; Quantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode);  // Enqueue for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(No);  // Enqueue for ItemTrackingLinesPageHandler.
        if ItemTrackingMode = ItemTrackingMode::SelectLotNo then
            LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(PostJournalLinesConfirmationMessage);  // Enqueue for ConfirmHandler.
    end;

    local procedure EnqueueValuesForItemTrackingLinesPageHandler(ItemTrackingMode: Option; LotNo: Code[50]; Quantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
    end;

    local procedure FindBin(var Bin: Record Bin; Location: Record Location)
    begin
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetFilter(Code, '<>%1&<>%2', Location."Shipment Bin Code", Location."Receipt Bin Code");
        Bin.FindFirst();
    end;

    local procedure FindPickBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindPickZone(Zone, LocationCode);
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, LibraryRandom.RandInt(Bin.Count));  // Find Random Bin.
    end;

    local procedure FindPickZone(var Zone: Record Zone; LocationCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, true));  // TRUE for Put-away and Pick.
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure FindInventoryMovementLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, WarehouseActivityLine."Activity Type"::"Invt. Movement");
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
    end;

    local procedure FindPostedSalesShipment(CustomerNo: Code[20]; OrderNo: Code[20]): Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."No.");
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure FindSalesOrderLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure FindPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.FindFirst();
    end;

    local procedure FindPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.FindFirst();
    end;

    local procedure FindSalesInvoiceHeader(var SalesHeader: Record "Sales Header"; No: Code[20])
    begin
        SalesHeader.SetRange("No.", No);
        FindSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
    end;

    local procedure FindSalesReturnOrderLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Sales Order");
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseReceipt(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; ItemNo: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.SetRange("No.", WarehouseReceiptLine."No.");
        WarehouseReceiptHeader.FindFirst();
    end;

    local procedure GetLotNoFromItemTrackingPageHandler(var LotNo: Code[50])
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LotNo := DequeueVariable;
    end;

    local procedure GetShipmentLineOnSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LibrarySales.GetShipmentLines(SalesLine);
    end;

    local procedure CreateSalesDocumentLinkBlanketOrder(var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; Quantity: Decimal; DocumentType: Enum "Sales Document Type")
    var
        SalesLine2: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SalesLine."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine.Type, SalesLine."No.", Quantity);
        SalesLine2.Validate("Blanket Order No.", SalesLine."Document No.");
        SalesLine2.Validate("Blanket Order Line No.", SalesLine."Line No.");
        SalesLine2.Modify(true);
    end;

    local procedure CreatePurchaseDocumentLinkBlanketOrder(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; Quantity: Decimal; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine2: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, PurchaseLine."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine.Type, PurchaseLine."No.", Quantity);
        PurchaseLine2.Validate("Blanket Order No.", PurchaseLine."Document No.");
        PurchaseLine2.Validate("Blanket Order Line No.", PurchaseLine."Line No.");
        PurchaseLine2.Modify(true);
    end;

    local procedure GetWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure OpenItemsByLocationPageFromItemCard(ItemNo: Code[20])
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.FILTER.SetFilter("No.", ItemNo);
        ItemCard.ItemsByLocation.Invoke();
    end;

    local procedure OpenOrderTrackingPageFromPlanningWorksheet(ItemNo: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type"; Quantity: Decimal; MultipleLines: Boolean)
    var
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        EnqueueValuesForOrderTrackingDetailsPageHandler(ItemNo, Quantity, MultipleLines);
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.FILTER.SetFilter("No.", ItemNo);
        PlanningWorksheet.FILTER.SetFilter("Ref. Order Type", Format(RefOrderType));
        PlanningWorksheet.OrderTracking.Invoke();
    end;

    local procedure OpenOrderTrackingPageFromSalesOrder(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        EnqueueValuesForOrderTrackingDetailsPageHandler(ItemNo, Quantity, true);  // Multiple Lines as TRUE.
        OpenSalesOrderByPage(SalesOrder, DocumentNo);
        SalesOrder.SalesLines.OrderTracking.Invoke();
    end;

    local procedure OpenSalesOrderByPage(var SalesOrder: TestPage "Sales Order"; No: Code[20])
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure PostJobJournalLineWithSelectedItemTrackingLines(JobTask: Record "Job Task"; ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        JobJournalLine: Record "Job Journal Line";
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", ItemNo);
        JobJournalLine.Validate(Quantity, Quantity);
        JobJournalLine.Modify(true);
        JobJournalLine.OpenItemTrackingLines(false);
        LibraryVariableStorage.Enqueue(PostJobJournalLines);
        LibraryVariableStorage.Enqueue(UsageNotLinkedToBlankLineTypeMsg);
        LibraryVariableStorage.Enqueue(JobJournalPosted);
        LibraryJob.PostJobJournal(JobJournalLine);
        exit(JobJournalLine."Document No.");
    end;

    local procedure PostSalesInvoiceWithGetShipmentLinesAndItemCharge(var SalesLine: Record "Sales Line"; No: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        ItemCharge: Record "Item Charge";
        SalesHeader: Record "Sales Header";
    begin
        UpdateManualNosAsTrueOnNoSeriesSetupOfSalesInvoice();
        CreateSalesInvoiceByPage(No, CustomerNo);
        FindSalesInvoiceHeader(SalesHeader, No);
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreateSalesLine(SalesHeader, SalesLine, SalesLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandDec(10, 2), '');
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);  // Enqueue for ItemChargeAssignmentSalesPageHandler.
        SalesLine.ShowItemChargeAssgnt();
        LibrarySales.GetShipmentLines(SalesLine);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as SHIP and INVOICE.
    end;

    local procedure PostSalesReturnOrderWithGetPostedDocLinesToReverse(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]): Code[20]
    var
        ReasonCode: Record "Reason Code";
    begin
        LibraryERM.CreateReasonCode(ReasonCode);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        SalesHeader.Validate("Reason Code", ReasonCode.Code);
        SalesHeader.Modify(true);
        SalesHeader.GetPstdDocLinesToReverse();
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));  // Post as RECEIVE.
    end;

    local procedure PostSalesOrder(SellToCustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        FindSalesHeader(SalesHeader, SalesHeader."Document Type"::Order);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Ship as TRUE.
    end;

    local procedure CreateItemOnInventoryWithTracking(var LotNo: Code[50]; Quantity: Decimal): Code[20]
    var
        Item: Record Item;
        ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,SetQuantity,VerifyEntryNo;
    begin
        CreateItemWithItemTrackingCode(Item, true, false, true, LibraryUtility.GetGlobalNoSeriesCode(), '');

        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);
        CreateAndPostItemJournalLine(LocationOrange.Code, '', Item."No.", '', Quantity, true, true);
        GetLotNoFromItemTrackingPageHandler(LotNo);
        exit(Item."No.");
    end;

    local procedure PostPurchaseDocument(BuyFromVendorNo: Code[20]; DocumentType: Enum "Purchase Document Type"; Receive: Boolean; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        FindPurchaseHeader(PurchaseHeader, BuyFromVendorNo, DocumentType);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, Receive, Invoice);
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseShipment(SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        GetWarehouseShipmentHeader(WarehouseShipmentHeader, SourceNo);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure PreparationForCalcConsumptionAndOpeningProductionJournal(var ProductionOrder: Record "Production Order"): Code[20]
    var
        Bin: Record Bin;
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        Quantity: Decimal;
    begin
        // General preparation for running Calc. Consumption / openning Production Journal.
        Quantity := LibraryRandom.RandInt(10);
        FindBin(Bin, LocationGreen);
        CreateItemWithProductionBOM(ParentItem, ChildItem, Quantity, false, false, '');
        CreateAndPostItemJournalLine(
          Bin."Location Code", Bin.Code, ChildItem."No.", '', Quantity, false, false);
        UpdateBinContentForItem(LocationGreen.Code, ChildItem."No.");
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Bin, ParentItem."No.", Quantity);

        // Filled with another Bin which does not include the Item in Prod. Order Component.
        UpdateBinCodeOnProductionOrderComponent(ProdOrderComponent, Bin, ProductionOrder);

        exit(ChildItem."No.");
    end;

    local procedure RegisterWarehouseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure ReleasePurchaseOrders(ItemNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("No.", ItemNo);
        PurchLine.FindSet();
        repeat
            PurchHeader.Get(PurchHeader."Document Type"::Order, PurchLine."Document No.");
            LibraryPurchase.ReleasePurchaseDocument(PurchHeader);
        until PurchLine.Next() = 0;
    end;

    local procedure SelectConsumptionLine(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20])
    begin
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindFirst();
    end;

    local procedure SelectRequisitionTemplateName(): Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Planning);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        exit(ReqWkshTemplate.Name);
    end;

    local procedure UndoSalesShipmentLine(DocumentNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(UndoShipmentConfirmationMessage);  // UndoShipmentMessage Used in ConfirmHandler.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UndoMultipleShipmentLines(OrderNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        LibraryVariableStorage.Enqueue(UndoShipmentConfirmationMessage);  // UndoShipmentMessage Used in ConfirmHandler.
        LibraryVariableStorage.Enqueue(UndoShipmentAfterPickedConfirmationMsg);
        LibraryVariableStorage.Enqueue(UndoShipmentAfterPickedConfirmationMsg);
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UpdateAlwaysCreatePickLineOnLocation(var Location: Record Location; NewAlwaysCreatePickLine: Boolean) OldAlwaysCreatePickLine: Boolean
    begin
        OldAlwaysCreatePickLine := Location."Always Create Pick Line";
        Location.Validate("Always Create Pick Line", NewAlwaysCreatePickLine);
        Location.Modify(true);
    end;

    local procedure UpdateBinCodeOnProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; var Bin: Record Bin; ProductionOrder: Record "Production Order") BinCode: Code[20]
    begin
        BinCode := Bin.Code;
        Bin.Next();  // Next is required to get second different Bin.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Location Code", Bin."Location Code");
        ProdOrderComponent.Validate("Bin Code", Bin.Code);
        ProdOrderComponent.Modify(true);
    end;

    local procedure UpdateBinCodeOnPutAwayLine(Bin: Record Bin; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Zone Code", Bin."Zone Code");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.ModifyAll("Bin Code", Bin.Code, true);
    end;

    local procedure UpdateExpirationDateOnReservationEntry(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Expiration Date", WorkDate(), true);
    end;

    local procedure UpdateLotNoOnInventoryMovementLine(ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Prod. Consumption", SourceNo,
          WarehouseActivityLine."Activity Type"::"Invt. Movement");
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateManualNosAsTrueOnNoSeriesSetupOfSalesInvoice()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
    begin
        SalesReceivablesSetup.Get();
        NoSeries.Get(SalesReceivablesSetup."Invoice Nos.");
        NoSeries.Validate("Manual Nos.", true);
        NoSeries.Modify(true);
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdatePurchasingCodeOnSalesLine(var SalesLine: Record "Sales Line")
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQuantityBaseOnReservationEntry(ItemNo: Code[20]; Quantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        ReservationEntry.Validate("Quantity (Base)", Quantity);
        ReservationEntry.Modify(true);
    end;

    local procedure UpdateQuantityOnSalesLine(var SalesLine: Record "Sales Line"; Quantity: Decimal)
    begin
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQtyToShipOnSalesLine(SellToCustomerNo: Code[20]; ShipQty: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        FindSalesHeader(SalesHeader, SalesHeader."Document Type"::Order);
        FindSalesOrderLine(SalesLine, SalesHeader."No.");
        SalesLine.Validate("Qty. to Ship", ShipQty);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQtyToReceiveOnPurchaseLine(BuyFromVendorNo: Code[20]; DocumentType: Enum "Purchase Document Type"; ReceiveQty: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseHeader(PurchaseHeader, BuyFromVendorNo, DocumentType);
        FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.");
        PurchaseLine.Validate("Qty. to Receive", ReceiveQty);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateQuantityOnSalesAndReservationLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        UpdateQuantityBaseOnReservationEntry(ItemNo, Quantity);
        FindSalesReturnOrderLine(SalesLine, SalesHeader."No.", ItemNo);
        UpdateQuantityOnSalesLine(SalesLine, Quantity);
    end;

    local procedure UpdateReplenishmentSystemAsTransferOnSKU(LocationCode: Code[10]; ItemNo: Code[20]; TransferFromCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.Get(LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::Transfer);
        StockkeepingUnit.Validate("Transfer-from Code", TransferFromCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateSerialNoOnInventoryMovementLines(ItemNo: Code[20]; ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; MoveNext: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindInventoryMovementLine(
          WarehouseActivityLine, ActionType, ItemNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", SourceNo);
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
        if MoveNext then
            ItemLedgerEntry.Next(WarehouseActivityLine.Count);  // Required for Entering Wrong Serial No.
        repeat
            WarehouseActivityLine.Validate("Serial No.", ItemLedgerEntry."Serial No.");
            WarehouseActivityLine.Modify(true);
            ItemLedgerEntry.Next();
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateUsePutAwayWorksheetOnLocation(var Location: Record Location; UsePutAwayWorksheet: Boolean)
    begin
        Location.Validate("Use Put-away Worksheet", UsePutAwayWorksheet);
        Location.Modify(true);
    end;

    local procedure UpdateVariantCodeOnTransferLine(var TransferLine: Record "Transfer Line"; VariantCode: Code[10])
    begin
        TransferLine.Validate("Variant Code", VariantCode);
        TransferLine.Modify(true);
    end;

    local procedure UpdateVendorNoOnStockkeepingUnit(LocationCode: Code[10]; ItemNo: Code[20])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        StockkeepingUnit.Get(LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Vendor No.", Vendor."No.");
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateBinContentForItem(LocationCode: Code[10]; ItemNo: Code[20])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();
        BinContent.Validate(Default, false);
        BinContent.Validate(Fixed, false);
        BinContent.Modify(true);
    end;

    local procedure UndoPurchaseReceiptLine(ItemNo: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        LibraryVariableStorage.Enqueue(UndoReceiptConfirmationMessage);  // UndoReceiptMessage Used in ConfirmHandler.
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
    end;

    local procedure UndoReturnReceiptLine(DocumentNo: Code[20])
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        LibraryVariableStorage.Enqueue(UndoReturnReceiptConfirmationMessage);  // Enqueue for ConfirmHandler.
        ReturnReceiptLine.SetRange("Document No.", DocumentNo);
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);
    end;

    local procedure VerifyInternalMovementHeaderExists(LocationCode: Code[10]; ToBinCode: Code[20])
    var
        InternalMovementHeader: Record "Internal Movement Header";
    begin
        InternalMovementHeader.SetRange("Location Code", LocationCode);
        InternalMovementHeader.SetRange("To Bin Code", ToBinCode);
        Assert.IsTrue(InternalMovementHeader.IsEmpty, StrSubstNo(InternalMovementHeaderDelete, InternalMovementHeader.TableCaption()));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; NextLine: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindSet();
        if NextLine then
            GLEntry.Next();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyGLEntryByGenPostingGroups(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLEntry.SetRange("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyInternalMovementLine(Bin: Record Bin; ItemNo: Code[20]; ToBinCode: Code[20]; Quantity: Decimal)
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        InternalMovementLine.SetRange("Item No.", ItemNo);
        InternalMovementLine.SetRange("Location Code", Bin."Location Code");
        InternalMovementLine.SetRange("From Bin Code", Bin.Code);
        InternalMovementLine.SetRange("To Bin Code", ToBinCode);
        InternalMovementLine.FindFirst();
        InternalMovementLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Entry Type"; DocumentType: Enum "Item Ledger Document Type"; LocationCode: Code[10]; ItemNo: Code[20]; LotNo: Code[50]; VariantCode: Code[10]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.SetRange("Variant Code", VariantCode);
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyInventoryMovementLinesForProdConsumption(ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; SourceNo: Code[20]; BinCode: Code[20]; Quantity: Decimal; ExpectedTotalQuantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ActualTotalQuantity: Decimal;
    begin
        FindInventoryMovementLine(
          WarehouseActivityLine, ActionType, ItemNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", SourceNo);
        repeat
            WarehouseActivityLine.TestField("Bin Code", BinCode);
            WarehouseActivityLine.TestField(Quantity, Quantity);
            ActualTotalQuantity += WarehouseActivityLine.Quantity;
        until WarehouseActivityLine.Next() = 0;
        Assert.AreEqual(ExpectedTotalQuantity, ActualTotalQuantity, QuantityMustBeSame);
    end;

    local procedure VerifyInventoryMovementLineForLot(Bin: Record Bin; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindInventoryMovementLine(WarehouseActivityLine, ActionType, ItemNo, WarehouseActivityLine."Source Document"::" ", '');
        WarehouseActivityLine.TestField("Location Code", Bin."Location Code");
        WarehouseActivityLine.TestField("Bin Code", Bin.Code);
        WarehouseActivityLine.TestField("Lot No.", LotNo);
        WarehouseActivityLine.TestField("Expiration Date", WorkDate());
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyInventoryMovementLinesForSerial(Bin: Record Bin; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; TotalQuantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        FindInventoryMovementLine(WarehouseActivityLine, ActionType, ItemNo, WarehouseActivityLine."Source Document"::" ", '');
        repeat
            WarehouseActivityLine.TestField("Location Code", Bin."Location Code");
            WarehouseActivityLine.TestField("Bin Code", Bin.Code);
            WarehouseActivityLine.TestField("Serial No.");
            WarehouseActivityLine.TestField("Expiration Date", WorkDate());
            WarehouseActivityLine.TestField(Quantity, 1);   // Value required for Serial No. Item Tracking.
            Quantity += WarehouseActivityLine.Quantity;
        until WarehouseActivityLine.Next() = 0;
        Assert.AreEqual(TotalQuantity, Quantity, QuantityMustBeSame);
    end;

    local procedure VerifyJobLedgerEntry(DocumentNo: Code[20]; JobNo: Code[20]; Quantity: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.FindFirst();
        JobLedgerEntry.TestField("Job No.", JobNo);
        JobLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyOrderTracking(var OrderTracking: TestPage "Order Tracking")
    var
        ItemNo: Variant;
        Quantity: Variant;
        UntrackedQuantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(Quantity);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(UntrackedQuantity);  // Dequeue variable.
        OrderTracking.CurrItemNo.AssertEquals(ItemNo);
        OrderTracking.Quantity.AssertEquals(Quantity);
        OrderTracking."Untracked Quantity".AssertEquals(UntrackedQuantity);
    end;

    local procedure VerifyOrderTrackingLine(var OrderTracking: TestPage "Order Tracking")
    var
        Quantity: Variant;
        LineQuantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(Quantity);  // Dequeue variable.
        LineQuantity := Quantity;
        OrderTracking.Quantity.AssertEquals(LineQuantity);
    end;

    local procedure VerifyOrderTrackingOnReqLineAndSalesOrder(ItemNo: Code[20]; Quantity: Decimal; SalesHeaderNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        OpenOrderTrackingPageFromPlanningWorksheet(ItemNo, RequisitionLine."Ref. Order Type"::Transfer, Quantity, false);  // Multiple Lines as FALSE.
        OpenOrderTrackingPageFromPlanningWorksheet(ItemNo, RequisitionLine."Ref. Order Type"::Purchase, Quantity, true);  // Multiple Lines as TRUE.
        OpenOrderTrackingPageFromSalesOrder(SalesHeaderNo, ItemNo, -Quantity);
    end;

    local procedure VerifyProdOrderLineNotExists(ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Init();
        ProdOrderLine.SetRange("Item No.", ItemNo);
        Assert.RecordIsEmpty(ProdOrderLine);
    end;

    local procedure VerifyProductionOrderComponent(ProdOrderComponent: Record "Prod. Order Component"; QuantityPicked: Decimal; RemainingQuantity: Decimal; BinCode: Code[20])
    begin
        ProdOrderComponent.Find();
        ProdOrderComponent.TestField("Qty. Picked", QuantityPicked);
        ProdOrderComponent.TestField("Remaining Quantity", RemainingQuantity);
        ProdOrderComponent.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyPurchRcptLine(OrderNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; MoveNext: Boolean)
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.SetRange("Location Code", LocationCode);
        PurchRcptLine.FindSet();
        if MoveNext then
            PurchRcptLine.Next();
        PurchRcptLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPutAwayLine(ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; CrossDockInformation: Option)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Cross-Dock Information", CrossDockInformation);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange(Quantity, Quantity);
        Assert.AreEqual(
          1, WarehouseActivityLine.Count, 'Unexpected no. of Whse activity lines for Put Away ' + WarehouseActivityLine."No.");
    end;

    local procedure VerifyQtyToCrossDock(ItemNo: Code[20]; QtyToReceive: Decimal; QtyToCrossDock: Decimal)
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.SetRange("Item No.", ItemNo);
        WhseRcptLine.SetRange("Qty. to Receive", QtyToReceive);
        WhseRcptLine.FindFirst();
        WhseRcptLine.TestField("Qty. to Cross-Dock", QtyToCrossDock);
    end;

    local procedure VerifySalesInvoiceLine(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("No.", ItemNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifySalesShipmentLine(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; MoveNext: Boolean)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.FindSet();
        if MoveNext then
            SalesShipmentLine.Next();
        SalesShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseEntry(EntryType: Option; SourceDocument: Enum "Warehouse Journal Source Document"; ItemNo: Code[20]; BinCode: Code[20]; LotNo: Code[50]; Quantity: Decimal; MoveNext: Boolean)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Source Document", SourceDocument);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Bin Code", BinCode);
        WarehouseEntry.SetRange("Lot No.", LotNo);
        WarehouseEntry.FindSet();
        if MoveNext then
            WarehouseEntry.Next();
        WarehouseEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehousePickLine(ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField(Quantity, Quantity);
        WarehouseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyWarehouseReceiptLine(SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; QtyToCrossDock: Decimal; LocationCode: Code[10]; MoveNext: Boolean)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo);
        if MoveNext then
            WarehouseReceiptLine.Next();
        WarehouseReceiptLine.TestField("Item No.", ItemNo);
        WarehouseReceiptLine.TestField(Quantity, Quantity);
        WarehouseReceiptLine.TestField("Qty. to Cross-Dock", QtyToCrossDock);
        WarehouseReceiptLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyNoErrorForJobJnlReversal(ManExpirDateEntryReqd: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        JobTask: Record "Job Task";
        LotNo: Variant;
        DocumentNo: Code[20];
        Quantity: Decimal;
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
    begin
        // Setup: Create and Post Purchase Order with Assigned Lot No. and Expiration Date.
        // Post Job Journal with Select Entries and with Positive Quantity.
        Initialize();
        Quantity := LibraryRandom.RandInt(50);
        CreateItemWithItemTrackingCode(Item, true, false, ManExpirDateEntryReqd, LibraryUtility.GetGlobalNoSeriesCode(), '');
        CreatePurchaseOrderWithLot(PurchaseHeader, Item."No.", Quantity);
        UpdateExpirationDateOnReservationEntry(Item."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        CreateJobWithJobTask(JobTask);
        PostJobJournalLineWithSelectedItemTrackingLines(JobTask, Item."No.", Quantity);
        EnqueueValuesForItemTrackingLinesPageHandler(ItemTrackingMode::SelectLotNo, LotNo, -Quantity);

        // Exercise: Post Job Journal.
        DocumentNo := PostJobJournalLineWithSelectedItemTrackingLines(JobTask, Item."No.", -Quantity);

        // Verify: Verify Job Journal Line with Negative Quantity and Expiration Date Posted with out error Message.
        VerifyJobLedgerEntry(DocumentNo, JobTask."Job No.", -Quantity);
    end;

    local procedure VerifyWarehouseEntryWithTotalLines(EntryType: Option; SourceDocument: Enum "Warehouse Journal Source Document"; ItemNo: Code[20]; WarehouseEntryCount: Integer)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Source Document", SourceDocument);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        Assert.AreEqual(WarehouseEntryCount, WarehouseEntry.Count, WarehouseEntryMsg);
    end;

    local procedure MakeSalesOrderAndVerifyErr(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; ExpectedQty: Decimal)
    begin
        Commit(); // COMMIT is necessary here since the following LibraryInventory.BlanketSalesOrderMakeOrder will invoke RUNMODAL.
        asserterror LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);
        Assert.ExpectedError(
          StrSubstNo(
            NotMadeOrderErr, SalesLine.FieldCaption("Qty. to Ship (Base)"), SalesLine.Type,
            SalesLine."No.", SalesLine.FieldCaption("Line No."), SalesLine."Line No.", ExpectedQty));
    end;

    local procedure MakePurchaseOrderAndVerifyErr(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; ExpectedQty: Decimal)
    begin
        Commit(); // COMMIT is necessary here since the following LibraryInventory.BlanketPurchaseOrderMakeOrder will invoke RUNMODAL.
        asserterror LibraryPurchase.BlanketPurchaseOrderMakeOrder(PurchaseHeader);
        Assert.ExpectedError(
          StrSubstNo(
            NotMadeOrderErr, PurchaseLine.FieldCaption("Qty. to Receive (Base)"), PurchaseLine.Type,
            PurchaseLine."No.", PurchaseLine.FieldCaption("Line No."), PurchaseLine."Line No.", ExpectedQty));
    end;

    local procedure UpdateLocation(var Location: Record Location)
    var
        Bin: Record Bin;
    begin
        Location.Validate("Directed Put-away and Pick", false);
        Location.Validate("Require Put-away", false);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), Database::Bin), '', '');
        Location.Validate("To-Job Bin Code", Bin.Code);
        Location.Modify(true);
    end;

    local procedure SetWhseItemTrackingLineFilters(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ItemNo: Code[20]; LocationCode: Code[20]; JobNo: Code[20])
    begin
        WhseItemTrackingLine.SetRange("Item No.", ItemNo);
        WhseItemTrackingLine.SetRange("Location Code", LocationCode);
        WhseItemTrackingLine.SetRange("Source ID", JobNo);
    end;

    local procedure UpdateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate("Location Code", LocationCode);
        JobPlanningLine.Validate("Quantity", Quantity);
        JobPlanningLine.Modify(true);
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; LocationCode: Code[10]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.SetRange(Type, ActivityType);
        WarehouseActivityHeader.FindFirst();
    end;

    local procedure OpenJobAndCreateWarehousePick(Job: Record Job)
    var
        JobCardPage: TestPage "Job Card";
    begin
        JobCardPage.OpenEdit();
        JobCardPage.GoToRecord(Job);
        JobCardPage."Create Warehouse Pick".Invoke(); // Needs WhseSrcCreateDocReqHandler
        JobCardPage.Close();
    end;

    local procedure OpenReservationPage(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        JobPlanningLines.OpenView();
        JobPlanningLines.Filter.SetFilter("Job No.", JobNo);
        JobPlanningLines.Filter.SetFilter("Job Task No.", JobTaskNo);
        JobPlanningLines.Reserve.Invoke();
    end;

    local procedure CreateCompItem(var Item: Record Item; FlushingType: Enum "Flushing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Flushing Method", FlushingType);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
    end;

    local procedure CreateReleasedProdOrder(ProdItem: Record Item; CompItem: Record Item; Location: Record Location; Qty: Decimal)
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionBOM(ProdBOMHeader, ProdItem, CompItem, 1, '');
        LibraryManufacturing.CreateProductionOrder(ProdOrder, ProdOrder.Status::Released, ProdItem, Location.Code, '', Qty, WorkDate());
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; WorksheetTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        RequisitionLine.SetRange("Worksheet Template Name", WorksheetTemplateName);
        RequisitionLine.SetRange("Journal Batch Name", JournalBatchName);
        RequisitionLine.FindFirst();
    end;

    local procedure OpenRequisitionWorksheetPage(var ReqWorksheet: TestPage "Req. Worksheet"; Name: Code[20])
    begin
        ReqWorksheet.OpenEdit();
        ReqWorksheet.CurrentJnlBatchName.SetValue(Name);
    end;

    local procedure CreateRequisitionWorksheetline(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; ItemVariantCode: Code[10])
    begin
        CreateBlankRequisitionLine(RequisitionLine);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate("Variant Code", ItemVariantCode);
        RequisitionLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        // Use Random for Quantity.
        RequisitionLine.Validate("Due Date", WorkDate());
        RequisitionLine.Modify(true);
    end;

    local procedure CreateBlankRequisitionLine(var RequisitionLine: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
    end;

    local procedure CreateBinAndBinContent(var Bin: Record Bin; LocationCode: Code[10]; ItemNo: Code[20]; UnitOfMeasure: Code[10]; IsDefault: Boolean)
    var
        BinContent: Record "Bin Content";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", '', Bin.Code, ItemNo, '', UnitOfMeasure);
        BinContent.Validate(Default, IsDefault);
        BinContent.Modify(true);
    end;

    local procedure CreateBinContent(var BinContent: Record "Bin Content"; var Bin: Record Bin; Item: Record Item)
    begin
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate("Bin Ranking", Bin."Bin Ranking");
        BinContent.Validate(Fixed, true);
        BinContent.Validate("Min. Qty.", LibraryRandom.RandIntInRange(2, 2));
        BinContent.Validate("Max. Qty.", LibraryRandom.RandIntInRange(5, 5));
        BinContent.Modify(true);
    end;

    local procedure CalculateBinReplenishment(BinContent: Record "Bin Content")
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, BinContent."Location Code");
        LibraryWarehouse.CalculateBinReplenishment(BinContent, WhseWorksheetName, BinContent."Location Code", false, true, false);
    end;

    local procedure ValidateQtyToHandleInWhseActivityLines(Location: Record Location; PickQty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Qty. to Handle", PickQty);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.FindLast();
        WarehouseActivityLine.Validate("Qty. to Handle", PickQty);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure CreateShipmentZone(var Zone: Record Zone; LocationCode: Code[10])
    var
        WarehouseClass: Record "Warehouse Class";
    begin
        LibraryWarehouse.CreateWarehouseClass(WarehouseClass);
        LibraryWarehouse.CreateZone(
            Zone,
            '',
            LocationCode,
            LibraryWarehouse.SelectBinType(false, true, false, false),
            WarehouseClass.Code,
            '',
            0,
            false);
    end;

    local procedure CreateZone(var Zone: Record Zone; LocationCode: Code[10])
    var
        WarehouseClass: Record "Warehouse Class";
    begin
        LibraryWarehouse.CreateWarehouseClass(WarehouseClass);
        LibraryWarehouse.CreateZone(
            Zone,
            '',
            LocationCode,
            LibraryWarehouse.SelectBinType(false, false, false, false),
            WarehouseClass.Code,
            '',
            0,
            false);
    end;

    local procedure CreateBinWithZone(var Bin: Record Bin; LocationCode: Code[10])
    var
        BinType: Record "Bin Type";
        Zone: Record Zone;
    begin
        BinType.Get(LibraryWarehouse.SelectBinType(false, false, true, true));
        LibraryWarehouse.CreateZone(Zone, '', LocationCode, BinType.Code, '', '', LibraryRandom.RandIntInRange(100, 100), false);
        LibraryWarehouse.CreateBin(Bin, LocationCode, '', Zone.Code, BinType.Code);
    end;

    local procedure CreateBinContentWithBinAndItem(var BinContent: Record "Bin Content"; var Bin: Record Bin; Item: Record Item)
    begin
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate("Bin Ranking", Bin."Bin Ranking");
        BinContent.Validate(Fixed, true);
        BinContent.Validate("Min. Qty.", LibraryRandom.RandIntInRange(5, 5));
        BinContent.Validate("Max. Qty.", LibraryRandom.RandIntInRange(10, 10));
        BinContent.Modify(true);
    end;

    local procedure CreateWarehouseJournalLine(
        var WarehouseJournalLine: Record "Warehouse Journal Line";
        LocationCode: Code[10];
        ZoneCode: Code[10];
        BinCode: Code[20];
        ItemNo: Code[20];
        ExpirationDate: Date)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
            WarehouseJournalLine,
            WarehouseJournalBatch."Journal Template Name",
            WarehouseJournalBatch.Name,
            LocationCode,
            ZoneCode,
            BinCode,
            WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
            ItemNo,
            LibraryRandom.RandIntInRange(10, 10));

        WarehouseJournalLine.OpenItemTrackingLines();
        UpdateExpirationDateOnWhseItemTrackingLine(LocationCode, ItemNo, ExpirationDate);

        // Register Warehouse Item Journal.
        LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalLine."Journal Template Name",
            WarehouseJournalLine."Journal Batch Name",
            LocationCode,
            false);
    end;

    local procedure UpdateExpirationDateOnWhseItemTrackingLine(LocationCode: Code[10]; ItemNo: Code[20]; ExpirationDate: Date)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.SetRange("Location Code", LocationCode);
        WhseItemTrackingLine.SetRange("Item No.", ItemNo);
        WhseItemTrackingLine.FindFirst();

        WhseItemTrackingLine.Validate("Expiration Date", ExpirationDate);
        WhseItemTrackingLine.Modify(true);
    end;

    local procedure CreateAndRegisterPickFromWareshouseShipment(SalesHeaderNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeaderNo);
        RegisterWarehouseActivity(
            WarehouseActivityLine,
            WarehouseActivityLine."Source Document"::"Sales Order",
            SalesHeaderNo,
            WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreatePickFromWarehouseShipment(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure RegisterWarehouseActivity(
        var WarehouseActivityLine: Record "Warehouse Activity Line";
        SourceDocument: Enum "Warehouse Activity Source Document";
        SourceNo: Code[20];
        ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindWarehouseShipmentLine(
        var WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SourceDocument: Enum "Warehouse Activity Source Document";
        SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure CreateMovementFromMovementWorksheet()
    var
        DummyWhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
    begin
        WhseSourceCreateDocument.SetWhseWkshLine(DummyWhseWorksheetLine);
        WhseSourceCreateDocument.UseRequestPage(false);
        WhseSourceCreateDocument.Run();
    end;

    local procedure CreateAndOpenSalesInvoicePage(var SalesInvoice: TestPage "Sales Invoice")
    begin
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".SetValue(LibrarySales.CreateCustomerNo());
        SalesInvoice.SalesLines.Type.SetValue(SalesInvoice.SalesLines.Type.GetOption(3));  // Option 3 is used for Item.
        SalesInvoice.SalesLines."No.".SetValue(CreateInventoriableItem());
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(5));
    end;

    local procedure CreateInventoriableItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Inventory);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);

        exit(Item."No.")
    end;

    local procedure CreateTransferRoute(TransferFrom: Code[10]; TransferTo: Code[10]; InTransit: Code[10])
    var
        TransferRoute: Record "Transfer Route";
    begin
        if not TransferRoute.Get(TransferFrom, TransferTo) then begin
            LibraryWarehouse.CreateTransferRoute(TransferRoute, TransferFrom, TransferTo);
            TransferRoute.Validate("In-Transit Code", InTransit);
            TransferRoute.Modify(true);
        end;
    end;

    local procedure CreateItemWithTwoSKU(var Item: Record Item; LocationCode: Code[10]; LocationCode1: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        CreateItemWithItemTrackingCode(Item, true, false, true, LibraryUtility.GetGlobalNoSeriesCode(), '');
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item."Reorder Point" := LibraryRandom.RandIntInRange(500, 500);
        Item."Reorder Quantity" := LibraryRandom.RandIntInRange(100, 100);
        Item."Minimum Order Quantity" := LibraryRandom.RandIntInRange(1, 1);
        Item."Order Multiple" := LibraryRandom.RandIntInRange(1, 1);
        Item."Use Cross-Docking" := false;
        Item.Modify(true);

        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, Item."No.", '');
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::"Prod. Order");
        StockkeepingUnit."Reorder Point" := LibraryRandom.RandIntInRange(500, 500);
        StockkeepingUnit."Reorder Quantity" := LibraryRandom.RandIntInRange(100, 100);
        StockkeepingUnit."Minimum Order Quantity" := LibraryRandom.RandIntInRange(1, 1);
        StockkeepingUnit."Order Multiple" := LibraryRandom.RandIntInRange(1, 1);
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");
        StockkeepingUnit.Modify(true);

        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode1, Item."No.", '');
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::Transfer);
        StockkeepingUnit."Reorder Point" := LibraryRandom.RandIntInRange(500, 500);
        StockkeepingUnit."Reorder Quantity" := LibraryRandom.RandIntInRange(100, 100);
        StockkeepingUnit."Minimum Order Quantity" := LibraryRandom.RandIntInRange(1, 1);
        StockkeepingUnit."Order Multiple" := LibraryRandom.RandIntInRange(1, 1);
        StockkeepingUnit.Validate("Transfer-from Code", LocationCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateWorkCenterWithCalendar(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Work Center Group Code", '1');
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(50, 50));
        WorkCenter.Validate("Unit of Measure Code", 'HOURS');
        WorkCenter.Validate(Capacity, LibraryRandom.RandIntInRange(1, 1));
        WorkCenter.Validate(Efficiency, LibraryRandom.RandIntInRange(100, 100));
        WorkCenter.Validate("Shop Calendar Code", '1');
        WorkCenter.Modify(true);

        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', Today()), CalcDate('<1M>', Today()));
    end;

    local procedure CreateRoutingWithWorkCenterAndRoutingLink(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; RoutingLinkCode: Code[10]): Code[20]
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)), RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Wait Time", LibraryRandom.RandIntInRange(14, 14));
        RoutingLine.Validate("Fixed Scrap Quantity", LibraryRandom.RandIntInRange(1500, 1500));
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; RoutinglinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 1));
        ProductionBOMLine.Validate("Scrap %", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMLine.Validate("Routing Link Code", RoutinglinkCode);
        ProductionBOMLine.Modify(true);

        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UnitAmount: Decimal; PostingDate: Date; AppliesToEntryNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine."Applies-to Entry" := AppliesToEntryNo;
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemChargeAssignmentSales.GetShipmentLines.Invoke();
        ItemChargeAssignmentSales."Qty. to Assign".SetValue(DequeueVariable);
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        DequeueVariable: Variant;
        QuantityBase: Variant;
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
        ItemNo: Code[20];
        TrackingQuantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::AssignLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
                end;
            ItemTrackingMode::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            ItemTrackingMode::AssignMultipleLotNo:
                begin
                    TrackingQuantity := ItemTrackingLines.Quantity3.AsDecimal() / 2;  // Value required for test.
                    AssignLotNoOnItemTrackingLine(ItemTrackingLines, TrackingQuantity);
                    ItemTrackingLines.Next();
                    AssignLotNoOnItemTrackingLine(ItemTrackingLines, TrackingQuantity);
                end;
            ItemTrackingMode::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::SelectSerialNo:
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemNo := DequeueVariable;
                    ItemLedgerEntry.SetRange("Item No.", ItemNo);
                    ItemLedgerEntry.FindLast();
                    ItemTrackingLines."Serial No.".SetValue(ItemLedgerEntry."Serial No.");
                end;
            ItemTrackingMode::SelectLotNo:
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    LibraryVariableStorage.Dequeue(QuantityBase);
                    ItemTrackingLines."Lot No.".SetValue(DequeueVariable);
                    ItemTrackingLines."Quantity (Base)".SetValue(QuantityBase);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    local procedure CreateLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Put-away", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Inventory Put-away");
        Location.Validate("Asm. Consump. Whse. Handling", Location."Asm. Consump. Whse. Handling"::"Inventory Movement");
        Location.Validate("Job Consump. Whse. Handling", Location."Job Consump. Whse. Handling"::"Inventory Pick");
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLines(Item: Record Item; Item2: Record Item; Location: Record Location; Bin: Record Bin; Bin2: Record Bin; var LotNo: Code[50]; var LotNo2: Code[50])
    var
        ItemJournalLine: array[4] of Record "Item Journal Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);

        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine[1], ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine[1]."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandIntInRange(30, 30));
        ItemJournalLine[1].Validate("Location Code", Location.Code);
        ItemJournalLine[1].Validate("Bin Code", Bin.Code);
        ItemJournalLine[1].Modify(true);

        LotNo := LibraryUtility.GenerateRandomCode20(Item.FieldNo("Lot Nos."), Database::Item);

        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandIntInRange(30, 30));
        ItemJournalLine[1].OpenItemTrackingLines(false);

        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine[2], ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine[2]."Entry Type"::"Positive Adjmt.", Item2."No.", LibraryRandom.RandIntInRange(20, 20));
        ItemJournalLine[2].Validate("Location Code", Location.Code);
        ItemJournalLine[2].Validate("Bin Code", Bin.Code);
        ItemJournalLine[2].Modify(true);

        LotNo2 := LibraryUtility.GenerateRandomCode20(Item.FieldNo("Lot Nos."), Database::Item);

        LibraryVariableStorage.Enqueue(LotNo2);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandIntInRange(20, 20));
        ItemJournalLine[2].OpenItemTrackingLines(false);

        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine[3], ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine[3]."Entry Type"::"Positive Adjmt.", Item2."No.", LibraryRandom.RandIntInRange(4, 4));
        ItemJournalLine[3].Validate("Location Code", Location.Code);
        ItemJournalLine[3].Validate("Bin Code", Bin2.Code);
        ItemJournalLine[3].Modify(true);

        LibraryVariableStorage.Enqueue(LotNo2);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandIntInRange(4, 4));
        ItemJournalLine[3].OpenItemTrackingLines(false);

        ItemUnitOfMeasure.SetRange("Item No.", Item2."No.");
        ItemUnitOfMeasure.SetRange("Qty. per Unit of Measure", LibraryRandom.RandIntInRange(2, 2));
        ItemUnitOfMeasure.FindFirst();

        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine[4], ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine[4]."Entry Type"::"Positive Adjmt.", Item2."No.", LibraryRandom.RandIntInRange(3, 3));
        ItemJournalLine[4].Validate("Location Code", Location.Code);
        ItemJournalLine[4].Validate("Bin Code", Bin2.Code);
        ItemJournalLine[4].Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ItemJournalLine[4].Modify(true);

        LibraryVariableStorage.Enqueue(LotNo2);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandIntInRange(6, 6));
        ItemJournalLine[4].OpenItemTrackingLines(false);

        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
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
        BomComponent.Validate(BomComponent."Quantity per", LibraryRandom.RandIntInRange(30, 30));
        BomComponent.Insert(true);
    end;


    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
        LotNo: Variant;
        QuantityBase: Variant;
        EntryNo: Variant;
        ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,SetQuantity;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::AssignLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
                end;
            ItemTrackingMode::SelectEntries:
                begin
                    LibraryVariableStorage.Dequeue(LotNo);
                    LibraryVariableStorage.Dequeue(QuantityBase);
                    LibraryVariableStorage.Dequeue(EntryNo);
                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(QuantityBase);
                    ItemTrackingLines."Appl.-to Item Entry".SetValue(EntryNo);
                end;
            ItemTrackingMode::SetQuantity:
                begin
                    LibraryVariableStorage.Dequeue(QuantityBase);
                    LibraryVariableStorage.Dequeue(EntryNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(QuantityBase);
                    ItemTrackingLines."Appl.-to Item Entry".AssertEquals(EntryNo)
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesSNHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
        SerialNo: Variant;
        QuantityBase: Variant;
        ItemTrackingMode: Option " ",AssignLotNo,AssignSerialNo,AssignMultipleLotNo,SelectEntries,SelectSerialNo,SelectLotNo;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::AssignSerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Serial No.".Value);
                end;
            ItemTrackingMode::SelectSerialNo:
                begin
                    LibraryVariableStorage.Dequeue(SerialNo);
                    LibraryVariableStorage.Dequeue(QuantityBase);
                    ItemTrackingLines."Serial No.".SetValue(SerialNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(QuantityBase);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ReserveFromCurrentLineHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure WhseSrcCreateDocReqHandler(var CreatePickReqPage: TestRequestPage "Whse.-Source - Create Document")
    begin
        CreatePickReqPage.DoNotFillQtytoHandle.SetValue(true);
        CreatePickReqPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, LocalMessage) > 0, Message);
    end;

    [MessageHandler]
    procedure DummyMessageHandler(Message: Text[1024])
    begin
        // Dummy message handler
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingDetailsPageHandler(var OrderTracking: TestPage "Order Tracking")
    var
        Variant: Variant;
    begin
        // Verify Item No, Quantity and UntrackedQuantity.
        LibraryVariableStorage.Dequeue(Variant);
        VerifyOrderTracking(OrderTracking);
        VerifyOrderTrackingLine(OrderTracking);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.FILTER.SetFilter("Entry Type", ProductionJournal."Entry Type".GetOption(6));  // Value 6 is used for Consumption.
        ProductionJournal.ItemTrackingLines.Invoke();
        ProductionJournal.Post.Invoke();
        ProductionJournal.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentLinePageHandler(var SalesShipmentLines: TestPage "Sales Shipment Lines")
    begin
        SalesShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        DequeueVariable: Variant;
        WhseItemTrackingMode: Option SelectSerialNo,SelectLotNo;
        ItemNo: Code[20];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        WhseItemTrackingMode := DequeueVariable;
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemNo := DequeueVariable;
        case WhseItemTrackingMode of
            WhseItemTrackingMode::SelectSerialNo:
                begin
                    ItemLedgerEntry.SetRange("Item No.", ItemNo);
                    ItemLedgerEntry.FindSet();
                    repeat
                        WhseItemTrackingLines."Serial No.".SetValue(ItemLedgerEntry."Serial No.");
                        WhseItemTrackingLines.Quantity.SetValue(ItemLedgerEntry.Quantity);
                        WhseItemTrackingLines.Next();
                    until ItemLedgerEntry.Next() = 0;
                end;
            WhseItemTrackingMode::SelectLotNo:
                begin
                    ItemLedgerEntry.SetRange("Item No.", ItemNo);
                    ItemLedgerEntry.FindSet();
                    repeat
                        WhseItemTrackingLines."Lot No.".SetValue(ItemLedgerEntry."Lot No.");
                        WhseItemTrackingLines.Quantity.SetValue(ItemLedgerEntry.Quantity);
                        WhseItemTrackingLines.Next();
                    until ItemLedgerEntry.Next() = 0;
                end;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler2(var ProductionJournal: TestPage "Production Journal")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        ProductionJournal.FILTER.SetFilter("Entry Type", ProductionJournal."Entry Type".GetOption(6)); // Value 6 is used for Consumption.
        ProductionJournal."Item No.".AssertEquals(ItemNo);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SourceDocumentsPageHandler(var SourceDocuments: Page "Source Documents"; var Response: Action)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Order");
        WarehouseRequest.SetFilter("Source No.", LibraryVariableStorage.DequeueText());
        WarehouseRequest.FindFirst();
        SourceDocuments.SetRecord(WarehouseRequest);
        Response := ACTION::LookupOK;
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandlerWithLot(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(WhseItemTrackingLines."Lot No.".Value());
        WhseItemTrackingLines.Quantity.SetValue(WhseItemTrackingLines.Quantity3.AsInteger());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ProductionJournalModalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.FlushingFilter.SetValue("Flushing Method Filter"::Manual);
        ProductionJournal.Filter.SetFilter("Entry Type", Format("Item Ledger Entry Type"::Output));
        ProductionJournal.Post.Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure RegisterWhseMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, RegisterWhseMessageLbl) > 0, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcRegenPlanReqPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    begin
        CalculatePlanPlanWksh.MPS.SetValue(true);
        CalculatePlanPlanWksh.MRP.SetValue(true);
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.EndingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.NoPlanningResiliency.SetValue(LibraryVariableStorage.DequeueBoolean());
        CalculatePlanPlanWksh.Item.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateInvtPutAwayPickMvmtPageHandler(var CreateInvtPutAwayPickMvmt: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutAwayPickMvmt.CInvtMvmt.SetValue(true);
        CreateInvtPutAwayPickMvmt.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandlerTrackingOption(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
    begin
        case LibraryVariableStorage.DequeueInteger() of
            TrackingOption::AssignLotNoWithExpirationDate:
                begin
                    ItemTrackingLines.New();
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines."Expiration Date".SetValue(LibraryVariableStorage.DequeueDate());
                end;
            TrackingOption::VerifyExpirationDate:
                ItemTrackingLines."Expiration Date".AssertEquals(LibraryVariableStorage.DequeueDate());
        end;

        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrkingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;
}

