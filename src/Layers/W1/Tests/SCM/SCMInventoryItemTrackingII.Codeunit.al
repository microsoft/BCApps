codeunit 137261 "SCM Inventory Item Tracking II"
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
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJob: Codeunit "Library - Job";
        isInitialized: Boolean;
        IsUsingSimpleYesConfirmHandler: Boolean;
        AvailabilityWarning: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        DeleteItemTrackingCodeError: Label 'You cannot delete %1 %2 because it is used on one or more items.', Comment = '%1:FieldCaption1,%2:Value1';
        MultipleExpirDateError: Label 'There are multiple expiration dates registered for lot %1.';
        NegativeSelectedQuantityError: Label 'The value must be greater than or equal to 0. Value: -%1.';
        SelectedQuantityError: Label 'You cannot select more than';
        SerialLotConfirmMessage: Label 'Do you want to reserve specific tracking numbers?';
        PickCreated: Label 'Number of Invt. Pick activities created: 1 out of a total of 1.';
        ReservEntryError: Label 'There is no Reservation Entry within the filter.';
        AssignSerialNoStatus: Label 'Assign Serial No must be TRUE.';
        ExistingSalesLnITError: Label 'Item tracking is defined for item %1 in the Sales Line.';
        WrongSerialNoErr: Label 'Serial No is wrong.';
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo,EditValue,SelectEntries,UpdateQtyToInvoice,AssignLotNo2,AssignQty,ReSelectEntries,AssignMoreThanPurchasedQty,SetNewLotNo,EditSNValue,SetNewSN,SetLotAndSerial,CheckExpDateControls,CreateCustomizedSN,AssignPackageNo,SetNewPackageNo,AssignTwoLotNos,AssignLotNoAndPackageNo,AssignPackageNoAndLotNo,AssignSerialNoWithLotNo,AssignSerialNoWithPackageNo,AssignSerialNoWithLotNoAndPackageNo,CreateCustomizedSNWithLotNo,CreateCustomizedSNWithPackageNo,CreateCustomizedSNWithLotNoAndPackageNo;
        TheLotNoInfoDoesNotExistErr: Label 'The Lot No. Information does not exist. Identification fields and values:';
        TheSerialNoInfoDoesNotExistErr: Label 'The Serial No. Information does not exist. Identification fields and values:';
        LotNoBySNNotFoundErr: Label 'A lot number could not be found for serial number';
        QtyToInvoiceDoesNotMatchItemTrackingErr: Label 'The quantity to invoice does not match the quantity defined in item tracking.';
        InventoryNotAvailableErr: Label '%1 %2 is not available on inventory or it has already been reserved for another document.', Comment = '%1 = Item Tracking ID, %2 = Item Tracking No."';
        CloseItemTrackingLinesWithQtyZeroConfirmErr: Label 'One or more lines have tracking specified';
        ReservationIsNotCreatedForSOErr: Label 'Reservation is not created for Sales Order: %1', Comment = '%1 = Sales Order No.';
        SingleExpirationDateErr: Label 'New Expiration Date must be equal to ''%1', Comment = '%1=Workdate';
        CreateSNInfo: Boolean;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PartialInvoicePurchaseWithIT()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase Order]
        // [SCENARIO] Fully received purchase order with serial no. tracked item cannot be partially invoiced if "Qty. to Invoice" on the purchase line does not match "Qty. to Invoice" in item tracking.
        Initialize();

        // [GIVEN] Create Purchase Order with Item with Serial Specific Item Tracking and Post Purchase Order Receipt.
        CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(false, true, false));
        CreatePurchaseOrder(PurchaseLine, Item."No.", LibraryRandom.RandInt(20));
        AssignSerialNoAndReceivePurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseLine.Find();

        // [WHEN] Post Partial Invoice from Purchase Order.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] "The quantity to invoice does not match item tracking" error message is raised.
        Assert.ExpectedError(QtyToInvoiceDoesNotMatchItemTrackingErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ErrorForDeleteItemTrackingCode()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // Verify Error while Deleting Item Tracking Code after creating inventory with Item Tracking.

        // Setup: Create Item Journal Line with Serial Specific Item Tracking and post.
        Initialize();
        CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(false, true, false));
        CreateItemJournalLine(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));  // Take random for Quantity and used blank for Location and Bin Code.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        ItemTrackingCode.Get(Item."Item Tracking Code");

        // Exercise: Delete Item Tracking Code.
        asserterror ItemTrackingCode.Delete(true);

        // Verify: Verify error message while Deleting Item Tracking Code.
        Assert.ExpectedError(StrSubstNo(DeleteItemTrackingCodeError, Item.FieldCaption("Item Tracking Code"), ItemTrackingCode.Code));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingCodeWithAutoAssignedPackageNo()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // Verify package number cab ne auto assigned after creating inventory with Item Tracking.

        // Setup: Create Item Journal Line with Serial Specific Item Tracking and post.
        Initialize();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false, true);
        CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        CreateItemJournalLine(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));  // Take random for Quantity and used blank for Location and Bin Code.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignPackageNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify error message while Deleting Item Tracking Code.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Package No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LotNoOnPurchaseOrderFromCarryOutActMsg()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Vendor: Record Vendor;
        LotNo: Variant;
    begin
        // Verify Lot No. in Purchase Order created from Sales Order through Carry Out Action Msg.

        // Setup: Create Item, Location, Vendor and Sales Order with Item Tracking.
        Initialize();
        CreateSetupforSalesOrder(SalesLine, true, false);
        Item.Get(SalesLine."No.");
        LibraryPurchase.CreateVendor(Vendor);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarning);  // Enqueue value for ConfirmHandler.
        SalesLine.OpenItemTrackingLines();
        LibraryVariableStorage.Dequeue(LotNo);

        // Exercise: Generate Purchase Order through Carry Out Action Msg.
        CalcRegenPlanAndCarryOutActionMsg(Item, SalesLine."Location Code", Vendor."No.");

        // Verify: Verify Lot No. in Reservation Entry for generated Purchase Order.
        VerifyPurchaseOrderItemTracking(SalesLine."Location Code", Item."No.", LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteSerialNoOnPlanningWorksheet()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Verify Reservation Entry for Deleted Item Tracking on Planning Worksheet.

        // Setup: Create Item, Location, Vendor and Sales Order with Item Tracking.
        Initialize();
        CreateSetupforSalesOrder(SalesLine, false, true);
        Item.Get(SalesLine."No.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarning);  // Enqueue value for ConfirmHandler.
        SalesLine.OpenItemTrackingLines();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));  // Dates based on WORKDATE.

        // [GIVEN] Now set the confirm handler to simple yes.
        IsUsingSimpleYesConfirmHandler := true;
        // Exercise: Delete Item Tracking Lines from Planning Worksheet.
        DeleteItemTrackingLines(SalesLine);

        // Verify: Verify Deleted Item Tracking in Reservation Entry from Planning Worksheet.
        VerifyDeletedItemTracking(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SalesLineErrorWithNegativeSelectedQty()
    var
        Quantity: Decimal;
    begin
        // Verify error while negative values is taken in the Selected Quantity field on Item Tracking Summary page.

        // Setup: Create Item, create and post Purchase Order, create Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandInt(20);  // Take random for Quantity.
        SelectITEntriesOnSalesLine(Quantity, -1, StrSubstNo(NegativeSelectedQuantityError, Quantity));  // -1 for sign factor.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SelectedQtyErrorOnSalesLine()
    begin
        // Verify error for Selected Quantity field on Item Tracking Summary page after creating Sales Order.

        // Setup: Create Item, create and post Purchase Order, create Sales Order.
        Initialize();
        SelectITEntriesOnSalesLine(10 + LibraryRandom.RandInt(10), 1, StrSubstNo(SelectedQuantityError));  // Take random Quantity greater than 1 and 1 for sign factor.
    end;

    local procedure SelectITEntriesOnSalesLine(Quantity: Integer; SignFactor: Integer; ExpectedError: Text[100])
    var
        SalesLine: Record "Sales Line";
    begin
        // Create Item, create and post Purchase Order, create Sales Order.
        SetupSalesAndPurchEntryWithIT(SalesLine, Quantity);
        LibraryVariableStorage.Enqueue(SignFactor * SalesLine.Quantity);

        // Exercise: Assign Item Tracking on Sales Line.
        asserterror SalesLine.OpenItemTrackingLines();

        // Verify: Verify error for Select Quantity on Sales Line.
        Assert.ExpectedError(ExpectedError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SelectedQtyErrorOnSalesLineWithReserv()
    var
        SalesLine: Record "Sales Line";
        SummaryOption: Option SetQuantity,VerifyQuantity;
    begin
        // Verify error for Selected Quantity field on Item Tracking Summary page after creating Sales Order with Reservation.

        // Setup: Create Item, create and post Purchase Order, create Sales Order.
        Initialize();
        SetupSalesAndPurchEntryWithIT(SalesLine, LibraryRandom.RandInt(10));  // Take random Quantity.
        LibraryVariableStorage.Enqueue(1);  // Enqueue 1 for Quantity as Item Tracking code is Serial Specific for ItemTrackingSummaryPageHandler.

        // Exercise: Assign Item Tracking and Reservation on Sales Line.
        asserterror AssignTrackingAndReserveOnSalesLine(SalesLine, SummaryOption::SetQuantity, SalesLine.Quantity);

        // Verify: Verify error for Select Quantity on Sales Line.
        Assert.ExpectedError(SelectedQuantityError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SelectedQtyOnSalesLineWithReserv()
    var
        SalesLine: Record "Sales Line";
        SummaryOption: Option SetQuantity,VerifyQuantity;
    begin
        // Verify Selected Quantity on Item Tracking Summary page after creating Sales Order with Reservation.

        // Setup: Create Item, create and post Purchase Order, create Sales Order.
        Initialize();
        SetupSalesAndPurchEntryWithIT(SalesLine, LibraryRandom.RandInt(10));  // Take random Quantity.
        LibraryVariableStorage.Enqueue(1);  // Enqueue 1 for Quantity as Item Tracking code is Serial Specific for ItemTrackingSummaryPageHandler.

        // Exercise: Item Tracking and Reservation on Sales Line.
        AssignTrackingAndReserveOnSalesLine(SalesLine, SummaryOption::VerifyQuantity, 0);

        // Verify: Verify Selected Quantity on Item Tracking Summary page.Verification done in ItemTrackingSummaryPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ExpirDateOnItemTrackingSummaryPage()
    var
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SummaryOption: Option SetQuantity,VerifyQuantity,VerifyExpirationDate;
    begin
        // Verify Expiration Date on Item Tracking Summary page after creating Sales Order.

        // Setup: Create Item, create and post Purchase Order, create Sales Order.
        Initialize();
        SetupSalesAndPurchEntryWithIT(SalesLine, LibraryRandom.RandInt(10));  // Take random Quantity.

        // Enuque values for ItemTrackingLinesPageHandler and ItemTrackingSummaryPageHandler.Taking 1 for Quantity as Item Tracking code is Serial Specific.
        LibraryVariableStorage.Enqueue(1);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        LibraryVariableStorage.Enqueue(SummaryOption::VerifyExpirationDate);
        LibraryVariableStorage.Enqueue(1);
        FindItemLedgerEntry(ItemLedgerEntry, SalesLine."No.");
        LibraryVariableStorage.Enqueue(ItemLedgerEntry."Expiration Date");

        // Exercise: Assign Item Tracking on Sales Line.
        SalesLine.OpenItemTrackingLines();

        // Verify: Verify Expiration Date on Item Tracking Summary page.Verification done in ItemTrackingSummaryPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithExpirDateAndIT()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // Verify Sales Order is posted successfully created with Item Tracking and Expiration Date.

        // Setup: Create Item, create and post Purchase Order, create Sales Order with Expiration Date and Item Tracking.
        Initialize();
        SetupSalesAndPurchEntryWithIT(SalesLine, LibraryRandom.RandInt(10));  // Take random Quantity.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        LibraryERM.FindGLAccount(GLAccount);
        UpdateGeneralLedgerSetup(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", GLAccount."No.");
        LibraryVariableStorage.Enqueue(1);
        SalesLine.OpenItemTrackingLines();

        // Exercise: Post Sales Order.
        DocumentNo := PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", true);

        // Verify: Verify Sales Order has been posted successfully.
        SalesInvoiceHeader.Get(DocumentNo);

        // Tear Down.
        UpdateGeneralLedgerSetup(
          SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", GeneralPostingSetup."Sales Account");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure CreateInvPickOnSalesOrderWithIT()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // Verify Message while creating Inventory Pick on Sales Order with Item Tracking.

        // Setup: Create and post Purchase Order, create Sales Order with Item Tracking.
        Initialize();
        PostPurchaseOrderWithLocation(PurchaseLine);
        CreateSalesOrderWithIT(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity, 1);  // Taking 1 for Quantity as Item Tracking code is Serial Specific.

        // Exercise: Create Inventory Pick on Sales Order.
        CreateInventoryPickOnSalesLine(SalesLine);

        // Verify message that Pick has been created. Verification done in MessageHandlerValidateMessage.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler,MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure ReservEntryErrorAfterPostInvPickOnSalesOrder()
    var
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        No: Code[20];
    begin
        // Verify Reservation Entry error if an Inventory Pick on Sales Order is created and posted.

        // Setup: Create and post Purchase Order, create and post Inventory Pick on Sales Order.
        Initialize();
        PostPurchaseOrderWithLocation(PurchaseLine);
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.");
        CreateSalesOrderWithIT(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity / 2, 1);  // Taking partial Quantity and 1 for Quantity as Item Tracking code is Serial Specific.
        LibraryERM.FindGLAccount(GLAccount);
        UpdateGeneralLedgerSetup(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", GLAccount."No.");
        No := CreateInventoryPickOnSalesLine(SalesLine);
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::"Invt. Pick", No);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // Exercise.
        asserterror FindReservationEntryForSerialNo(SalesLine."No.", PurchaseLine."Location Code", ItemLedgerEntry."Serial No.");

        // Verify.
        Assert.ExpectedError(ReservEntryError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SelectedQtyErrorAfterPostInvPickOnSalesOrder()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // Verify error for Selected Quantity field on Item Tracking Summary page after an Inventory Pick on Sales Order is created and posted.

        // Setup:
        Initialize();
        PostWhseRcptAndRegisterPutAway(PurchaseLine);
        CreateWhseShptAndRegisterPick(PurchaseLine);

        // Exercise: Item Tracking and Reservation on Sales Line.
        asserterror CreateSalesOrderWithIT(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity / 2, 1);  // Taking partial Quantity and 1 for Quantity as Item Tracking code is Serial Specific.

        // Verify: Verify error for Select Quantity on Sales Line.
        Assert.ExpectedError(SelectedQuantityError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ExpirDateOnILEAfterRegisterPutAway()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ExpirationDate: Date;
    begin
        // Verify Expiration Date on Item Ledger Entry When Put Away is Registered.

        // Setup: Create Purchase Order, post Warehouse Receipt, register Put Away.
        Initialize();
        PostWhseRcptAndRegisterPutAway(PurchaseLine);
        Item.Get(PurchaseLine."No.");
        ExpirationDate := CalcDate(Item."Expiration Calculation", WorkDate());

        // Exercise: Create Sales Order with Item Tracking.
        CreateSalesOrderWithIT(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity / 2, 1);  // Taking partial Quantity and 1 for Quantity as Item Tracking code is Serial Specific.

        // Verify: Verify Expiration Date on Item Ledger Entry.
        VerifyExpirationDateOnItemLedgerEntry(SalesLine."No.", ExpirationDate);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ExpirDateOnILEAfterRegisterPick()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ExpirationDate: Date;
    begin
        // Verify Expiration Date on Item Ledger Entry When Pick is Registered.

        // Setup: Create Purchase Order, post Warehouse Receipt, Register Put Away, create Warehouse Shipment and register Pick.
        Initialize();
        PostWhseRcptAndRegisterPutAway(PurchaseLine);
        CreateWhseShptAndRegisterPick(PurchaseLine);
        Item.Get(PurchaseLine."No.");
        ExpirationDate := CalcDate(Item."Expiration Calculation", WorkDate());

        // Exercise: Create Sales Order with Item Tracking.
        CreateSalesOrderWithIT(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity / 2, 0);  // Taking partial Quantity and 0 for Quantity as Item Tracking code is Serial Specific.

        // Verify: Verify Expiration Date on Item Ledger Entry.
        VerifyExpirationDateOnItemLedgerEntry(SalesLine."No.", ExpirationDate);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SelectedQtyErrorWithAssignITManually()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        SalesLine: Record "Sales Line";
    begin
        // Verify error for Selected Quantity field on Item Tracking Summary page after assigning Item Tracking manually.

        // Setup: Create and post Purchase Order.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreatePurchaseOrderWithLocation(PurchaseLine, Location.Code, '');
        AssignSerialNoOnPurchaseOrder(PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Create Sales Order and Assign Item Tracking.
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, PurchaseLine."No.", Location.Code, PurchaseLine.Quantity / 2);  // Take partial Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarning);
        SalesLine.OpenItemTrackingLines();

        // Exercise: Create another Sales Order and assign Item Tracking.
        asserterror CreateSalesOrderWithIT(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity / 2, 1);  // Taking partial Quantity and 0 for Quantity as Item Tracking code is Serial Specific.

        // Verify: Verify error for Selected Quantity field on Item Tracking Summary page.
        Assert.ExpectedError(SelectedQuantityError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostItemReclassJournalWithLotNo()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Posting of Item Reclass. Journal with Lot Tracked Item.

        // Setup: Create and post Item Journal with Item Tracking, create Reclassification Journal with Item Tracking.
        Initialize();
        CreateAndPostItemJournalLineWithIT(ItemJournalLine);
        CreateItemReclassificationJournal(
          ItemJournalLine, ItemJournalLine."Item No.", ItemJournalLine."Location Code", ItemJournalLine."Bin Code",
          ItemJournalLine.Quantity);

        // Exercise: Post Item Reclass. Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify Location on Warehouse entries.
        VerifyWarehouseEntry(ItemJournalLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CreateItemReclassJournalWithIT_ExpDateNotVisible()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // When Use Expiration Dates = false, the column "New Expiration Date" is neither shown nor editable on the tracking page in Item Reclassification.
        // [SCENARIO 459882] "Expiration Date" field is not visible.

        CreateTrackedItemAndPostItemJournal(ItemJournalLine, false);

        // Setup: Create Item Reclass Line 
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer, ItemJournalLine."Item No.",
          ItemJournalLine.Quantity);
        ItemJournalLine.Validate("Location Code", ItemJournalLine."Location Code");
        ItemJournalLine.Validate("Bin Code", ItemJournalLine."Bin Code");
        ItemJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(TrackingOption::CheckExpDateControls); // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(false); // Enqueue value for CheckExpDateControls ExpirationDateExpectedEditability.
        LibraryVariableStorage.Enqueue(false); // Enqueue value for CheckExpDateControls NewExpirationDateExpectedEditability.
        ItemJournalLine.OpenItemTrackingLines(true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CreateItemReclassJournalWithIT_ExpDateVisible()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // When Use Expiration Dates = true, the column "New Expiration Date" is shown as editable on the tracking page in Item Reclassification.
        // [SCENARIO 459882] "Expiration Date" field is visible and not editable.
        Initialize();

        CreateTrackedItemAndPostItemJournal(ItemJournalLine, true);

        // Setup: Create Item Reclass Line 
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer, ItemJournalLine."Item No.",
          ItemJournalLine.Quantity);
        ItemJournalLine.Validate("Location Code", ItemJournalLine."Location Code");
        ItemJournalLine.Validate("Bin Code", ItemJournalLine."Bin Code");
        ItemJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(TrackingOption::CheckExpDateControls); // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(false); // Enqueue value for CheckExpDateControls ExpirationDateExpectedEditability.
        LibraryVariableStorage.Enqueue(true); // Enqueue value for CheckExpDateControls NewExpirationDateExpectedEditability.
        ItemJournalLine.OpenItemTrackingLines(true);
    end;

    local procedure CreateTrackedItemAndPostItemJournal(var ItemJournalLine: Record "Item Journal Line"; UseExpirationDates: Boolean)
    var
        Item: Record Item;
        Bin: Record Bin;
        LotNo: Variant;
    begin
        // Setup: Create item that has Use Expiration Dates = UseExpirationDates
        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(true, false, UseExpirationDates));

        // Setup: Post Item Journal with Item Tracking
        CreateLocationWithBin(Bin);
        CreateItemJournalLine(ItemJournalLine, Item."No.", Bin."Location Code", Bin.Code, LibraryRandom.RandInt(10));  // Take random Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryVariableStorage.Dequeue(LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateHandlerForSetQuantity')]
    [Scope('OnPrem')]
    procedure PostPartialPurchOrderWithSerialNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        Quantity: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify Purchase Order is posted partially with Serial Tracked Item.

        // Setup: Create Item, create Purchase Order and Receive partially.
        Initialize();
        CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(false, true, false));
        CreatePurchaseOrder(PurchaseLine, Item."No.", 2 * LibraryRandom.RandInt(100));  // Take random Quantity.
        UpdatePurchaseLineAndAssignIT(
          PurchaseLine, PurchaseLine.FieldNo("Qty. to Receive"), PurchaseLine.Quantity / 2, TrackingOption::AssignSerialNo,
          PurchaseLine.Quantity / 2);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post Purchase Order as Receive partially.

        // Update Qty to Invoice on Purchase Line.
        Quantity := LibraryRandom.RandInt(PurchaseLine."Quantity Received" - 1);  // Take random Quantity less than Quantity Received.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        UpdatePurchaseLineAndAssignIT(
          PurchaseLine, PurchaseLine.FieldNo("Qty. to Invoice"), PurchaseLine."Quantity Received" - Quantity,
          TrackingOption::UpdateQtyToInvoice, Quantity);

        // Exercise: Post Purchase Order as Invoice partially.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);  // Post Purchase Order as Invoice.

        // Verify: Verify Quantity on Posted Purchase Invoice Line.
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Quantity, PurchaseLine."Qty. to Invoice");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ExpirDateOnPurchaseOrderWithLotNo()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        LotNo: Variant;
        ExpirationDate: Date;
    begin
        // Verify Expiration Date for Item Tracking if it has already been assigned to Lot No.

        // Setup: Create and post Purchase Order.
        Initialize();
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, CreateAndUpdateItem(false, true), TrackingOption::AssignLotNo);
        LibraryVariableStorage.Dequeue(LotNo);
        Item.Get(PurchaseLine."No.");
        ExpirationDate := CalcDate(Item."Expiration Calculation", WorkDate());

        // Create another Purchase Order.
        CreatePurchaseOrder(PurchaseLine, PurchaseLine."No.", PurchaseLine.Quantity);  // Take random Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::EditValue);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);

        // Exercise: Assign Item Tracking on Purchase Line.
        PurchaseLine.OpenItemTrackingLines();

        // Verify: Verify Expiration Date on Reservation Entry.
        VerifyExpirationDateForItemTracking(PurchaseLine."No.", ExpirationDate);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure UpdatedExpirDateOnPurchOrder()
    var
        PurchaseLine: Record "Purchase Line";
        LotNo: Variant;
        ExpirationDate: Date;
    begin
        // Verify Expiration date is updated  for Item Tracking if it is updated in Item Ledger Entry.

        // Setup: Create and post Purchase Order and update Expiration Date on Item Ledger Entry.
        Initialize();
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, CreateAndUpdateItem(false, true), TrackingOption::AssignLotNo);
        LibraryVariableStorage.Dequeue(LotNo);
        ExpirationDate := UpdateExpirDateOnILE(PurchaseLine."No.");

        // Exercise: Create Purchase Order and assign Item Tracking.
        CreatePurchaseOrderWithIT(PurchaseLine, PurchaseLine."No.", LotNo);

        // Verify: Verify Expiration Date on Reservation Entry.
        VerifyExpirationDateForItemTracking(PurchaseLine."No.", ExpirationDate);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure MultipleExpirDateOnPurchOrder()
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        LotNo: Variant;
        ExpirationDate: Date;
    begin
        // Verify Expiration Date is not updated on Purchase Line if multiple Expiration dates for the same lot No. exist in Item Ledger Entry.

        // Setup: Create and post Purchase Order having same Lot No. and update Expiration Date on Item Ledger Entry.
        Initialize();
        LotNo := SetupForMultipleExpirDateOnILE(PurchaseLine);
        Item.Get(PurchaseLine."No.");
        ExpirationDate := CalcDate(Item."Expiration Calculation", WorkDate());

        // Exercise: Create Purchase Order.
        CreatePurchaseOrderWithIT(PurchaseLine, PurchaseLine."No.", LotNo);

        // Verify: Verify Expiration Date on Reservation Entry.
        VerifyExpirationDateForItemTracking(PurchaseLine."No.", ExpirationDate);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure MultipleExpirDateErrorForSameLotNo()
    var
        PurchaseLine: Record "Purchase Line";
        LotNo: Variant;
    begin
        // Verify error while posting Purchase Order if multiple Expiration dates for the same lot No. exist in Item Ledger Entry.

        // Setup: Create and post Purchase Order having same Lot No. and update Expiration Date on Item Ledger Entry.
        Initialize();
        LotNo := SetupForMultipleExpirDateOnILE(PurchaseLine);
        CreatePurchaseOrderWithIT(PurchaseLine, PurchaseLine."No.", LotNo);

        // Exercise.
        asserterror PostPurchaseOrder(PurchaseLine);

        // Verify: Verify error while posting Purchase Order
        Assert.ExpectedError(StrSubstNo(MultipleExpirDateError, LotNo));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure RecalculateQtyOnItemTrackingLinesPage()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        SummaryOption: Option SetQuantity,VerifyQuantity,VerifyExpirationDate,AssignQty,SelectEntries,ReSelectEntries;
    begin
        // Recalculate Quantity on Item Tracking Lines Page.

        // Setup: Create and Post Purchase order with Lot No.
        Initialize();
        CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, false, false));
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, Item."No.", TrackingOption::AssignLotNo2);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, Item."No.", '', (PurchaseLine.Quantity - LibraryRandom.RandInt(10)));  // Random Sales Quantity less than Purchase Quantity for test case.
        EnqueueQuantityForReselectEntries(
          TrackingOption::ReSelectEntries, SummaryOption::SelectEntries, SummaryOption::ReSelectEntries,
          PurchaseLine.Quantity - SalesLine.Quantity, 0, SalesLine.Quantity);

        // Exercise: Open Item Tracking Lines Page.
        SalesLine.OpenItemTrackingLines();

        // Verify: Verify Enqueue Quantity values on Item Tracking Summary Page Handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure RecalculateQtyOnITLinesPageWithMoreQtythanPurchase()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        QuantityBase: Decimal;
        SummaryOption: Option SetQuantity,VerifyQuantity,VerifyExpirationDate,AssignQty,SelectEntries,ReSelectEntries;
    begin
        // Recalculate Quantity on Sales Order Item Tracking Lines Page With More Quantity than Purchase Quantity.

        // Setup: Create and Post Purchase order with Lot No,Create Sales order,Assign Lot.
        Initialize();
        CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, false, false));
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, Item."No.", TrackingOption::AssignLotNo2);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, Item."No.", '', (PurchaseLine.Quantity - 1));  // Sales Quantity less than Purchase Quantity for test case.
        QuantityBase := LibraryRandom.RandInt(10) + PurchaseLine.Quantity;  // Take Random Quantity Greater than Purchase Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignMoreThanPurchasedQty);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(SummaryOption::SelectEntries);  // Enqueue value for ItemTrackingSummaryPageHandler.
        LibraryVariableStorage.Enqueue(QuantityBase);  // Enqueue Quantity Base for ItemTrackingLinesPageHandler.

        // Enqueue value for ItemTrackingSummaryPageHandler.
        LibraryVariableStorage.Enqueue(SummaryOption::ReSelectEntries);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity - QuantityBase);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(QuantityBase);

        // Exercise: Open Item Tracking Lines Page.
        SalesLine.OpenItemTrackingLines();

        // Verify: Verify Enqueue Quantity values on Item Tracking Summary Page Handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure RecalculateQtyOnPartiallyAssignedITLinesPage()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        QuantityBase: Variant;
        QtyBase: Decimal;
        SummaryOption: Option SetQuantity,VerifyQuantity,VerifyExpirationDate,AssignQty,SelectEntries,ReSelectEntries;
    begin
        // Recalculate Quantity on Partially Assigned Item Tracking Lines Page.

        // Setup: Create and Post Purchase order,Create Sales Order Assign Lot.
        Initialize();
        CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, false, false));
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, Item."No.", TrackingOption::AssignLotNo2);
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, Item."No.", '', (PurchaseLine.Quantity - LibraryRandom.RandInt(10)));  // Take Random Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignQty);  // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
        LibraryVariableStorage.Dequeue(QuantityBase);
        QtyBase := QuantityBase;
        EnqueueQuantityForReselectEntries(
          TrackingOption::ReSelectEntries, SummaryOption::SelectEntries, SummaryOption::ReSelectEntries,
          PurchaseLine.Quantity - SalesLine.Quantity, QtyBase, SalesLine.Quantity - QtyBase);
        // Enqueue value for ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler.

        // Exercise: Open Item Tracking Lines Page.
        SalesLine.OpenItemTrackingLines();

        // Verify: Verify Enqueue Quantity values on Item Tracking Summary Page Handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AssignItemTrackingNoToSupplyOrderWithDemand()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // Assign Item Tracking Number to Purchase Order With Demand.

        // Setup: Create Sales order and Assign Serial Number, Create Purchase Order and Assign Serial No.
        Initialize();
        CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(false, true, false));
        LibraryWarehouse.CreateLocation(Location);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, Item."No.", Location.Code, LibraryRandom.RandInt(10));  // Take random for Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarning);  // Enqueue value for ConfirmHandler.
        SalesLine.OpenItemTrackingLines();
        CreatePurchaseOrder(PurchaseLine, Item."No.", LibraryRandom.RandInt(10));  // Take Random Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarning);  // Enqueue value for ConfirmHandler.
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");

        // Exercise: Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify Purchase Receipt.
        VerifyPurchRcpt(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure AssignItemTrackingNoToSupplyOrderWithoutDemand()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        // Assign Item Tracking Number to Purchase Order without Demand.

        // Setup: Create Purchase order.
        Initialize();
        CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(false, true, false));
        CreatePurchaseOrder(PurchaseLine, Item."No.", LibraryRandom.RandIntInRange(10, 20));  // Take Random Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo2);  // Enqueue value for ItemTrackingLinesPageHandler.

        // Exercise: Open Item Tracking Lines Page.
        PurchaseLine.OpenItemTrackingLines();

        // Verify: Item Tracking Page run without Availability Warning Error.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure AssignSerialNoToSalesRetOrd()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Generated Assign Serial No on on Item Tracking Lines Page for Sales Return Order.

        // Setup: Create Sales Return Order, assign Serial No with Item Tracking.
        Initialize();
        CreateSalesRetOrdWithIT(SalesLine);

        // Exercise: Assign Serial Numbers to Item tracking Lines.
        SalesLine.OpenItemTrackingLines();

        // Verify: Verify Serial No Lines generated on the ItemTrackingLinesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure DeleteSalesCrMemoLnWithITLnError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Error while deleting Sales Credit Memo Line with Item tracking lines generated with Get Return Receipt Lines.

        // Setup: Create Sales Return Order, assign Serial No with Item Tracking, create Credit Memo with Get Return Receipt Lines.
        Initialize();
        CreateSalesRetOrdWithIT(SalesLine);
        SalesLine.OpenItemTrackingLines();
        PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.", false);
        CreateSalesCreditMemo(SalesHeader, SalesLine."No.", SalesLine."Sell-to Customer No.");
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");

        // Exercise: Delete Credit Memo Line.
        asserterror SalesLine.DeleteAll(true);

        // Verify: Verify Error on deleting Sales Credit Memo Line.
        Assert.ExpectedError(StrSubstNo(ExistingSalesLnITError, SalesLine."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateHandlerForSetQuantityAssignLot')]
    [Scope('OnPrem')]
    procedure NoSNWhseTrackingPurchOrder()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchQuantity: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Warehouse] [Purchase]
        // [SCENARIO] Check that warehouse entries contain empty Serial No, if warehouse tracking only enabled for Lot.

        // [GIVEN] Item with Lot Warehouse Tracking, Serial Purchase Inbound Tracking, but no Serial Warehouse Tracking.
        Initialize();
        CreateWhseLotSpecificTrackedItem(Item, true);
        PurchQuantity := LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Create Purchase Order, Location with receive/ship required.
        CreatePurchOrderWithLocation(PurchaseLine, CreateLocationWithReceiveShipRequired(), Item."No.", PurchQuantity);

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt from Purchase order, assign Serial and Lot Nos.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseReceiptLine.FindFirst();
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);
        // Enqueue for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(PurchQuantity);
        // Enqueue for EnterQuantityToCreateHandlerForSetQuantityAssignLot.
        WarehouseReceiptLine.OpenItemTrackingLines();

        // [WHEN] Post Warehouse Receipt.
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // [THEN] Warehouse Entries have empty "Serial No."
        VerifyWarehouseEntriesSN(Item."No.", '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostItemReclassJournalWithInboundLotInfo()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        LotNo: Code[50];
        NewLotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Lot No. Info]
        // [SCENARIO 380704] It should not be allowed to post item reclassification journal with a lot that does not have lot information if inbound lot info must exists in tracking code.
        Initialize();

        // [GIVEN] Assign item tracking code that must have inbound lot info to item "I".
        CreateItemInboundLotInfoMustExist(Item);

        // [GIVEN] Stock inventory with lot no. = "L1".
        LotNo := CreateItemWarehouseInventoryWithLotInfo(ItemJournalLine, Item."No.");

        // [GIVEN] Create item reclassification journal line. Set New "Lot No." = "L2". Lot "L2" does not have lot information.
        NewLotNo := LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID();
        CreateItemReclassificationJournalLineWithTrackingAttribute(
          ItemJournalLine, ItemJournalLine."Item No.", ItemJournalLine."Location Code",
          ItemJournalLine.Quantity, TrackingOption::SetNewLotNo, LotNo, NewLotNo);

        // [WHEN] Post Item Reclassification Journal
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error 'The Lot No. Information does not exist.' occurs.
        Assert.ExpectedErrorCannotFind(Database::"Lot No. Information");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostItemReclassJournalWithInboundSNInfo()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SN: Code[20];
        NewSN: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Serial No. Info]
        // [SCENARIO 380704] It should not be allowed to post item reclassification journal with a serial no. that does not have serial no. information if inbound serial no. info must exists in tracking code.
        Initialize();

        // [GIVEN] Assign item tracking code that must have inbound serial no. info to item "I".
        CreateItemInboundSNInfoMustExist(Item);

        // [GIVEN] Stock inventory with serial no. = "S1".
        SN := CreateItemWarehouseInventoryWithSNInfo(ItemJournalLine, Item."No.");

        // [GIVEN] Create item reclassification journal line. Set New "Serial No." = "S2". Serial No. "S2" does not have serial no. information.
        NewSN := LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID();
        CreateItemReclassificationJournalLineWithTrackingAttribute(
          ItemJournalLine, ItemJournalLine."Item No.", ItemJournalLine."Location Code",
          ItemJournalLine.Quantity, TrackingOption::SetNewSN, SN, NewSN);

        // [WHEN] Post Item Reclassification Journal
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Error 'The Serial No. Information does not exist.' occurs.
        Assert.ExpectedErrorCannotFind(Database::"Serial No. Information");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostItemJournalWithInbLotInfoAndCreateInfoCard()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        LotNo: Code[50];
        LotNoInformation: Record "Lot No. Information";
    begin

        // [FEATURE] [Item Tracking] [Lot No. Info]
        // [SCENARIO 319084] Posting of Item Journal Line with tracking code having Create Information Lot Card enabled
        Initialize();

        // [GIVEN] Assign item tracking code that must have inbound Lot no. info and auto create Lot info card to item "I"
        CreateItemInboundLotInfoMustExistAutoInfoCard(Item);

        // [WHEN] Create item journal line with lot number = "L1" and Post Item Journal
        LotNo := LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Lot No."), DATABASE::"Item Journal Line");
        CreateItemWarehouseInventoryWithTrackingAttribute(ItemJournalLine, Item."No.", TrackingOption::EditValue, LotNo);

        // [THEN] Lot number information card must be created
        Assert.IsTrue(LotNoInformation.Get(Item."No.", '', LotNo), TheLotNoInfoDoesNotExistErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostItemJournalWithInbSNInfoAndCreateInfoCard()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SerialNoInformation: Record "Serial No. Information";
        SN: Code[20];
    begin
        // [FEATURE] [Item Tracking] [Serial No. Info]
        // [SCENARIO 319084] Posting of Item Journal Line with tracking code having Create Information SN Card enabled
        Initialize();

        // [GIVEN] Assign item tracking code that must have inbound serial no. info and auto create SN info card to item "I"
        CreateItemInboundSNInfoMustExistAutoInfoCard(Item);

        // [WHEN] Create item journal line with serial number = "S1" and Post Item Journal
        SN := LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Serial No."), DATABASE::"Item Journal Line");
        CreateItemWithTrackingAttrNoPosting(ItemJournalLine, Item."No.", TrackingOption::EditSNValue, SN, 1);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Serial number information card must be created
        Assert.IsTrue(SerialNoInformation.Get(Item."No.", '', SN), TheSerialNoInfoDoesNotExistErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure CreateItemJournalWithInbSNInfoAndAssignSNWithInfoCard()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking] [Serial No. Info]
        // [SCENARIO 319084] Creating information card from assign serial no. action on item tracking page
        Initialize();

        // [GIVEN] Assign item tracking code that must have inbound serial no. info and without creating SN info card to item "I"
        CreateItemInboundSNInfoMustExist(Item);

        // [WHEN] Create item journal line with serial number = "S1", create SN info from assign serial no. action
        CreateSNInfo := true;
        CreateItemWithTrackingAttrNoPosting(ItemJournalLine, Item."No.", TrackingOption::AssignSerialNo, '', 5);

        // [THEN] Serial number information card must be created
        AssertSNInfoExists(ItemJournalLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,CustomizedSerialPageHandler')]
    [Scope('OnPrem')]
    procedure CreateItemJournalWithInbSNInfoAndCustomizedSNWithInfoCard()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking] [Serial No. Info]
        // [SCENARIO 319084] Creating information card from Create Customized SN action on item tracking page
        Initialize();

        // [GIVEN] Assign item tracking code that must have inbound serial no. info and without creating SN info card to item "I"
        CreateItemInboundSNInfoMustExist(Item);

        // [WHEN] Create item journal line with serial number = "S1", create SN info from create customized serial no. action
        CreateSNInfo := true;
        CreateItemWithTrackingAttrNoPosting(ItemJournalLine, Item."No.", TrackingOption::CreateCustomizedSN, '', 5);

        // [THEN] Serial number information card must be created
        AssertSNInfoExists(ItemJournalLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateInventoryPutAwayLotSerialPurchase()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SNo: Code[20];
        LNo: Code[20];
    begin
        // [FEATURE] [Inventory Put-Away] [Purchase]
        // [SCENARIO 213968] No error occurs when input new unregistred yet in the system values of "Lot No." and "Serial No." in "Warehouse Activity Line" for Purchase Order for item with Item Tracking Code which requires Lot and Serial tracking
        Initialize();

        // [GIVEN] Inventory Put-Away Line "WAL" for item with Item Tracking Code which requires Lot and Serial tracking, also for Warehouse
        CreateInvtPutawayWithLotSNTrackingItemPurchase(WarehouseActivityLine);

        LNo := LibraryUtility.GenerateGUID();
        SNo := LibraryUtility.GenerateGUID();

        // [WHEN] Update "Lot No." and "Serial No." by values "LN" and "SN" in "WAL"
        UpdateLotSerialNoInWarehouseActivityLine(WarehouseActivityLine, LNo, SNo);

        // [THEN] No error occurs, "WAL"."Lot No." = "LN", "WAL"."Serial No." = "SN"
        WarehouseActivityLine.TestField("Lot No.", LNo);
        WarehouseActivityLine.TestField("Serial No.", SNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateInventoryPutAwayLotSerialProduction()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SNo: Code[20];
        LNo: Code[20];
    begin
        // [FEATURE] [Inventory Put-Away] [Production]
        // [SCENARIO 213968] No error occurs when input new unregistred yet in the system values of "Lot No." and "Serial No." in "Warehouse Activity Line" for Production Order for item with Item Tracking Code which requires Lot and Serial tracking
        Initialize();

        // [GIVEN] Inventory Put-Away Line "WAL" for item with Item Tracking Code which requires Lot and Serial tracking, also for Warehouse
        CreateInvtPutawayWithLotSNTrackingItemProduction(WarehouseActivityLine);

        LNo := LibraryUtility.GenerateGUID();
        SNo := LibraryUtility.GenerateGUID();

        // [WHEN] Update "Lot No." and "Serial No." by values "LN" and "SN" in "WAL"
        UpdateLotSerialNoInWarehouseActivityLine(WarehouseActivityLine, LNo, SNo);

        // [THEN] No error occurs, "WAL"."Lot No." = "LN", "WAL"."Serial No." = "SN"
        WarehouseActivityLine.TestField("Lot No.", LNo);
        WarehouseActivityLine.TestField("Serial No.", SNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateInventoryPickLotSerialSales()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Inventory Pick]
        // [SCENARIO 213968] Error occurs when try to update "Serial No." by value which hasn't corresponding Lot in "Warehouse Activity Line" for Sales Order for item with Item Tracking Code which requires Lot and Serial tracking
        Initialize();

        // [GIVEN] Inventory Pick Line "WAL" for item with Item Tracking Code which requires Lot and Serial tracking, also for Warehouse
        CreateInvtPickWithLotSNTrackingItem(WarehouseActivityLine);

        // [WHEN] Try to update "Lot No." and "Serial No." in "WAL" by new values unregistred in the system
        asserterror
          UpdateLotSerialNoInWarehouseActivityLine(WarehouseActivityLine, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [THEN] The error 'There is no Entry Summary within the filter' occurs
        Assert.ExpectedError(LotNoBySNNotFoundErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesExpiredLotPageHandler')]
    [Scope('OnPrem')]
    procedure UI_DateFilterUntilWorkDateDefinedByDefaultOnLotNoInformationListPage()
    var
        Item: Record Item;
        LotNoInformationList: TestPage "Lot No. Information List";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Lot No. Info] [UI]
        // [SCENARIO 338232] The "Date Filter" defines until work date by default when "Lot No. Information List" page opens

        Initialize();

        // [GIVEN] Item with "Lot No." tracking
        CreateItemInboundLotInfoMustExist(Item);
        LotNo := CreateLotNoInformation(Item."No.");

        // [GIVEN] Positive adjustment of Item with Lot Tracking. Work Date = 05.01.2017
        PostItemJournalWithTracking(Item."No.", LotNo, LibraryRandom.RandInt(10));

        // [WHEN] Open "Lot No. Information List" page for Item with "Lot No." tracking
        LotNoInformationList.OpenEdit();
        LotNoInformationList.GotoKey(Item."No.", '', LotNo);

        // [THEN] "Date Filter" is "01.01.0000..05.01.2017"
        Assert.AreEqual(
          LotNoInformationList.FILTER.GetFilter("Date Filter"),
          StrSubstNo('>%1&<=%2', '''''', WorkDate()), 'Incorrect Date Filter');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesExpiredSerialNoPageHandler')]
    [Scope('OnPrem')]
    procedure UI_DateFilterUntilWorkDateDefinedByDefaultOnSerialNoInformationListPage()
    var
        Item: Record Item;
        SerialNoInformationList: TestPage "Serial No. Information List";
        SerialNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Lot No. Info] [UI]
        // [SCENARIO 338232] The "Date Filter" defines until work date by default when "Serial No. Information List" page opens

        Initialize();

        // [GIVEN] Item with "Serial No. No." tracking
        CreateItemInboundSNInfoMustExist(Item);
        SerialNo := CreateSNInformation(Item."No.");

        // [GIVEN] Positive adjustment of Item with Serial No. Tracking. Work Date = 05.01.2017
        PostItemJournalWithTracking(Item."No.", SerialNo, 1);

        // [WHEN] Open "Serial No. Information List" page for Item with "Serial No." tracking
        SerialNoInformationList.OpenEdit();
        SerialNoInformationList.GotoKey(Item."No.", '', SerialNo);

        // [THEN] "Date Filter" is "01.01.0000..05.01.2017"
        Assert.AreEqual(
          SerialNoInformationList.FILTER.GetFilter("Date Filter"),
          StrSubstNo('>%1&<=%2', '''''', WorkDate()), 'Incorrect Date Filter');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesExpiredLotPageHandler')]
    [Scope('OnPrem')]
    procedure UI_DateFilterUntilWorkDateDefinedByDefaultOnLotNoInformationCardPage()
    var
        Item: Record Item;
        LotNoInformationCard: TestPage "Lot No. Information Card";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Lot No. Info] [UI]
        // [SCENARIO 338232] The "Date Filter" defines until work date by default when "Lot No. Information Card" page opens

        Initialize();

        // [GIVEN] Item with "Lot No." tracking
        CreateItemInboundLotInfoMustExist(Item);
        LotNo := CreateLotNoInformation(Item."No.");

        // [GIVEN] Positive adjustment of Item with Lot Tracking. Work Date = 05.01.2017
        PostItemJournalWithTracking(Item."No.", LotNo, LibraryRandom.RandInt(10));

        // [WHEN] Open "Lot No. Information Card" page for Item with "Lot No." tracking
        LotNoInformationCard.OpenEdit();
        LotNoInformationCard.GotoKey(Item."No.", '', LotNo);

        // [THEN] "Date Filter" is "01.01.0000..05.01.2017"
        Assert.AreEqual(
          LotNoInformationCard.FILTER.GetFilter("Date Filter"),
          StrSubstNo('>%1&<=%2', '''''', WorkDate()), 'Incorrect Date Filter');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesExpiredSerialNoPageHandler')]
    [Scope('OnPrem')]
    procedure UI_DateFilterUntilWorkDateDefinedByDefaultOnSerialNoInformationCardPage()
    var
        Item: Record Item;
        SerialNoInformationCard: TestPage "Serial No. Information Card";
        SerialNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Lot No. Info] [UI]
        // [SCENARIO 338232] The "Date Filter" defines until work date by default when "Serial No. Information Card" page opens

        Initialize();

        // [GIVEN] Item with "Serial No. No." tracking
        CreateItemInboundSNInfoMustExist(Item);
        SerialNo := CreateSNInformation(Item."No.");

        // [GIVEN] Positive adjustment of Item with Serial No. Tracking. Work Date = 05.01.2017
        PostItemJournalWithTracking(Item."No.", SerialNo, 1);

        // [WHEN] Open "Serial No. Information Card" page for Item with "Serial No." tracking
        SerialNoInformationCard.OpenEdit();
        SerialNoInformationCard.GotoKey(Item."No.", '', SerialNo);

        // [THEN] "Date Filter" is "01.01.0000..05.01.2017"
        Assert.AreEqual(
          SerialNoInformationCard.FILTER.GetFilter("Date Filter"),
          StrSubstNo('>%1&<=%2', '''''', WorkDate()), 'Incorrect Date Filter');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FinalizingPostingPartiallyPutAwayForOutputWithItemTracking()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WhseActivHeader: Record "Warehouse Activity Header";
        Qty: Decimal;
    begin
        // [FEATURE] [Production Order] [Output] [Inventory Put-away]
        // [SCENARIO 333316] Posting inventory put-away for production output that has been already partially put-away with another lot.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Location "L" with enabled put-away.
        // [GIVEN] Lot-tracked item "I".
        Location.Get(CreatePutawayPickLocation());
        CreateWhseLotSpecificTrackedItem(Item, true);

        // [GIVEN] Released production order for item "I" on location "L". Quantity = 100.
        CreateAndRefreshProductionOrderOnLocation(ProductionOrder, Location.Code, Item."No.", Qty);
        FindProdOrderLine(ProdOrderLine, ProductionOrder);

        // [GIVEN] Create inventory put-away, assign lot no. = "L1", quantity = 50 and post.
        CreateInvtPutAwayForProdOrder(WhseActivHeader, ProdOrderLine, Qty / 2);
        LibraryWarehouse.PostInventoryActivity(WhseActivHeader, true);

        // [GIVEN] Delete the partially posted inventory put-away.
        WhseActivHeader.Delete(true);

        // [GIVEN] Create another inventory put-away, assign lot no. = "L2", quantity = 50.
        CreateInvtPutAwayForProdOrder(WhseActivHeader, ProdOrderLine, Qty / 2);

        // [WHEN] Post the second put-away.
        LibraryWarehouse.PostInventoryActivity(WhseActivHeader, true);

        // [THEN] The production output is fully posted.
        ProdOrderLine.Find();
        ProdOrderLine.TestField("Finished Quantity", Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayExpirationCalculationNotBlank()
    var
        Location: Record Location;
        Item: Record Item;
        Bin: Record Bin;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        WhseActivHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        WarehouseEntry: Record "Warehouse Entry";
        ExpDate: Date;
    begin
        // [FEATURE] [Purchase] [Inventory Put-away]
        // [SCENARIO 336704] Expiration date is not blank in Warehouse Entry / Posted Inventory Put-away
        // [SCENARIO 336704] on first Item expiration calculation when posting Inventory put-away for Purchase
        Initialize();

        // [GIVEN] Location "L" with enabled put-away.
        // [GIVEN] Lot-tracked item "I" with "Expiration calculation" = "2Y"
        Location.Get(CreatePutawayPickLocation());
        CreateWhseLotSpecificTrackedItem(Item, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Released purchase order from 01-01-2022 for item "I" on location "L"
        // [GIVEN] Assign new lot number for tracking of item "I"
        CreatePurchaseOrder(PurchaseLine, Item."No.", 1);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        ExpDate := CalcDate(Item."Expiration Calculation", WorkDate());

        // [GIVEN] Create inventory put-away for purchase order with autofilled quantity to handle
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          PurchaseLine."Location Code", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
        WhseActivHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // [WHEN] Post Inventory Put-Away for receipt
        LibraryWarehouse.PostInventoryActivity(WhseActivHeader, false);

        // [THEN] Posted Invt. Put-Away line has expiration date = 01-01-2024
        PostedInvtPutAwayLine.SetRange("Item No.", Item."No.");
        PostedInvtPutAwayLine.FindFirst();
        PostedInvtPutAwayLine.TestField("Expiration Date", ExpDate);

        // [THEN] Warehouse entry for the receipt has expiration date = 01-01-2024
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Expiration Date", ExpDate);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerValidateMessage')]
    procedure CheckItemTrackingAvailabilityBeforePostingInvtPick()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SerialNo: Code[50];
    begin
        // [FEATURE] [Availability] [Inventory Pick] [Item Tracking]
        // [SCENARIO 438731] Check item tracking availability before posting inventory pick.
        Initialize();
        SerialNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with required pick.
        Location.Get(CreatePutawayPickLocation());
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();

        // [GIVEN] Serial No.-tracked item.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);

        // [GIVEN] Post serial no. "S1" to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin.Code, 1);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, SerialNo, '', 1);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order, release, create inventory pick.
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, Item."No.", Location.Code, 1);
        CreateInventoryPickOnSalesLine(SalesLine);

        // [GIVEN] Go to the pick line, set "Serial No." = "S2", which is not available in stock.
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesLine."Document No.", WarehouseActivityLine."Activity Type"::"Invt. Pick", SalesLine."Location Code",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Validate("Serial No.", LibraryUtility.GenerateGUID());
        WarehouseActivityLine.Modify(true);

        // [WHEN] Try to post the inventory pick.
        Commit();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        asserterror LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Error "Serial No. S2 is not available..." shows up.
        Assert.ExpectedError(
          StrSubstNo(InventoryNotAvailableErr, WarehouseActivityLine.FieldCaption("Serial No."), WarehouseActivityLine."Serial No."));

        // [THEN] After you correct the serial no. to "S1", the inventory pick can be posted.
        WarehouseActivityLine.Find();
        WarehouseActivityLine.Validate("Serial No.", SerialNo);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Find();
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure CannotCreateItemTrackingFromItemJnlLineForNonTrackedItem()
    var
        NotTrackedItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Cannot create item tracking from item journal line for non-tracked item.
        Initialize();

        LibraryInventory.CreateItem(NotTrackedItem);

        CreateItemJournalLineItemTrackingEnabled(ItemJournalLine, NotTrackedItem."No.", LibraryRandom.RandInt(10));
        ItemJournalLine."Lot No." := LibraryUtility.GenerateGUID();
        ItemJournalLine.Modify();

        ItemJnlLineReserve.CreateItemTracking(ItemJournalLine);

        Assert.IsFalse(ItemJnlLineReserve.ReservEntryExist(ItemJournalLine), '');
    end;

    [Test]
    procedure CannotCreateItemTrackingFromItemJnlLineIfTrackingExists()
    var
        LotTrackedItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Cannot create item tracking from item journal line if tracking already exists.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();

        LibraryItemTracking.CreateLotItem(LotTrackedItem);

        CreateItemJournalLineItemTrackingEnabled(ItemJournalLine, LotTrackedItem."No.", LibraryRandom.RandInt(10));
        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);

        ItemJournalLine."Lot No." := LibraryUtility.GenerateGUID();
        ItemJournalLine.Modify();

        ItemJnlLineReserve.CreateItemTracking(ItemJournalLine);

        ReservationEntry.Reset();
        ItemJournalLine.SetReservationFilters(ReservationEntry);
        ReservationEntry.ClearTrackingFilter();
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Lot No.", LotNo);
        Assert.RecordCount(ReservationEntry, 1);
    end;

    [Test]
    procedure CreateItemTrackingLinesFromItemJournalLine()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        LotTrackedItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Create item tracking from item journal line.
        Initialize();

        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(LotTrackedItem, '', '', ItemTrackingCode.Code);

        CreateItemJournalLineItemTrackingEnabled(ItemJournalLine, LotTrackedItem."No.", LibraryRandom.RandInt(10));
        ItemJournalLine."Lot No." := LibraryUtility.GenerateGUID();
        ItemJournalLine."Expiration Date" := LibraryRandom.RandDate(30);
        ItemJournalLine.Modify();

        ItemJnlLineReserve.CreateItemTracking(ItemJournalLine);

        ItemJnlLineReserve.FindReservEntry(ItemJournalLine, ReservationEntry);
        ReservationEntry.TestField("Lot No.", ItemJournalLine."Lot No.");
        ReservationEntry.TestField("Expiration Date", ItemJournalLine."Expiration Date");
    end;

    [Test]
    procedure CannotCreateIncorrectItemTrackingLinesFromItemJnl()
    var
        SerialTrackedItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Cannot create item tracking from item journal line for serial number with abs(Quantity) > 1.
        Initialize();

        LibraryItemTracking.CreateSerialItem(SerialTrackedItem);

        CreateItemJournalLineItemTrackingEnabled(ItemJournalLine, SerialTrackedItem."No.", LibraryRandom.RandIntInRange(2, 10));
        ItemJournalLine."Serial No." := LibraryUtility.GenerateGUID();
        ItemJournalLine.Modify();

        asserterror ItemJnlLineReserve.CreateItemTracking(ItemJournalLine);

        Assert.ExpectedError('-1');
    end;

    [Test]
    procedure PostItemJnlWithItemTrackingDefinedOnlyOnLine()
    var
        Item: array[3] of Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        SerialNo: array[3] of Code[50];
        LotNo: array[3] of Code[50];
        i: Integer;
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Post item journal with item tracking defined on the line but not in Item Tracking Lines page.
        Initialize();

        LibraryItemTracking.CreateLotItem(Item[1]);
        LibraryItemTracking.CreateSerialItem(Item[2]);
        LibraryInventory.CreateItem(Item[3]);

        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();
        for i := 1 to ArrayLen(Item) do begin
            SerialNo[i] := LibraryUtility.GenerateGUID();
            LotNo[i] := LibraryUtility.GenerateGUID();
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::"Positive Adjmt.", Item[i]."No.", 1);
            ItemJournalLine."Serial No." := SerialNo[i];
            ItemJournalLine."Lot No." := LotNo[i];
            ItemJournalLine.Modify();
        end;

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        VerifyTrackingOnItemLedgerEntry(Item[1]."No.", SerialNo[1], LotNo[1]);
        VerifyTrackingOnItemLedgerEntry(Item[2]."No.", SerialNo[2], LotNo[2]);
        VerifyTrackingOnItemLedgerEntry(Item[3]."No.", '', '');
    end;

    [Test]
    procedure PostItemJnlWithItemTrackingDefinedOnLineAndOnITLPage()
    var
        SerialTrackedItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Post item journal with item tracking defined on the line and in Item Tracking Lines page.
        Initialize();

        LibraryItemTracking.CreateSerialItem(SerialTrackedItem);

        CreateItemJournalLineItemTrackingEnabled(ItemJournalLine, SerialTrackedItem."No.", 1);
        ItemJournalLine."Serial No." := LibraryUtility.GenerateGUID();
        ItemJournalLine.Modify();

        LibraryItemTracking.CreateItemJournalLineItemTracking(
          ReservationEntry, ItemJournalLine, LibraryUtility.GenerateGUID(), '', ItemJournalLine.Quantity);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        VerifyTrackingOnItemLedgerEntry(SerialTrackedItem."No.", ReservationEntry."Serial No.", '');
    end;

    [Test]
    procedure CannotPostItemJnlWithTrackingOnLineIfTrackingDisabledOnBatch()
    var
        SerialTrackedItem: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Cannot post item journal with item tracking defined on the line if item tracking is disabled on the batch.
        Initialize();

        LibraryItemTracking.CreateSerialItem(SerialTrackedItem);

        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        ItemJournalBatch."Item Tracking on Lines" := false;
        ItemJournalBatch.Modify();

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", SerialTrackedItem."No.", 1);
        ItemJournalLine."Serial No." := LibraryUtility.GenerateGUID();
        ItemJournalLine.Modify();

        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        Assert.ExpectedError('You must assign a serial number');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingSummaryModalPageHandler')]
    procedure SelectItemTrackingOnItemJnlLineUsingAssistEdit()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        SerialTrackedItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SerialNo: Code[50];
        ExpirationDate: Date;
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Select item tracking on item journal line using Assist Edit.
        Initialize();
        SerialNo := LibraryUtility.GenerateGUID();
        ExpirationDate := LibraryRandom.RandDate(60);

        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(ItemTrackingCode, true, false);
        LibraryInventory.CreateTrackedItem(SerialTrackedItem, '', '', ItemTrackingCode.Code);

        CreateItemJournalLineItemTrackingEnabled(ItemJournalLine, SerialTrackedItem."No.", 1);
        ItemJournalLine."Serial No." := SerialNo;
        ItemJournalLine."Expiration Date" := ExpirationDate;
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        CreateItemJournalLineItemTrackingEnabled(ItemJournalLine, SerialTrackedItem."No.", -1);

        ItemJournalLine.LookUpTrackingSummary("Item Tracking Type"::"Serial No.");

        ItemJournalLine.TestField("Serial No.", SerialNo);
        ItemJournalLine.TestField("Expiration Date", ExpirationDate);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler')]
    procedure SyncItemTrackingOnItemJnlLineWithITLPage()
    var
        LotTrackedItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournal: TestPage "Item Journal";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Synchronize item tracking on item journal line with Item Tracking Lines page.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();

        LibraryItemTracking.CreateLotItem(LotTrackedItem);

        CreateItemJournalLineItemTrackingEnabled(ItemJournalLine, LotTrackedItem."No.", LibraryRandom.RandInt(10));
        ItemJournalLine."Lot No." := LotNo;
        ItemJournalLine.Modify();

        LibraryVariableStorage.Enqueue(LotNo);
        ItemJournal.OpenEdit();
        ItemJournal.GoToRecord(ItemJournalLine);
        ItemJournal.ItemTrackingLines.Invoke();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure UpdateItemTrackingOnItemJnlLineFromITLPage()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        LotTrackedItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournal: TestPage "Item Journal";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Update item tracking on item journal line after you define tracking on Item Tracking Lines page.
        Initialize();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(LotTrackedItem, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        CreateItemJournalLineItemTrackingEnabled(ItemJournalLine, LotTrackedItem."No.", LibraryRandom.RandInt(10));

        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
        ItemJournal.OpenEdit();
        ItemJournal.GoToRecord(ItemJournalLine);
        ItemJournal.ItemTrackingLines.Invoke();

        ItemJournalLine.Find();
        ItemJournalLine.TestField("Lot No.", LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure UseUpdateItemTrackingLinesFunctionInItemJnl()
    var
        Item: array[3] of Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        ItemJournal: TestPage "Item Journal";
        SerialNo: array[3] of Code[50];
        LotNo: array[3] of Code[50];
        i: Integer;
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Use Update Item Tracking Lines function to automatically fill in Item Tracking Lines from item journal line.
        Initialize();

        LibraryItemTracking.CreateLotItem(Item[1]);
        LibraryItemTracking.CreateSerialItem(Item[2]);
        LibraryInventory.CreateItem(Item[3]);

        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();
        for i := 1 to ArrayLen(Item) do begin
            SerialNo[i] := LibraryUtility.GenerateGUID();
            LotNo[i] := LibraryUtility.GenerateGUID();
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::"Positive Adjmt.", Item[i]."No.", 1);
            ItemJournalLine."Serial No." := SerialNo[i];
            ItemJournalLine."Lot No." := LotNo[i];
            ItemJournalLine.Modify();
        end;

        ItemJournal.OpenEdit();
        ItemJournal."Update Item Tracking Lines".Invoke();

        FindItemJournalLine(ItemJournalLine, Item[1]."No.");
        Assert.IsTrue(ItemJnlLineReserve.FindReservEntry(ItemJournalLine, ReservationEntry), '');

        FindItemJournalLine(ItemJournalLine, Item[2]."No.");
        Assert.IsTrue(ItemJnlLineReserve.FindReservEntry(ItemJournalLine, ReservationEntry), '');

        FindItemJournalLine(ItemJournalLine, Item[3]."No.");
        Assert.IsFalse(ItemJnlLineReserve.FindReservEntry(ItemJournalLine, ReservationEntry), '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure ResetItemTrackingOnItemJnlLineForMultipleLots()
    var
        LotTrackedItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournal: TestPage "Item Journal";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Reset item tracking on item journal line if Item Tracking Lines page contains more than one line.
        Initialize();

        LibraryItemTracking.CreateLotItem(LotTrackedItem);

        CreateItemJournalLineItemTrackingEnabled(ItemJournalLine, LotTrackedItem."No.", LibraryRandom.RandIntInRange(10, 20));
        ItemJournalLine."Lot No." := LibraryUtility.GenerateGUID();
        ItemJournalLine.Modify();

        LibraryVariableStorage.Enqueue(TrackingOption::AssignTwoLotNos);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(ItemJournalLine."Quantity (Base)" / 2);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(ItemJournalLine."Quantity (Base)" / 2);

        ItemJournal.OpenEdit();
        ItemJournal.GoToRecord(ItemJournalLine);
        ItemJournal.ItemTrackingLines.Invoke();

        ItemJournalLine.Find();
        ItemJournalLine.TestField("Lot No.", '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure UpdateItemTrackingOnItemJnlLineFromITLPageEditedTwice()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        LotTrackedItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournal: TestPage "Item Journal";
        LotNo: Code[50];
        i: Integer;
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 348246] Update item tracking on item journal line after you define tracking in two iterations on Item Tracking Lines page.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(LotTrackedItem, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        CreateItemJournalLineItemTrackingEnabled(ItemJournalLine, LotTrackedItem."No.", 2 * LibraryRandom.RandInt(10));

        ItemJournal.OpenEdit();
        for i := 1 to 2 do begin
            LibraryVariableStorage.Enqueue(TrackingOption::SetLotAndSerial);
            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue('');
            LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity / 2);
            ItemJournal.GoToRecord(ItemJournalLine);
            ItemJournal.ItemTrackingLines.Invoke();
        end;
        ItemJournal.Close();

        ItemJournalLine.Find();
        ItemJournalLine.TestField("Lot No.", LotNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler')]
    procedure OpeningItemTrackingLinesForItemJnlLineUpdatesTracking()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        LotTrackedItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournal: TestPage "Item Journal";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 462571] Update item tracking for item journal line on opening Item Tracking Lines page.
        Initialize();

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(LotTrackedItem, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        CreateItemJournalLine(ItemJournalLine, LotTrackedItem."No.", '', '', LibraryRandom.RandInt(10));
        ItemJournalLine."Lot No." := LibraryUtility.GenerateGUID();
        ItemJournalLine.Modify();

        LibraryVariableStorage.Enqueue(ItemJournalLine."Lot No.");
        ItemJournal.OpenEdit();
        ItemJournal.GoToRecord(ItemJournalLine);
        ItemJournal.ItemTrackingLines.Invoke();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler')]
    procedure ResetItemTrackingOnItemJnlLineForEmptyLot()
    var
        LotTrackedItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournal: TestPage "Item Journal";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 464291] Reset item tracking on item journal line if Item Tracking Lines page contains no lines.
        Initialize();

        LibraryItemTracking.CreateLotItem(LotTrackedItem);

        CreateItemJournalLineItemTrackingEnabled(ItemJournalLine, LotTrackedItem."No.", LibraryRandom.RandIntInRange(10, 20));
        ItemJournalLine."Lot No." := LibraryUtility.GenerateGUID();
        ItemJournalLine.Modify();

        LibraryVariableStorage.Enqueue(TrackingOption::SetLotAndSerial);
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(CloseItemTrackingLinesWithQtyZeroConfirmErr);

        ItemJournal.OpenEdit();
        ItemJournal.GoToRecord(ItemJournalLine);
        IsUsingSimpleYesConfirmHandler := true;
        ItemJournal.ItemTrackingLines.Invoke();

        ItemJournalLine.Find();
        ItemJournalLine.TestField("Lot No.", '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PostedSalesDocumentLinesPageHandler')]
    procedure VerifyRegisterPickWithMandatorySerialNoAndNonEssentialLotNo()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        LotNo, SerialNo : Code[50];
        Quantity: Decimal;
    begin
        // [SCENARIO 469609] Verify that you can register a pick for an item that has mandatory serial number and non-essential lot number 
        Initialize();

        Quantity := 1;

        // [GIVEN] Create SN specific Item Tracking Code
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);

        // [GIVEN] Create Item with SN specific Item Tracking Code        
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);

        // [GIVEN] Generate Lot No and Serial No
        LotNo := LibraryUtility.GenerateGUID();
        SerialNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Create Full Warehouse Location
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Purchase Order with Item and assign SN and Lot No.
        CreatePurchaseOrderWithLocationAndTrackingData(PurchaseLine, Item."No.", Location.Code, LotNo, SerialNo, Quantity);

        // [GIVEN] Create and Post Warehouse Receipt and Put-away
        CreateAndPostWarehouseReceiptFromPO(PurchaseLine);

        // [GIVEN] Create and Register Put-away
        CreateAndRegisterPutAwayFromPurchaseOrder(PurchaseLine."Document No.", Location.Code);

        // [GIVEN] Create Sales Order and Warehouse Shipment
        CreateSalesOrderAndWareshouseShipment(SalesHeader, Item."No.", Location.Code, Quantity);

        // [GIVEN] Create and Register Warehouse Pick
        CreateAndRegisterPickFromWareshouseShipment(SalesHeader."No.", LotNo, SerialNo, Quantity);

        // [GIVEN] Post Warehouse Shipment
        PostWarehouseShipmentFromSalesOrder(SalesHeader);

        // [GIVEN] Create Sales Return Order
        CreateSalesRetOrderGetPstdDocLineToRev(SalesHeader, Item."No.");

        // [GIVEN] Create and Post Warehouse Receipt and Put-away
        CreateAndPostWhseRcptFromSalesReturn(SalesHeader, Item."No.");

        // [WHEN] Create Sales Order and Warehouse Shipment
        CreateSalesOrderAndWareshouseShipment(SalesHeader, Item."No.", Location.Code, Quantity);

        // [THEN] Create and Register Warehouse Pick
        CreateAndRegisterPickFromWareshouseShipment(SalesHeader."No.", LotNo, SerialNo, Quantity);
    end;

    [HandlerFunctions('ItemTrackingSummaryModalPageHandler')]
    [Test]
    procedure LookupItemJournalLotNoWithItemTrackingDefinedOnlyOnLineAndDecimalQuantity()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Journal] [Item Tracking on Lines] [UI]
        // [SCENARIO 485524] Lookup "Lot No." on item journal line with item tracking defined on the line work with decimal Quantity.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with decimal Rounding Precision.
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Rounding Precision", 0.00001);
        Item.Modify(true);

        // [GIVEN] Item journal batch with "Item Tracking on Lines" = true.
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 0.01);

        // [WHEN] Lookup "Lot No." on item journal line.
        ItemJournalLine.LookUpTrackingSummary("Item Tracking Type"::"Lot No.");

        // [THEN] The "Lot No. Information List" page opens.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerTrue')]
    procedure ItemTrackingLines_AssignLotNoAndPackageNo()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking] [Item Journal]
        // [SCENARIO 459882] "Assign Lot No. on the empty tracking inserts new line and sets "Lot No.".
        // [SCENARIO 459882] "Assign Package No." on the line with "Lot No." sets "Package No.", without inserting new line.
        // [SCENARIO 459882] "Assign Lot No." on the line with "Lot No." inserts new line with new "Lot No." and copies "Package No." from that line.
        // [SCENARIO 459882] "Assign Lot No." on the new line inserts new line and sets "Lot No.".
        Initialize();

        // [GIVEN] Create Item Tracking Code with Lot and Package tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);

        // [GIVEN] Create Item with Lot and Package tracking
        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Create Item Journal Line and open tracking lines
        CreateItemJournalLine(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));  // Take random for Quantity and used blank for Location and Bin Code.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNoAndPackageNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] [THEN] Verified in ItemTrackingLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerTrue')]
    procedure ItemTrackingLines_AssignPackageNoAndLotNo()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking] [Item Journal]
        // [SCENARIO 459882] "Assign Package No. on the empty tracking inserts new line and sets "Package No.".
        // [SCENARIO 459882] "Assign Lot No." on the line with "Package No." sets "Lot No.", without inserting new line.
        // [SCENARIO 459882] "Assign Package No." on the line with "Package No." inserts new line with new "Package No." and copies "Lot No." from that line.
        // [SCENARIO 459882] "Assign Package No." on the new line inserts new line and sets "Package No.".
        Initialize();

        // [GIVEN] Create Item Tracking Code with Lot and Package tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);

        // [GIVEN] Create Item with Lot and Package tracking
        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Create Item Journal Line and open tracking lines
        CreateItemJournalLine(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));  // Take random for Quantity and used blank for Location and Bin Code.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignPackageNoAndLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] [THEN] Verified in ItemTrackingLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateHandlerForSetQuantityAssignLot')]
    procedure ItemTrackingLines_AssignSerialNoWithLot_ThenAssignPackage()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking] [Item Journal]
        // [SCENARIO 459882] "Assign Serial No." with creating Lot No. inserts new lines and with "Serial No." and "Lot No.".
        // [SCENARIO 459882] "Assign Package No." on the line with "Serial No." and "Lot No." sets "Package No.", without inserting new line.
        Initialize();

        // [GIVEN] Create Item Tracking Code with Serial, Lot and Package tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, true);

        // [GIVEN] Create Item with Serial, Lot and Package tracking
        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);

        // [GIVEN] Create Item Journal Line and open tracking lines
        CreateItemJournalLine(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));  // Take random for Quantity and used blank for Location and Bin Code.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNoWithLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity); // Enqueue for EnterQuantityToCreateHandlerForSetQuantityAssignLot.
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] [THEN] Verified in ItemTrackingLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateHandlerForSetQuantityAssignPackage')]
    procedure ItemTrackingLines_AssignSerialNoWithPackage_ThenAssignLot()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking] [Item Journal]
        // [SCENARIO 459882] "Assign Serial No." with creating Package No. inserts new lines and with "Serial No." and "Package No.".
        // [SCENARIO 459882] "Assign Lot No." on the line with "Serial No." and "Package No." sets "Lot No.", without inserting new line.
        Initialize();

        // [GIVEN] Create Item Tracking Code with Serial, Lot and Package tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, true);

        // [GIVEN] Create Item with Serial, Lot and Package tracking
        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);

        // [GIVEN] Create Item Journal Line and open tracking lines
        CreateItemJournalLine(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));  // Take random for Quantity and used blank for Location and Bin Code.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNoWithPackageNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity); // Enqueue for EnterQuantityToCreateHandlerForSetQuantityAssignPackage.
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] [THEN] Verified in ItemTrackingLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateHandlerForSetQuantityAssignLotAndPackage')]
    procedure ItemTrackingLines_AssignSerialNoWithLotAndPackage()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking] [Item Journal]
        // [SCENARIO 459882] "Assign Serial No." with creating Lot No. and Package No. inserts new lines and with "Serial No.", "Lot No." and "Package No.".
        Initialize();

        // [GIVEN] Create Item Tracking Code with Serial, Lot and Package tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, true);

        // [GIVEN] Create Item with Serial, Lot and Package tracking
        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);

        // [GIVEN] Create Item Journal Line and open tracking lines
        CreateItemJournalLine(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));  // Take random for Quantity and used blank for Location and Bin Code.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNoWithLotNoAndPackageNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity); // Enqueue for EnterQuantityToCreateHandlerForSetQuantityAssignLotAndPackage.
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] [THEN] Verified in ItemTrackingLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,CustomizedSerialPageHandlerAssignLot')]
    procedure ItemTrackingLines_CreateCustomizedSerialNoWithLot_ThenAssignPackage()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking] [Item Journal]
        // [SCENARIO 459882] "Create Customized SN" with creating Lot No. inserts new lines and with "Serial No." and "Lot No.".
        // [SCENARIO 459882] "Assign Package No." on the line with "Serial No." and "Lot No." sets "Package No.", without inserting new line.
        Initialize();

        // [GIVEN] Create Item Tracking Code with Serial, Lot and Package tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, true);

        // [GIVEN] Create Item with Serial, Lot and Package tracking
        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);

        // [GIVEN] Create Item Journal Line and open tracking lines
        CreateItemJournalLine(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));  // Take random for Quantity and used blank for Location and Bin Code.
        LibraryVariableStorage.Enqueue(TrackingOption::CreateCustomizedSNWithLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity); // Enqueue for CustomizedSerialPageHandlerAssignLot.
        CreateSNInfo := false;
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] [THEN] Verified in ItemTrackingLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,CustomizedSerialPageHandlerAssignPackage')]
    procedure ItemTrackingLines_CreateCustomizedSerialNoWithPackage_ThenAssignLot()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking] [Item Journal]
        // [SCENARIO 459882] "Create Customized SN" with creating Package No. inserts new lines and with "Serial No." and "Package No.".
        // [SCENARIO 459882] "Assign Lot No." on the line with "Serial No." and "Package No." sets "Lot No.", without inserting new line.
        Initialize();

        // [GIVEN] Create Item Tracking Code with Serial, Lot and Package tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, true);

        // [GIVEN] Create Item with Serial, Lot and Package tracking
        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);

        // [GIVEN] Create Item Journal Line and open tracking lines
        CreateItemJournalLine(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));  // Take random for Quantity and used blank for Location and Bin Code.
        LibraryVariableStorage.Enqueue(TrackingOption::CreateCustomizedSNWithPackageNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity); // Enqueue for CustomizedSerialPageHandlerAssignPackage.
        CreateSNInfo := false;
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] [THEN] Verified in ItemTrackingLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,CustomizedSerialPageHandlerAssignLotAndPackage')]
    procedure ItemTrackingLines_CreateCustomizedSerialNoWithLotAndPackage()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking] [Item Journal]
        // [SCENARIO 459882] "Create Customized SN" with creating Lot No. and Package No. inserts new lines and with "Serial No.", "Lot No." and "Package No.".
        Initialize();

        // [GIVEN] Create Item Tracking Code with Serial, Lot and Package tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true, true);

        // [GIVEN] Create Item with Serial, Lot and Package tracking
        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);

        // [GIVEN] Create Item Journal Line and open tracking lines
        CreateItemJournalLine(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));  // Take random for Quantity and used blank for Location and Bin Code.
        LibraryVariableStorage.Enqueue(TrackingOption::CreateCustomizedSNWithLotNoAndPackageNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity); // Enqueue for CustomizedSerialPageHandlerAssignLotAndPackage.
        CreateSNInfo := false;
        ItemJournalLine.OpenItemTrackingLines(false);

        // [WHEN] [THEN] Verified in ItemTrackingLinesPageHandler
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerTrue')]
    procedure PostPurchaseOrderWhenItemTrackingLinesWithLotNoAndPackageNoAssigned()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 504315] Item tracking error "Package No. must be equal to 'x' in item ledger entry: Entry No.=xxx. Current value is 'x'." 
        // when package tracking is enabled, and a job is used on a purchase order.
        Initialize();

        // [GIVEN] Create Item Tracking Code with Lot and Package tracking
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);

        // [GIVEN] Create Purchase Order with Job when Item with Lot and Package tracking
        CreatePurchaseDocumentWithJobAndLotTracking(PurchaseLine, PurchaseHeader."Document Type"::Order, ItemTrackingCode.Code);

        // [THEN] Purchase Order Post without any Error
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerTrue,ProductionJournalPageHandler,MessageHandler')]
    procedure VerifyConsumptionAppliedToUnreservedItemLedgerEntry()
    var
        Bins: array[4] of record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityline: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        LotNo: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO 557020] Consumption should not apply to already reserved Item Ledger Entry from other demands.
        Initialize();

        // [GIVEN] Create a LOT tracked Item.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Create a Whse Location and setup the Bins in the Location.
        CreateWhseLocationWithBins(Location, Bins);

        // [GIVEN] Initialize the LotNo and Quantity.
        LotNo := LibraryUtility.GenerateGUID();
        Quantity := 1;

        // [GIVEN] Create the Inventory Posting Setup for the Location.
        LibraryInventory.UpdateInventoryPostingSetup(Location);

        // [GIVEN] Create and Post two Positive Adjustment Journal at Bin[1] of Location with Quantity = 1 and "Lot No" = LotNo.      
        CreateAndPostTwoLinePositiveAdjustmentJnlwithLotNo(Location.Code, Bins[1].Code, Item."No.", Quantity, LotNo);

        // [GIVEN] Create a Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create a Sales Order, then create the Warehouse Shipment from the Sales Order.
        CreateSalesOrderAndWareshouseShipment(SalesHeader, Item."No.", Location.Code, Quantity);

        // [WHEN] Create and Register the Warehouse Pick.
        CreateAndRegisterPickFromWareshouseShipment(SalesHeader."No.", LotNo, '', Quantity);

        // [THEN] Quantity = 1 will be reserve for the Sales Order from the first Item Ledger Entry.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Reserved Quantity");
        Assert.AreEqual(Quantity, ItemLedgerEntry."Reserved Quantity", StrSubstNo(ReservationIsNotcreatedForSOErr, SalesHeader."No."));

        // [GIVEN] Create and refresh a Released Production Order.
        CreateAndRefreshProductionOrderOnLocation(ProductionOrder, Location.Code, Item."No.", Quantity);

        // [GIVEN] Create a Prod. Order Component using same Item and "Quantity Per" = 1.
        CreateProdOrderComponent(ProductionOrder, ProdOrderLine, Item."No.", Location.Code);

        // [GIVEN] Create a Warehouse Pick from Production Order.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [GIVEN] Update the "Lot No." and register the Warehouse Pick.
        WhseActivityline.SetRange("Source No.", ProductionOrder."No.");
        if WhseActivityline.FindSet() then
            WhseActivityline.ModifyAll("Lot No.", LotNo, true);
        WhseActivityHeader.Get(WhseActivityline."Activity Type", WhseActivityline."No.");
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // [WHEN] Create and post the Production Journal with LotNo.
        CreateAndPostProductionJnlWithLotNo(ProductionOrder, ProdOrderLine."Line No.", LotNo);

        // [THEN] Verify that the consumption is applied to second Item Ledger Entry as first Item Ledger Entry is reserved for Sales Order.
        // So there should be one open Item Ledger Entry with "Reserved Quantity" > 0.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange(Open, true);
        ItemLedgerEntry.SetFilter("Reserved Quantity", '<>%1', 0);
        Assert.RecordCount(ItemLedgerEntry, 1);

        // [WHEN] Posting the Warehouse Shipment.
        PostWarehouseShipmentFromSalesOrder(SalesHeader);

        // [THEN] Verified as no error occurred.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure LotNoOnInvtPickLineByFEFOWithOtherLotsBlocked()
    var
        Location: Record Location;
        Item: Record Item;
        LotNoInformation: Record "Lot No. Information";
        ItemJournalLine: Record "Item Journal Line";
        ReservEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: array[3] of Code[50];
        i: Integer;
    begin
        // [FEATURE] [FEFO] [Item Tracking] [Blocked] [Inventory Pick]
        // [SCENARIO 550978] Available lot no. is populated on inventory pick line when FEFO is enabled and other lots are blocked.
        Initialize();

        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);

        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(true, false, true));

        for i := 1 to 3 do begin
            LotNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreateLotNoInformation(LotNoInformation, Item."No.", '', LotNo[i]);
            LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', 1);
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine, '', LotNo[i], ItemJournalLine.Quantity);
            ReservEntry.Validate("Expiration Date", WorkDate());
            ReservEntry.Modify(true);
            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        end;

        LotNoInformation.Get(Item."No.", '', LotNo[1]);
        LotNoInformation.Validate(Blocked, true);
        LotNoInformation.Modify(true);
        LotNoInformation.Get(Item."No.", '', LotNo[2]);
        LotNoInformation.Validate(Blocked, true);
        LotNoInformation.Modify(true);

        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, Item."No.", Location.Code, 1);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickMovement(SalesHeader."Document Type", SalesHeader."No.", false, true, false);

        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesLine."Document No.", WarehouseActivityLine."Activity Type"::"Invt. Pick", SalesLine."Location Code",
          WarehouseActivityLine."Action Type"::" ");
        WarehouseActivityLine.TestField("Lot No.", LotNo[3]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SerialNoOnInvtPickLineByFEFOWithOtherSerialsBlocked()
    var
        Location: Record Location;
        Item: Record Item;
        SerialNoInformation: Record "Serial No. Information";
        ItemJournalLine: Record "Item Journal Line";
        ReservEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SerialNo: array[3] of Code[50];
        i: Integer;
    begin
        // [FEATURE] [FEFO] [Item Tracking] [Blocked] [Inventory Pick]
        // [SCENARIO 550978] Available serial no. is populated on inventory pick line when FEFO is enabled and other serial nos. are blocked.
        Initialize();

        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);

        CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(false, true, true));

        for i := 1 to 3 do begin
            SerialNo[i] := LibraryUtility.GenerateGUID();
            LibraryItemTracking.CreateSerialNoInformation(SerialNoInformation, Item."No.", '', SerialNo[i]);
            LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', 1);
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine, SerialNo[i], '', ItemJournalLine.Quantity);
            ReservEntry.Validate("Expiration Date", WorkDate());
            ReservEntry.Modify(true);
            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        end;

        SerialNoInformation.Get(Item."No.", '', SerialNo[1]);
        SerialNoInformation.Validate(Blocked, true);
        SerialNoInformation.Modify(true);
        SerialNoInformation.Get(Item."No.", '', SerialNo[2]);
        SerialNoInformation.Validate(Blocked, true);
        SerialNoInformation.Modify(true);

        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, Item."No.", Location.Code, 1);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickMovement(SalesHeader."Document Type", SalesHeader."No.", false, true, false);

        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesLine."Document No.", WarehouseActivityLine."Activity Type"::"Invt. Pick", SalesLine."Location Code",
          WarehouseActivityLine."Action Type"::" ");
        WarehouseActivityLine.TestField("Serial No.", SerialNo[3]);
    end;

    [Test]
    procedure ItemTrackingNumbersRequireItemTrackingCode()
    var
        Item: Record Item;
        ItemJournalPage: TestPage "Item Journal";
    begin
        // [SCENARIO 562516] User should not be able to enter tracking numbers without an item tracking code on the Item Journal page
        Initialize();

        // Create Tracked item
        CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(false, true, false));

        // Add tracking numbers
        ItemJournalPage.OpenEdit();
        ItemJournalPage."Item No.".SetValue(Item."No.");

        // [WHEN] Adding tracking numbers to a tracked item with an item tracking code
        // [THEN] No error
        ItemJournalPage."Serial No.".SetValue(LibraryRandom.RandText(10));
        ItemJournalPage."Lot No.".SetValue(LibraryRandom.RandText(10));
        ItemJournalPage."Package No.".SetValue(LibraryRandom.RandText(10));

        // [WHEN] Removing the item tracking code
        Item.Validate("Item Tracking Code", '');
        Item.Modify();

        // [THEN] The same fields are not editable
        asserterror ItemJournalPage."Serial No.".SetValue(LibraryRandom.RandText(10));
        asserterror ItemJournalPage."Lot No.".SetValue(LibraryRandom.RandText(10));
        asserterror ItemJournalPage."Package No.".SetValue(LibraryRandom.RandText(10));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesLotPackageHandler')]
    procedure ReclassificationOfLotWithNewExpDateForQtyLessThanQtyInILEGivesErr()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        LotNo: Code[50];
        PackageNo: Code[50];
        Quantity: Decimal;
    begin
        // [SCENARIO 579658] When Stan Posts an Item Reclassification Journal Line with "New Expiration Date" and "New Package No." for a "Lot No." with Quantity less
        // than its Quantity in Item Ledger Entry, then it gives error.
        Initialize();

        // [GIVEN] Create an Item Tracking Code.
        CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [GIVEN] Generate and save Quantity, Lot No. and Package No. in Variables.
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        LotNo := LibraryUtility.GenerateGUID();
        PackageNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Create and Post Item Journal Line.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(PackageNo);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(Quantity);
        CreateAndPostItemJournalLine(Item."No.", Quantity);

        // [GIVEN] Create an Item Reclassification Journal Line.
        CreateItemReclassificationJournalLine(ItemJournalLine, Item."No.", LibraryRandom.RandIntInRange(10, 50));

        // [GIVEN] Open Item Tracking Lines.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(PackageNo);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(CalcDate('<2D>', WorkDate()));
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        ItemJournalLine.OpenItemTrackingLines(true);

        // [WHEN] Post Item Reclassification Journal Line.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] An error appears: New Expiration Date must be equal to Workdate
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(SingleExpirationDateErr, WorkDate())) > 0, GetLastErrorText)
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Item Tracking II");
        // Clear Global variables.
        LibraryVariableStorage.Clear();
        IsUsingSimpleYesConfirmHandler := false;
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Item Tracking II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        InventorySetup.Validate("Package Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Item Tracking II");
    end;

    local procedure AssignSerialNoOnPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure AssignSerialNoAndReceivePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    begin
        AssignSerialNoOnPurchaseOrder(PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post Purchase Receipt.
        UpdatePurchaseLine(PurchaseLine);  // Update Quatity-to Invoice with partial Quantity.
    end;

    local procedure AssignTrackingAndReserveOnSalesLine(SalesLine: Record "Sales Line"; SummaryOption: Option; Quantity: Decimal)
    begin
        SalesLine.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(SerialLotConfirmMessage);  // Enqueue value for ConfirmHandler.
        SalesLine.ShowReservation();
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(SummaryOption);  // Enqueue value for ItemTrackingSummaryPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CalcRegenPlanAndCarryOutActionMsg(Item: Record Item; LocationCode: Code[10]; VendorNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));  // Dates based on WORKDATE.
        FindAndUpdateRequisitionLine(RequisitionLine, Item."No.", LocationCode, VendorNo);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CreateLotSNWarehouseTrackingItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(Item, '', '', CreateLotSNWarehouseItemTrackingCode());
        exit(Item."No.");
    end;

    local procedure CreateAndUpdateItem(SerialSpecific: Boolean; LotSpecific: Boolean): Code[20]
    var
        Item: Record Item;
        ExpirationDate: DateFormula;
    begin
        CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(LotSpecific, SerialSpecific, true));
        Evaluate(ExpirationDate, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        Item.Validate("Expiration Calculation", ExpirationDate);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostItemJournalLineWithIT(var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
        Bin: Record Bin;
        LotNo: Variant;
    begin
        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(true, false, false));
        CreateLocationWithBin(Bin);
        CreateItemJournalLine(ItemJournalLine, Item."No.", Bin."Location Code", Bin.Code, LibraryRandom.RandInt(10));  // Take random Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryVariableStorage.Dequeue(LotNo);
    end;

    local procedure CreateAndPostPosAdjmtItemJournalLineWithIT(Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Bin."Location Code", Bin.Code, Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::SetLotAndSerial);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateItemWarehouseInventoryWithLotInfo(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]) LotNo: Code[50]
    begin
        LotNo := CreateLotNoInformation(ItemNo);
        CreateItemWarehouseInventoryWithTrackingAttribute(ItemJournalLine, ItemNo, TrackingOption::EditValue, LotNo);
    end;

    local procedure CreateItemWarehouseInventoryWithSNInfo(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]) SN: Code[20]
    begin
        SN := CreateSNInformation(ItemNo);
        CreateItemWarehouseInventoryWithTrackingAttribute(ItemJournalLine, ItemNo, TrackingOption::EditSNValue, SN);
    end;

    local procedure CreateItemWarehouseInventoryWithTrackingAttribute(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; TrackingOptionPar: Option; AttributeValue: Code[20])
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemJournalLine(ItemJournalLine, ItemNo, Location.Code, '', 1);
        SetItemJournalLineTrackingAttribute(ItemJournalLine, TrackingOptionPar, AttributeValue);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostPurchaseOrderWithIT(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; TrackOption: Option)
    begin
        CreatePurchaseOrder(PurchaseLine, ItemNo, LibraryRandom.RandInt(10) + 20);  // Quantity shoulb be always more thant 20 required for Test.
        LibraryVariableStorage.Enqueue(TrackOption);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        PostPurchaseOrder(PurchaseLine);
    end;

    local procedure CreateAndRefreshProductionOrderOnLocation(var ProductionOrder: Record "Production Order"; LocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Qty);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, true);
    end;

    local procedure CreateItemWithTrackingAttrNoPosting(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; TrackingOptionPar: Option; AttributeValue: Code[20]; Qty: Decimal)
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemJournalLine(ItemJournalLine, ItemNo, Location.Code, '', Qty);
        SetItemJournalLineTrackingAttribute(ItemJournalLine, TrackingOptionPar, AttributeValue)
    end;

    local procedure AssertSNInfoExists(ItemJnlLine: Record "Item Journal Line")
    var
        ReservationEntry: Record "Reservation Entry";
        SerialNoInformation: Record "Serial No. Information";
    begin
        ReservationEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservationEntry.SetRange("Source ID", ItemJnlLine."Journal Template Name");
        ReservationEntry.SetRange("Source Batch Name", ItemJnlLine."Journal Batch Name");
        ReservationEntry.SetRange("Source Ref. No.", ItemJnlLine."Line No.");

        if (ReservationEntry.FindSet()) then
            repeat
                Assert.IsTrue(SerialNoInformation.Get(ReservationEntry."Item No.", '', ReservationEntry."Serial No."), TheSerialNoInfoDoesNotExistErr);
            until (ReservationEntry.Next() = 0);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateSalesCreditMemo(var SalesHeader: Record "Sales Header"; No: Code[20]; SellToCustomerNo: Code[20])
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SellToCustomerNo);
        SalesGetReturnReceipts.SetSalesHeader(SalesHeader);
        ReturnReceiptLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        ReturnReceiptLine.SetRange("No.", No);
        ReturnReceiptLine.FindFirst();
        SalesGetReturnReceipts.CreateInvLines(ReturnReceiptLine);
    end;

    local procedure CreateInventoryPickOnSalesLine(var SalesLine: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryVariableStorage.Enqueue(PickCreated);
        LibraryWarehouse.CreateInvtPutPickMovement(SalesHeader."Document Type", SalesHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick", SalesLine."Location Code",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.FindFirst();
        exit(WarehouseActivityHeader."No.");
    end;

    local procedure CreateInvtPutAwayForProdOrder(var WhseActivHeader: Record "Warehouse Activity Header"; ProdOrderLine: Record "Prod. Order Line"; QtyToHandle: Decimal)
    var
        Bin: Record Bin;
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        LibraryWarehouse.FindBin(Bin, ProdOrderLine."Location Code", '', 1);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WhseActivLine."Source Document"::"Prod. Output", ProdOrderLine."Prod. Order No.", true, false, false);
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WhseActivHeader, DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        WhseActivLine.SetRange("No.", WhseActivHeader."No.");
        WhseActivLine.FindFirst();
        WhseActivLine.Validate("Bin Code", Bin.Code);
        WhseActivLine.Validate("Lot No.", LibraryUtility.GenerateGUID());
        WhseActivLine.Validate("Qty. to Handle", QtyToHandle);
        WhseActivLine.Modify(true);
    end;

    local procedure CreateItemReclassificationJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        SummaryOption: Option SetQuantity,VerifyQuantity;
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer, ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(SummaryOption::SetQuantity);
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        ItemJournalLine.OpenItemTrackingLines(true);
    end;

    local procedure CreateItemReclassificationJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer,
          ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemReclassificationJournalLineWithTrackingAttribute(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; TrackingOptionPar: Option; OldAttributeValue: Code[20]; NewAttributeValue: Code[20])
    begin
        CreateItemReclassificationJournalLine(ItemJournalLine, ItemNo, LocationCode, Quantity);
        SetItemJournalLineNewTrackingAttribute(ItemJournalLine, TrackingOptionPar, OldAttributeValue, NewAttributeValue);
    end;

    local procedure SetItemJournalLineNewTrackingAttribute(var ItemJournalLine: Record "Item Journal Line"; TrackingOptionPar: Option; OldAttributeValue: Code[20]; NewAttributeValue: Code[20])
    begin
        LibraryVariableStorage.Enqueue(TrackingOptionPar);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(OldAttributeValue);
        LibraryVariableStorage.Enqueue(NewAttributeValue);
        ItemJournalLine.OpenItemTrackingLines(true);
    end;

    local procedure SetItemJournalLineTrackingAttribute(var ItemJournalLine: Record "Item Journal Line"; TrackingOptionPar: Option; AttributeValue: Code[20])
    begin
        LibraryVariableStorage.Enqueue(TrackingOptionPar);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AttributeValue);
        ItemJournalLine.OpenItemTrackingLines(true);
    end;

    local procedure CreateTrackedItem(var Item: Record Item; LotNos: Code[20]; SerialNos: Code[20]; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateTrackedItem(Item, LotNos, SerialNos, ItemTrackingCode);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemJournalLineItemTrackingEnabled(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        ItemJournalBatch."Item Tracking on Lines" := true;
        ItemJournalBatch.Modify();
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemTrackingCode(LOTSpecific: Boolean; SNSpecific: Boolean; UseExpirationDate: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if UseExpirationDate then
            LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(ItemTrackingCode, SNSpecific, LOTSpecific)
        else
            LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LOTSpecific);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateLotSNWarehouseItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, true);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemInboundLotInfoMustExist(var Item: Record Item)
    begin
        CreateTrackedItem(
          Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCodeInboundInfoMustExist(true, false, true, false, false, false));
    end;

    local procedure CreateItemInboundSNInfoMustExist(var Item: Record Item)
    begin
        CreateTrackedItem(
          Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCodeInboundInfoMustExist(false, true, false, true, false, false));
    end;

    local procedure CreateItemInboundLotInfoMustExistAutoInfoCard(var Item: Record Item)
    begin
        CreateTrackedItem(
          Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCodeInboundInfoMustExist(true, false, true, false, true, false));
    end;

    local procedure CreateItemInboundSNInfoMustExistAutoInfoCard(var Item: Record Item)
    begin
        CreateTrackedItem(
          Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCodeInboundInfoMustExist(false, true, false, true, false, true));
    end;

    local procedure CreateItemTrackingCodeInboundInfoMustExist(LotSpecific: Boolean; SNSpecific: Boolean; InboundLotNoInfoMustExist: Boolean; InboundSNInfoMustExist: Boolean; AutoLotInfo: Boolean; AutoSNInfo: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", LotSpecific);
        ItemTrackingCode.Validate("SN Specific Tracking", SNSpecific);
        ItemTrackingCode.Validate("Lot Info. Inbound Must Exist", InboundLotNoInfoMustExist);
        ItemTrackingCode.Validate("SN Info. Inbound Must Exist", InboundSNInfoMustExist);
        ItemTrackingCode.Validate("Create Lot No. Info on posting", AutoLotInfo);
        ItemTrackingCode.Validate("Create SN Info on Posting", AutoSNInfo);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateLotNoInformation(ItemNo: Code[20]): Code[20]
    var
        LotNoInformation: Record "Lot No. Information";
    begin
        LibraryInventory.CreateLotNoInformation(
          LotNoInformation, ItemNo, '',
          LibraryUtility.GenerateRandomCode(LotNoInformation.FieldNo("Lot No."), DATABASE::"Lot No. Information"));
        exit(LotNoInformation."Lot No.");
    end;

    local procedure CreateSNInformation(ItemNo: Code[20]): Code[20]
    var
        SerialNoInformation: Record "Serial No. Information";
    begin
        LibraryInventory.CreateSerialNoInformation(
          SerialNoInformation, ItemNo, '',
          LibraryUtility.GenerateRandomCode(SerialNoInformation.FieldNo("Serial No."), DATABASE::"Serial No. Information"));
        exit(SerialNoInformation."Serial No.");
    end;

    local procedure CreateLocationWithBin(var Bin: Record Bin)
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Require Pick", true);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin(
          Bin, Location.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
    end;

    local procedure CreateLocationWithReceiveShipRequired(): Code[10]
    var
        Location: Record Location;
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin(
          Bin, Location.Code, CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        Location.Validate("Receipt Bin Code", Bin.Code);
        LibraryWarehouse.CreateBin(
          Bin, Location.Code, CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        Location.Validate("Shipment Bin Code", Bin.Code);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreatePutawayPickLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 1, false);
        exit(Location.Code);
    end;

    local procedure CreateWhseLotSpecificTrackedItem(var Item: Record Item; SNTracking: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.Get(CreateItemTrackingCode(true, false, true));
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Validate("SN Purchase Inbound Tracking", SNTracking);
        ItemTrackingCode.Modify(true);
        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);
        Evaluate(Item."Expiration Calculation", '<1Y>');
        Item.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithLocation(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreatePurchaseOrder(PurchaseLine, CreateAndUpdateItem(true, false), 2 * LibraryRandom.RandInt(10));  // Take random Quantity.
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithIT(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LotNo: Code[50])
    begin
        CreatePurchaseOrder(PurchaseLine, ItemNo, PurchaseLine.Quantity);  // Take random Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::EditValue);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesRetOrdWithIT(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        Location: Record Location;
    begin
        CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(false, true, false));  // Blank value for Lot No.
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::"Return Order", Item."No.",
          LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location),
          LibraryRandom.RandInt(10));  // Random value for Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
    end;

    local procedure CreateWhseShptAndRegisterPick(PurchaseLine: Record "Purchase Line")
    var
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        CreateSalesOrderWithIT(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity / 2, 1);  // Taking 1 for Quantity as Item Tracking code is Serial Specific.
        CreateWarehouseShipment(SalesLine."Document No.");
        WarehouseShipmentHeader.SetRange("Location Code", PurchaseLine."Location Code");
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(SalesLine."Document No.", WarehouseActivityHeader.Type::Pick, PurchaseLine."Location Code");
    end;

    local procedure CreateSetupforSalesOrder(var SalesLine: Record "Sales Line"; LOTSpecific: Boolean; SNSpecific: Boolean)
    var
        Location: Record Location;
        Item: Record Item;
    begin
        CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(LOTSpecific, SNSpecific, false));
        LibraryWarehouse.CreateLocation(Location);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, Item."No.", Location.Code, LibraryRandom.RandInt(10));  // Take random for Quantity.
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithIT(var SalesLine: Record "Sales Line"; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal; SetQuantity: Decimal)
    var
        SummaryOption: Option SetQuantity,VerifyQuantity,VerifyExpirationDate;
    begin
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, No, LocationCode, Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(SummaryOption::SetQuantity);  // Enqueue value for ItemTrackingSummaryPageHandler.
        LibraryVariableStorage.Enqueue(SetQuantity);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryERM.FindGLAccount(GLAccount);
        UpdateGeneralLedgerSetup(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", GLAccount."No.");
    end;

    local procedure CreatePurchOrderWithLocation(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateWarehouseShipment(DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateInvtPutawayWithLotSNTrackingItemPurchase(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseRequest: Record "Warehouse Request";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '',
          CreateLotSNWarehouseTrackingItem(), 1, CreatePutawayPickLocation(), WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          PurchaseLine."Location Code", WarehouseActivityLine."Action Type"::Place);
    end;

    local procedure CreateInvtPutawayWithLotSNTrackingItemProduction(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, CreateLotSNWarehouseTrackingItem(), 1);
        ProductionOrder.Validate("Location Code", CreatePutawayPickLocation());
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, true);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          ProductionOrder."Location Code", WarehouseActivityLine."Action Type"::Place);
    end;

    local procedure CreateInvtPickWithLotSNTrackingItem(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseRequest: Record "Warehouse Request";
        LocationCode: Code[10];
        ItemNo: Code[20];
    begin
        LocationCode := CreatePutawayPickLocation();
        ItemNo := CreateLotSNWarehouseTrackingItem();
        Bin.SetRange("Location Code", LocationCode);
        Bin.FindFirst();
        CreateAndPostPosAdjmtItemJournalLineWithIT(Bin, ItemNo, 1);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          ItemNo, 1, LocationCode, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick", SalesLine."Location Code",
          WarehouseActivityLine."Action Type"::Take);
    end;

    local procedure DeleteItemTrackingLines(SalesLine: Record "Sales Line")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, SalesLine."No.", SalesLine."Location Code");
        LibraryVariableStorage.Enqueue(TrackingOption::EditValue); // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(''); // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(CloseItemTrackingLinesWithQtyZeroConfirmErr);
        RequisitionLine.OpenItemTrackingLines();
    end;

    local procedure EnqueueQuantityForReselectEntries(TrackingOptionPar: Option; SummaryOption: Option; SummaryOption2: Option; TotalAvailableQuantity: Decimal; TotalRequestedQuantity: Decimal; CurrentPendingQuantity: Decimal)
    begin
        // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(TrackingOptionPar);
        LibraryVariableStorage.Enqueue(SummaryOption);
        LibraryVariableStorage.Enqueue(SummaryOption2);
        LibraryVariableStorage.Enqueue(TotalAvailableQuantity);
        LibraryVariableStorage.Enqueue(TotalRequestedQuantity);
        LibraryVariableStorage.Enqueue(CurrentPendingQuantity);
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindAndUpdateRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20]; LocationCode: Code[10]; VendorNo: Code[20])
    begin
        FindRequisitionLine(RequisitionLine, No, LocationCode);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure FindReservationEntry(var ReservationEntry: Record "Reservation Entry"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
    end;

    local procedure FindReservationEntryForSerialNo(ItemNo: Code[20]; LocationCode: Code[10]; SerialNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FindReservationEntry(ReservationEntry, LocationCode, ItemNo);
        ReservationEntry.SetRange("Serial No.", SerialNo);
        ReservationEntry.FindFirst();
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20]; LocationCode: Code[10])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptNo(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]): Code[20]
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
        exit(WarehouseReceiptLine."No.");
    end;

    local procedure SetupSalesAndPurchEntryWithIT(var SalesLine: Record "Sales Line"; Quantity: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SummaryOption: Option SetQuantity,VerifyQuantity,VerifyExpirationDate;
    begin
        // Create Item, update Expiration calculation on Item, create and post Purchase Order, create Sales Order.
        CreatePurchaseOrder(PurchaseLine, CreateAndUpdateItem(true, false), Quantity);
        AssignSerialNoAndReceivePurchaseOrder(PurchaseHeader, PurchaseLine);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, PurchaseLine."No.", '', Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(SummaryOption::SetQuantity);  // Enqueue value for ItemTrackingSummaryPageHandler.
    end;

    local procedure PostPurchaseOrderWithLocation(var PurchaseLine: Record "Purchase Line")
    var
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateLocationWithBin(Bin);
        CreatePurchaseOrderWithLocation(PurchaseLine, Bin."Location Code", Bin.Code);
        AssignSerialNoAndReceivePurchaseOrder(PurchaseHeader, PurchaseLine);
    end;

    local procedure PostPurchaseOrder(PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostSalesDocument(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));
    end;

    local procedure PostWhseRcptAndRegisterPutAway(var PurchaseLine: Record "Purchase Line")
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // Create Purchase Order with Item Tracking.
        CreatePurchaseOrderWithLocation(PurchaseLine, Location.Code, '');
        AssignSerialNoOnPurchaseOrder(PurchaseHeader, PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Create Warehouse Receipt from Purchase Order and Register.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        RegisterWarehouseActivity(PurchaseLine."Document No.", WarehouseActivityHeader.Type::"Put-away", PurchaseLine."Location Code");
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(FindWarehouseReceiptNo(SourceDocument, SourceNo));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostItemJournalWithTracking(ItemNo: Code[20]; TrackingNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, '', '', Qty);
        LibraryVariableStorage.Enqueue(TrackingNo);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, ActivityType, LocationCode, WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, TemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetupForMultipleExpirDateOnILE(var PurchaseLine: Record "Purchase Line"): Code[20]
    var
        Item: Record Item;
        LotNo: Variant;
    begin
        // Create and post Purchase Order having same Lot No. and update Expiration Date on Item Ledger Entry.
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, CreateAndUpdateItem(false, true), TrackingOption::AssignLotNo);
        LibraryVariableStorage.Dequeue(LotNo);
        Item.Get(PurchaseLine."No.");
        CreatePurchaseOrderWithIT(PurchaseLine, PurchaseLine."No.", LotNo);
        PostPurchaseOrder(PurchaseLine);
        UpdateExpirDateOnILE(PurchaseLine."No.");
        exit(LotNo);
    end;

    local procedure UpdateExpirDateOnILE(ItemNo: Code[20]): Date
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ExpirationDate: Date;
    begin
        Item.Get(ItemNo);
        ExpirationDate := CalcDate(Item."Expiration Calculation", WorkDate());
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
        ItemLedgerEntry.Validate("Expiration Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', ExpirationDate));
        ItemLedgerEntry.Modify(true);
        exit(ItemLedgerEntry."Expiration Date");
    end;

    local procedure UpdateLotSerialNoInWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; LNo: Code[20]; SNo: Code[20])
    begin
        WarehouseActivityLine.Validate("Lot No.", LNo);
        WarehouseActivityLine.Validate("Serial No.", SNo);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / 2);  // Take partial Quantity.
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePurchaseLineAndAssignIT(var PurchaseLine: Record "Purchase Line"; FieldNo: Integer; Value: Variant; TrackingOptionPar: Option; Quantity: Decimal)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        // Update Purchase Line based on Field and its corresponding value.
        RecRef.GetTable(PurchaseLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(PurchaseLine);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(TrackingOptionPar);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure UpdateGeneralLedgerSetup(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; AccountNo: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup.Validate("Sales Account", AccountNo);
        GeneralPostingSetup.Validate("Purch. Account", AccountNo);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure VerifyTrackingOnItemLedgerEntry(ItemNo: Code[20]; SerialNo: Code[50]; LotNo: Code[50])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
        ItemLedgerEntry.TestField("Serial No.", SerialNo);
        ItemLedgerEntry.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyExpirationDateOnItemLedgerEntry(ItemNo: Code[20]; ExpirationDate: Date)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo);
        ItemLedgerEntry.TestField("Expiration Date", ExpirationDate);
    end;

    local procedure VerifyExpirationDateForItemTracking(ItemNo: Code[20]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Expiration Date", ExpirationDate);
    end;

    local procedure VerifyWarehouseEntry(ItemJournalLine: Record "Item Journal Line")
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        WarehouseEntry.SetRange("Entry Type", WarehouseEntry."Entry Type"::Movement);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Location Code", ItemJournalLine."Location Code");
    end;

    local procedure VerifyPurchRcpt(OrderNo: Code[20])
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
        PurchRcptHeader.TestField("Order No.", OrderNo);
    end;

    local procedure VerifyPurchaseOrderItemTracking(LocationCode: Code[10]; ItemNo: Code[20]; LotNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange(Positive, true);
        FindReservationEntry(ReservationEntry, LocationCode, ItemNo);
        ReservationEntry.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyDeletedItemTracking(SalesLine: Record "Sales Line")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FindReservationEntry(ReservationEntry, SalesLine."Location Code", SalesLine."No.");
        ReservationEntry.TestField("Item Tracking", ReservationEntry."Item Tracking"::None);
    end;

    local procedure VerifyWarehouseEntriesSN(ItemNo: Code[20]; ExpectedSerialNo: Code[50])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.FindSet();
        repeat
            Assert.AreEqual(ExpectedSerialNo, WarehouseEntry."Serial No.", WrongSerialNoErr);
        until WarehouseEntry.Next() = 0;
    end;

    local procedure CreateSalesRetOrderGetPstdDocLineToRev(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(ItemNo); // Enqueue value for PostedSalesDocumentLinesPageHandler
        GetPostedDocToReverseOnSalesReturnOrder(SalesHeader."No.");
    end;

    local procedure GetPostedDocToReverseOnSalesReturnOrder(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.Filter.SetFilter("No.", No);
        SalesReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure PostWarehouseShipmentFromSalesOrder(var SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, SalesHeader."No.", SalesHeader."Document Type");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure CreateAndRegisterPickFromWareshouseShipment(SalesHeaderNo: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; QtyToHandle: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreatePickFromWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeaderNo);
        UpdateWarehouseActivityLineWithLotNoAndSerialNo(SalesHeaderNo, LotNo, SerialNo, QtyToHandle);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeaderNo,
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure UpdateWarehouseActivityLineWithLotNoAndSerialNo(SalesHeaderNo: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; QtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Sales Order");
        WarehouseActivityLine.SetRange("Source No.", SalesHeaderNo);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Lot No.", LotNo);
            WarehouseActivityLine.Validate("Serial No.", SerialNo);
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify();
        until WarehouseActivityLine.Next() = 0;
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

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure CreateSalesOrderAndWareshouseShipment(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateAndRegisterPutAwayFromPurchaseOrder(SourceNo: Code[20]; LocationCode: Code[10])
    var
        Bin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindPickBin(Bin, LocationCode);
        UpdateBinCodeOnPutAwayLine(Bin, SourceNo);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo, WarehouseActivityLine."Activity Type"::"Put-away");
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

    local procedure RegisterWarehouseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterWarehouseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure UpdateBinCodeOnPutAwayLine(Bin: Record Bin; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.Validate("Zone Code", Bin."Zone Code");
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
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

    local procedure CreateAndPostWhseRcptFromSalesReturn(SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, SalesHeader."No.", WarehouseReceiptLine."Source Document"::"Sales Return Order");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Register Put-away
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader."No.",
          ItemNo, WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndPostWarehouseReceiptFromPO(PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure CreatePurchaseOrderWithLocationAndTrackingData(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; LotNo: Code[50]; SerialNo: Code[50]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingOption::SetLotAndSerial);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(Quantity);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseDocumentWithJobAndLotTracking(
        var PurchaseLine: Record "Purchase Line";
        DocumentType: Enum "Purchase Document Type";
        ItemTrackingCode: Code[10])
    begin
        CreatePurchaseDocumentWithJob(PurchaseLine, DocumentType, ItemTrackingCode);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNoAndPackageNo);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseDocumentWithJob(
        var PurchaseLine: Record "Purchase Line";
        DocumentType: Enum "Purchase Document Type";
        ItemTrackingCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(5, 10));
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        UpdatePurchaseLineWithJobTask(PurchaseLine, JobTask);
    end;

    local procedure UpdatePurchaseLineWithJobTask(var PurchaseLine: Record "Purchase Line"; JobTask: Record "Job Task")
    begin
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::Budget);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateWhseLocationWithBins(var Location: Record Location; var Bin: array[4] of record Bin)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bin[3], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bin[4], Location.Code, '', '', '');
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");
        Location.Validate("Shipment Bin Code", Bin[2].Code);
        Location.Validate("Receipt Bin Code", Bin[3].Code);
        Location.Validate("To-Production Bin Code", Bin[4].Code);
        Location.Modify(true);
    end;

    local procedure CreatePositiveAdjmtLocationAndBin(
        ItemJnlTemplateName: Code[10]; ItemJnlBatchName: Code[10]; LocationCode: Code[10];
        BinCode: Code[20]; ItemNo: Code[20]; ItemQty: Integer; LotNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJnlTemplateName, ItemJnlBatchName,
            ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, ItemQty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine."Bin Code" := BinCode;
        ItemJournalLine.Validate("Lot No.", LotNo);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndPostTwoLinePositiveAdjustmentJnlwithLotNo(
        LocationCode: Code[10];
        BinCode: Code[20];
        ItemNo: Code[20];
        Quantity: Decimal;
        LotNo: Code[20])
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);

        CreatePositiveAdjmtLocationAndBin(ItemJnlTemplate.Name, ItemJnlBatch.Name, LocationCode, BinCode, ItemNo, Quantity, LotNo);
        CreatePositiveAdjmtLocationAndBin(ItemJnlTemplate.Name, ItemJnlBatch.Name, LocationCode, BinCode, ItemNo, Quantity, LotNo);

        ItemJournalLine.SetRange("Journal Template Name", ItemJnlTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJnlBatch.Name);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        if ItemJournalLine.FindSet() then
            repeat
                LibraryVariableStorage.Enqueue(TrackingOption::EditValue);
                LibraryVariableStorage.Enqueue(LotNo);
                ItemJournalLine.OpenItemTrackingLines(false);
            until ItemJournalLine.Next() = 0;

        LibraryInventory.PostItemJournalLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);

        ItemJnlTemplate.Delete();
    end;

    local procedure CreateAndPostProductionJnlWithLotNo(ProductionOrder: Record "Production Order"; ProdOrderLineNo: Integer; LotNo: Code[20])
    var
        ReleaseProdOrder: TestPage "Released Production Order";
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::EditValue);
        LibraryVariableStorage.Enqueue(LotNo);

        ReleaseProdOrder.OpenView();
        ReleaseProdOrder.GoToRecord(ProductionOrder);
        ReleaseProdOrder.ProdOrderLines.Filter.SetFilter("Line No.", Format(ProdOrderLineNo));
        ReleaseProdOrder.ProdOrderLines.ProductionJournal.Invoke();
    end;

    local procedure CreateProdOrderComponent(
        var ProductionOrder: Record "Production Order";
        var ProdOrderLine: Record "Prod. Order Line";
        ItemNo: Code[20];
        LocationCode: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        LibraryManufacturing.CreateProductionOrderComponent(
            ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Validate("Flushing Method", ProdOrderComponent."Flushing Method"::"Pick + Manual");
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Package Specific Tracking", true);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemReclassificationJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::Transfer, ItemNo, Quantity);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, '', '', Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateSNInfo.SetValue(CreateSNInfo);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateHandlerForSetQuantity(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    var
        Quantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(Quantity);
        EnterQuantityToCreate.QtyToCreate.SetValue(Quantity);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateHandlerForSetQuantityAssignLot(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    var
        Quantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(Quantity);
        EnterQuantityToCreate.QtyToCreate.SetValue(Quantity);
        EnterQuantityToCreate.CreateNewLotNo.SetValue(true);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EnterQuantityToCreateHandlerForSetQuantityAssignPackage(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    var
        Quantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(Quantity);
        EnterQuantityToCreate.QtyToCreate.SetValue(Quantity);
        EnterQuantityToCreate.CreateNewPackageNo.SetValue(true);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EnterQuantityToCreateHandlerForSetQuantityAssignLotAndPackage(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    var
        Quantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(Quantity);
        EnterQuantityToCreate.QtyToCreate.SetValue(Quantity);
        EnterQuantityToCreate.CreateNewLotNo.SetValue(true);
        EnterQuantityToCreate.CreateNewPackageNo.SetValue(true);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomizedSerialPageHandler(var EnterCustomizedSN: TestPage "Enter Customized SN")
    begin
        EnterCustomizedSN.QtyToCreate.SetValue(LibraryVariableStorage.DequeueInteger());
        EnterCustomizedSN.CustomizedSN.SetValue(LibraryRandom.RandText(40));  // Random Text40 for Serial No.
        EnterCustomizedSN.Increment.SetValue(LibraryRandom.RandInt(10));  // Random Value for Increment starting from 1.
        EnterCustomizedSN.CreateSNInfo.SetValue(CreateSNInfo);
        EnterCustomizedSN.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CustomizedSerialPageHandlerAssignLot(var EnterCustomizedSN: TestPage "Enter Customized SN")
    begin
        EnterCustomizedSN.QtyToCreate.SetValue(LibraryVariableStorage.DequeueInteger());
        EnterCustomizedSN.CustomizedSN.SetValue(LibraryRandom.RandText(40));  // Random Text40 for Serial No.
        EnterCustomizedSN.Increment.SetValue(LibraryRandom.RandInt(10));  // Random Value for Increment starting from 1.
        EnterCustomizedSN.CreateNewLotNo.SetValue(true);
        EnterCustomizedSN.CreateSNInfo.SetValue(CreateSNInfo);
        EnterCustomizedSN.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CustomizedSerialPageHandlerAssignPackage(var EnterCustomizedSN: TestPage "Enter Customized SN")
    begin
        EnterCustomizedSN.QtyToCreate.SetValue(LibraryVariableStorage.DequeueInteger());
        EnterCustomizedSN.CustomizedSN.SetValue(LibraryRandom.RandText(40));  // Random Text40 for Serial No.
        EnterCustomizedSN.Increment.SetValue(LibraryRandom.RandInt(10));  // Random Value for Increment starting from 1.
        EnterCustomizedSN.CreateNewPackageNo.SetValue(true);
        EnterCustomizedSN.CreateSNInfo.SetValue(CreateSNInfo);
        EnterCustomizedSN.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CustomizedSerialPageHandlerAssignLotAndPackage(var EnterCustomizedSN: TestPage "Enter Customized SN")
    begin
        EnterCustomizedSN.QtyToCreate.SetValue(LibraryVariableStorage.DequeueInteger());
        EnterCustomizedSN.CustomizedSN.SetValue(LibraryRandom.RandText(40));  // Random Text40 for Serial No.
        EnterCustomizedSN.Increment.SetValue(LibraryRandom.RandInt(10));  // Random Value for Increment starting from 1.
        EnterCustomizedSN.CreateNewLotNo.SetValue(true);
        EnterCustomizedSN.CreateNewPackageNo.SetValue(true);
        EnterCustomizedSN.CreateSNInfo.SetValue(CreateSNInfo);
        EnterCustomizedSN.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        LotNo: Variant;
        NewLotNo: Variant;
        SN: Variant;
        NewSN: Variant;
        PackageNo: Variant;
        NewPackageNo: Variant;
        "Count": Variant;
        QuantityBase: Variant;
        SummaryOption: Option SetQuantity,VerifyQuantity,VerifyExpirationDate,AssignQty,SelectEntries,ReSelectEntries;
        TrackingOptionLoc: Option;
        Count2: Integer;
        i: Integer;
        ExpirationDateExpectedEditability, NewExpirationDateExpectedEditability : Boolean;
    begin
        TrackingOptionLoc := LibraryVariableStorage.DequeueInteger();  // Dequeue TrackingOption.
        case TrackingOptionLoc of
            TrackingOption::AssignSerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    Assert.IsTrue(ItemTrackingLines.First(), AssignSerialNoStatus);
                end;
            TrackingOption::AssignLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
                end;
            TrackingOption::AssignPackageNo:
                begin
                    ItemTrackingLines."Assign Package No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Package No.".Value);
                end;
            TrackingOption::EditValue:
                begin
                    LibraryVariableStorage.Dequeue(LotNo);
                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsInteger());
                end;
            TrackingOption::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            TrackingOption::UpdateQtyToInvoice:
                begin
                    LibraryVariableStorage.Dequeue(Count);
                    Count2 := Count;
                    for i := 1 to Count2 do
                        ItemTrackingLines."Qty. to Invoice (Base)".SetValue(0);
                end;
            TrackingOption::AssignLotNo2:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingOption::ReSelectEntries:
                begin
                    ItemTrackingLines."Lot No.".AssistEdit();
                    ItemTrackingLines."Lot No.".AssistEdit();
                end;
            TrackingOption::AssignQty:
                begin
                    LibraryVariableStorage.Enqueue(SummaryOption::AssignQty);  // Enqueue value for ItemTrackingSummaryPageHandler.
                    ItemTrackingLines."Lot No.".AssistEdit();
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryRandom.RandInt(10));  // Take random for QuantityBase.
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Quantity (Base)".AsDecimal());   // Enqueue Assigned Qantity.
                end;
            TrackingOption::AssignMoreThanPurchasedQty:
                begin
                    ItemTrackingLines."Lot No.".AssistEdit();
                    LibraryVariableStorage.Dequeue(QuantityBase);
                    ItemTrackingLines."Quantity (Base)".SetValue(QuantityBase);
                    ItemTrackingLines."Lot No.".AssistEdit();
                end;
            TrackingOption::SetNewLotNo:
                begin
                    LibraryVariableStorage.Dequeue(LotNo);
                    LibraryVariableStorage.Dequeue(NewLotNo);
                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."New Lot No.".SetValue(NewLotNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsInteger());
                end;
            TrackingOption::SetNewPackageNo:
                begin
                    LibraryVariableStorage.Dequeue(PackageNo);
                    LibraryVariableStorage.Dequeue(NewPackageNo);
                    ItemTrackingLines."Package No.".SetValue(PackageNo);
                    ItemTrackingLines."New Package No.".SetValue(NewPackageNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsInteger());
                end;
            TrackingOption::EditSNValue:
                begin
                    LibraryVariableStorage.Dequeue(SN);
                    ItemTrackingLines."Serial No.".SetValue(SN);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsInteger());
                end;
            TrackingOption::SetNewSN:
                begin
                    LibraryVariableStorage.Dequeue(SN);
                    LibraryVariableStorage.Dequeue(NewSN);
                    ItemTrackingLines."Serial No.".SetValue(SN);
                    ItemTrackingLines."New Serial No.".SetValue(NewSN);
                    ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsInteger());
                end;
            TrackingOption::SetLotAndSerial:
                begin
                    LibraryVariableStorage.Dequeue(LotNo);
                    LibraryVariableStorage.Dequeue(SN);
                    LibraryVariableStorage.Dequeue(QuantityBase);
                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."Serial No.".SetValue(SN);
                    ItemTrackingLines."Quantity (Base)".SetValue(QuantityBase);
                end;
            TrackingOption::CheckExpDateControls:
                begin
                    ExpirationDateExpectedEditability := LibraryVariableStorage.DequeueBoolean();
                    NewExpirationDateExpectedEditability := LibraryVariableStorage.DequeueBoolean();
                    Assert.AreEqual(ExpirationDateExpectedEditability, ItemTrackingLines."Expiration Date".Editable(), 'Expiration Date editable is not as expected');
                    Assert.AreEqual(NewExpirationDateExpectedEditability, ItemTrackingLines."New Expiration Date".Editable(), 'New Expiration Date editable is not as expected');
                end;
            TrackingOption::CreateCustomizedSN:
                begin
                    LibraryVariableStorage.Dequeue(SN);
                    LibraryVariableStorage.Enqueue(ItemTrackingLines.Quantity3.AsInteger());
                    ItemTrackingLines."Create Customized SN".Invoke();
                end;
            TrackingOption::AssignTwoLotNos:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines.Next();
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            TrackingOption::AssignLotNoAndPackageNo:
                begin
                    // Assign "Lot No." for the 1st line.
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    ItemTrackingLines.First();
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() <> '', 'Lot No. is not assigned for the 1st line.');
                    LotNo := ItemTrackingLines."Lot No.".Value();

                    // Assign "Package No." for the 1st line.
                    ItemTrackingLines."Assign Package No.".Invoke();
                    ItemTrackingLines.First();
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() <> '', 'Package No. is not assigned for the 1st line.');
                    Assert.AreEqual(LotNo, ItemTrackingLines."Lot No.".Value(), 'Lot No. is changed for the 1st line.');
                    PackageNo := ItemTrackingLines."Package No.".Value();
                    ItemTrackingLines.Next();
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() = '', 'Lot No. is not empty for the 2nd line.');
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() = '', 'Package No. is not empty for the 2nd line.');
                    Assert.IsTrue(ItemTrackingLines.Next() = false, 'There is more than 1 line.');

                    // Assign "Lot No." for the 2nd line, copying "Package No." from the 1st line.
                    ItemTrackingLines.First();
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    ItemTrackingLines.Last();
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() <> '', 'Lot No. is not assigned for the 2nd line.');
                    Assert.AreNotEqual(LotNo, ItemTrackingLines."Lot No.".Value(), 'Lot No. on the 2nd line is the same as on the 1st line.');
                    LotNo := ItemTrackingLines."Lot No.".Value();
                    Assert.AreEqual(PackageNo, ItemTrackingLines."Package No.".Value(), 'Package No. on the 2nd line is not equal to the 1st line.');

                    // Assign "Lot No." for the 3rd line, with empty "Package No."
                    ItemTrackingLines.New();
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() <> '', 'Lot No. is not assigned for the 3rd line.');
                    Assert.AreNotEqual(LotNo, ItemTrackingLines."Lot No.".Value(), 'Lot No. on the 3rd line is the same as on the 2nd line.');
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() = '', 'Package No. is not empty for the 3rd line.');
                end;
            TrackingOption::AssignPackageNoAndLotNo:
                begin
                    // Assign "Package No." for the 1st line.
                    ItemTrackingLines."Assign Package No.".Invoke();
                    ItemTrackingLines.First();
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() <> '', 'Package No. is not assigned for the 1st line.');
                    PackageNo := ItemTrackingLines."Package No.".Value();

                    // Assign "Lot No." for the 1st line.
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    ItemTrackingLines.First();
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() <> '', 'Lot No. is not assigned for the 1st line.');
                    Assert.AreEqual(PackageNo, ItemTrackingLines."Package No.".Value(), 'Package No. is changed for the 1st line.');
                    LotNo := ItemTrackingLines."Lot No.".Value();
                    ItemTrackingLines.Next();
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() = '', 'Package No. is not empty for the 2nd line.');
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() = '', 'Lot No. is not empty for the 2nd line.');
                    Assert.IsTrue(ItemTrackingLines.Next() = false, 'There is more than 1 line.');

                    // Assign "Package No." for the 2nd line, copying "Lot No." from the 1st line.
                    ItemTrackingLines.First();
                    ItemTrackingLines."Assign Package No.".Invoke();
                    ItemTrackingLines.Last();
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() <> '', 'Package No. is not assigned for the 2nd line.');
                    Assert.AreNotEqual(PackageNo, ItemTrackingLines."Package No.".Value(), 'Package No. on the 2nd line is the same as on the 1st line.');
                    PackageNo := ItemTrackingLines."Package No.".Value();
                    Assert.AreEqual(LotNo, ItemTrackingLines."Lot No.".Value(), 'Lot No. on the 2nd line is not equal to the 1st line.');

                    // Assign "Package No." for the 3rd line, with empty "Lot No."
                    ItemTrackingLines.New();
                    ItemTrackingLines."Assign Package No.".Invoke();
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() <> '', 'Package No. is not assigned for the 3rd line.');
                    Assert.AreNotEqual(PackageNo, ItemTrackingLines."Package No.".Value(), 'Package No. on the 3rd line is the same as on the 2nd line.');
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() = '', 'Lot No. is not empty for the 3rd line.');
                end;
            TrackingOption::AssignSerialNoWithLotNo:
                begin
                    // "Assign Serial No." with creating Lot No. inserts new lines and with "Serial No." and "Lot No.".
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    Assert.IsTrue(ItemTrackingLines.Last(), AssignSerialNoStatus);
                    Assert.IsTrue(ItemTrackingLines."Serial No.".Value() <> '', 'Serial No. is not assigned for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() <> '', 'Lot No. is not assigned for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() = '', 'Package No. is not empty for the last line.');

                    // "Assign Package No." on the line with "Serial No." and "Lot No." sets "Package No.", without inserting new line.
                    ItemTrackingLines."Assign Package No.".Invoke();
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() <> '', 'Package No. is not assigned for the last line.');
                    ItemTrackingLines.Next();
                    Assert.IsTrue(ItemTrackingLines."Serial No.".Value() = '', 'Serial No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() = '', 'Lot No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() = '', 'Package No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines.Next() = false, 'New line is inserted after assigning Package No.');
                end;
            TrackingOption::AssignSerialNoWithPackageNo:
                begin
                    // "Assign Serial No." with creating Package No. inserts new lines and with "Serial No." and "Package No.".
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    Assert.IsTrue(ItemTrackingLines.Last(), AssignSerialNoStatus);
                    Assert.IsTrue(ItemTrackingLines."Serial No.".Value() <> '', 'Serial No. is not assigned for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() = '', 'Lot No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() <> '', 'Package No. is not assigned for the last line.');

                    // "Assign Lot No." on the line with "Serial No." and "Package No." sets "Lot No.", without inserting new line.
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() <> '', 'Lot No. is not assigned for the last line.');
                    ItemTrackingLines.Next();
                    Assert.IsTrue(ItemTrackingLines."Serial No.".Value() = '', 'Serial No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() = '', 'Lot No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() = '', 'Package No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines.Next() = false, 'New line is inserted after assigning Lot No.');
                end;
            TrackingOption::AssignSerialNoWithLotNoAndPackageNo:
                begin
                    // "Assign Serial No." with creating Lot No. and Package No. inserts new lines and with "Serial No.", "Lot No." and "Package No.".
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    Assert.IsTrue(ItemTrackingLines.Last(), AssignSerialNoStatus);
                    Assert.IsTrue(ItemTrackingLines."Serial No.".Value() <> '', 'Serial No. is not assigned for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() <> '', 'Lot No. is not assigned for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() <> '', 'Package No. is not assigned for the last line.');
                end;
            TrackingOption::CreateCustomizedSNWithLotNo:
                begin
                    // "Create Customized SN" with creating Lot No. inserts new lines and with "Serial No." and "Lot No.".
                    ItemTrackingLines."Create Customized SN".Invoke();
                    Assert.IsTrue(ItemTrackingLines.Last(), AssignSerialNoStatus);
                    Assert.IsTrue(ItemTrackingLines."Serial No.".Value() <> '', 'Serial No. is not assigned for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() <> '', 'Lot No. is not assigned for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() = '', 'Package No. is not empty for the last line.');

                    // "Assign Package No." on the line with "Serial No." and "Lot No." sets "Package No.", without inserting new line.
                    ItemTrackingLines."Assign Package No.".Invoke();
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() <> '', 'Package No. is not assigned for the last line.');
                    ItemTrackingLines.Next();
                    Assert.IsTrue(ItemTrackingLines."Serial No.".Value() = '', 'Serial No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() = '', 'Lot No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() = '', 'Package No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines.Next() = false, 'New line is inserted after assigning Package No.');
                end;
            TrackingOption::CreateCustomizedSNWithPackageNo:
                begin
                    // "Create Customized SN" with creating Package No. inserts new lines and with "Serial No." and "Package No.".
                    ItemTrackingLines."Create Customized SN".Invoke();
                    Assert.IsTrue(ItemTrackingLines.Last(), AssignSerialNoStatus);
                    Assert.IsTrue(ItemTrackingLines."Serial No.".Value() <> '', 'Serial No. is not assigned for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() <> '', 'Package No. is not assigned for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() = '', 'Lot No. is not empty for the last line.');

                    // "Assign Lot No." on the line with "Serial No." and "Package No." sets "Lot No.", without inserting new line.
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() <> '', 'Lot No. is not assigned for the last line.');
                    ItemTrackingLines.Next();
                    Assert.IsTrue(ItemTrackingLines."Serial No.".Value() = '', 'Serial No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() = '', 'Package No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() = '', 'Lot No. is not empty for the last line.');
                    Assert.IsTrue(ItemTrackingLines.Next() = false, 'New line is inserted after assigning Lot No.');
                end;
            TrackingOption::CreateCustomizedSNWithLotNoAndPackageNo:
                begin
                    // "Create Customized SN" with creating Lot No. and Package No. inserts new lines and with "Serial No.", "Lot No." and "Package No.".
                    ItemTrackingLines."Create Customized SN".Invoke();
                    Assert.IsTrue(ItemTrackingLines.Last(), AssignSerialNoStatus);
                    Assert.IsTrue(ItemTrackingLines."Serial No.".Value() <> '', 'Serial No. is not assigned for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Lot No.".Value() <> '', 'Lot No. is not assigned for the last line.');
                    Assert.IsTrue(ItemTrackingLines."Package No.".Value() <> '', 'Package No. is not assigned for the last line.');
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesExpiredLotPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsInteger());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesExpiredSerialNoPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(ItemTrackingLines.Quantity3.AsInteger());
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".AssertEquals(LibraryVariableStorage.DequeueText());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    var
        CurrentPendingQuantity: Variant;
        Quantity: Variant;
        OptionValue: Variant;
        TotalAvailableQuantity: Variant;
        TotalRequestedQuantity: Variant;
        ExpirationDate: Variant;
        OptionString: Option SetQuantity,VerifyQuantity,VerifyExpirationDate,AssignQty,SelectEntries,ReSelectEntries;
        SummaryOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        SummaryOption := OptionValue;  // To convert Variant into Option.
        case SummaryOption of
            OptionString::SetQuantity:
                begin
                    LibraryVariableStorage.Dequeue(Quantity);
                    ItemTrackingSummary.First();
                    ItemTrackingSummary."Selected Quantity".SetValue(Quantity);
                end;
            OptionString::VerifyQuantity:
                begin
                    LibraryVariableStorage.Dequeue(Quantity);
                    ItemTrackingSummary."Selected Quantity".AssertEquals(Quantity);
                end;
            OptionString::VerifyExpirationDate:
                begin
                    LibraryVariableStorage.Dequeue(ExpirationDate);
                    ItemTrackingSummary."Expiration Date".AssertEquals(ExpirationDate);
                end;
            OptionString::ReSelectEntries:
                begin
                    LibraryVariableStorage.Dequeue(TotalAvailableQuantity);  // Dequeue variable.
                    LibraryVariableStorage.Dequeue(TotalRequestedQuantity);  // Dequeue variable.
                    LibraryVariableStorage.Dequeue(CurrentPendingQuantity);  // Dequeue variable.
                    ItemTrackingSummary."Total Available Quantity".AssertEquals(TotalAvailableQuantity);
                    ItemTrackingSummary."Total Requested Quantity".AssertEquals(TotalRequestedQuantity);
                    ItemTrackingSummary."Current Pending Quantity".AssertEquals(CurrentPendingQuantity);
                end;
        end;
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingSummaryModalPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
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
    procedure MessageHandlerValidateMessage(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PostedSalesDocumentLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        PostedSalesDocumentLines.PostedInvoices.FILTER.SetFilter("No.", ItemNo);
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Next();
        ProductionJournal.ItemTrackingLines.Invoke();
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesLotPackageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        IsReclass: Boolean;
    begin
        IsReclass := LibraryVariableStorage.DequeueBoolean();
        if IsReclass then begin
            ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."New Lot No.".SetValue(ItemTrackingLines."Lot No.");
            ItemTrackingLines."Package No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."New Package No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."New Expiration Date".SetValue(LibraryVariableStorage.DequeueDate());
            ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        end else begin
            ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."Package No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingLines."Expiration Date".SetValue(LibraryVariableStorage.DequeueDate());
            ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        end;
        ItemTrackingLines.OK().Invoke();
    end;
}

