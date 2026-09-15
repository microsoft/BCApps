codeunit 137292 "SCM Inventory Costing Orders"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Inventory Costing] [SCM]
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        isInitialized: Boolean;
        AvailabilityWarning: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        BaseCalendarError: Label 'There is no Base Calendar Change within the filter.';
        CloseInventoryPeriodError: Label 'The Inventory Period cannot be closed because there is at least one item with unadjusted entries in the current period.';
        CostAmountMustBeSame: Label 'Cost Amount must be same';
        GlobalItemNo: Code[20];
        GlobalVendorNo: Code[20];
        GlobalQuantity: Decimal;
        GlobalItemTrackingAction: Option SelectEntriesLotNo,AssignLotNo;
        ItemFilter: Label '%1|%2|%3';
        ItemTrackingLotNoError: Label 'Variant  cannot be fully applied';
        OrderTrackingMessage: Label 'There are no order tracking entries for this line.';
        ReservationError: Label 'Applies-to Entry must not be filled out when reservations exist in Item Ledger Entry';
        ReturnOrderTrackingError: Label 'You must use form Item Tracking Lines to enter Appl.-to Item Entry, if item tracking is used.';
        TrackingAndActionMessage: Label 'The change will not affect existing entries.';
        UndoShipmentLine: Label 'Do you want to undo the selected shipment line';
        ValueNotMatchedError: Label 'Value must be same.';
        ReservationDisruptedWarningMsg: Label 'One or more reservation entries exist for the item';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        AverageCostPeriod: Enum "Average Cost Period Type";

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineWithReceiptDate()
    var
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
    begin
        // Verify Receipt Date on Transfer Line.

        // Setup: Create Transfer Header and Line with Base Calendar.
        Initialize();
        CreateTransferOrderWithBaseCalendar(TransferLine);

        // Exercise.
        TransferHeader.Get(TransferLine."Document No.");

        // Verify: Receipt Date on Transfer Line.
        TransferLine.TestField("Receipt Date", TransferHeader."Receipt Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferLineWithShipmentDate()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferOrder: TestPage "Transfer Order";
        ShipmentDate: Date;
    begin
        // Verify Shipment Date on Transfer Line with updated Transfer Header's Shipment Date.

        // Setup: Create Transfer Header and Line with Base Calendar.
        Initialize();
        CreateTransferOrderWithBaseCalendar(TransferLine);
        TransferHeader.Get(TransferLine."Document No.");
        ShipmentDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', TransferHeader."Receipt Date");  // Random value is taken for Shipment Date and 'D' is used for Day.

        // Exercise: Update Shipment Date on Transfer Order page.
        TransferOrder.OpenEdit();
        TransferOrder.FILTER.SetFilter("No.", TransferHeader."No.");
        TransferOrder."Shipment Date".SetValue(ShipmentDate);

        // Verify: Shipment Date on Transfer Line.
        TransferLine.TestField("Shipment Date", TransferHeader."Shipment Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseCalendarChangeError()
    var
        BaseCalendar: Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        // Verify Working Day on Base Calendar Changes must not exist.

        // Setup: Create Base Calendar and Base Calendar Change.
        Initialize();
        LibraryService.CreateBaseCalendar(BaseCalendar);
        CreateBaseCalendarChange(BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange.Day::Tuesday, BaseCalendarChange.Day::Wednesday);
        CreateBaseCalendarChange(BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange.Day::Thursday, BaseCalendarChange.Day::Friday);

        BaseCalendarChange.SetRange("Base Calendar Code", BaseCalendar.Code);
        BaseCalendarChange.SetRange(Day, BaseCalendarChange.Day::Saturday);  // 'Saturday' is taken as Working Day in Base Calendar Change.

        // Exercise.
        asserterror BaseCalendarChange.FindFirst();

        // Verify: Verify that Working Day must not exist in Base Calendar Changes.
        Assert.ExpectedError(StrSubstNo(BaseCalendarError));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReceiptApplyFromItemEntry()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Application using Appl.-from Item Entry field on Service Line.

        // Setup: Create and Receive Purchase Order, Create and Ship Service Order and Create Service Credit Memo.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None), LibraryRandom.RandDec(10, 2),
          false);  // Using Random value for Quantity.
        SetupApplyServiceDocument(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.", false);

        // Exercise.
        ModifyServiceLine(ServiceLine, ItemLedgerEntry."Entry No.");

        // Verify: Verify Appl.-from Item Entry of Service Order must be same as Item Ledger Entry.
        ServiceLine.TestField("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyToEntryOnPurchaseReturnOrder()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Verify Application using Appl.-to Item Entry field on Purchase Return Order.

        // Setup: Create and Receive Purchase Order, Create and Ship Service Order and Create Service Credit Memo.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None), LibraryRandom.RandDec(10, 2),
          false);  // Using Random value for Quantity.
        CreatePurchaseDocument(
          PurchaseLine2, PurchaseHeader."Document Type"::"Return Order", PurchaseLine."Buy-from Vendor No.", PurchaseLine."No.",
          PurchaseLine.Quantity);
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.", true);

        // Exercise.
        ModifyPurchaseLine(PurchaseLine2, ItemLedgerEntry."Entry No.");

        // Verify: Verify Appl.-to Item Entry of Purchase Return Order must be same as Item Ledger Entry.
        PurchaseLine2.TestField("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyToEntryAndAdjustmentOnReturnOrder()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        LineAmount: Decimal;
        LineAmount2: Decimal;
        CostAmountExpected: Decimal;
    begin
        // Verify Adjusted Cost Amount in Value Entry.

        // Setup: Create and Receive Purchase Order, Create and Ship Service Order and Create Service Credit Memo.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None), LibraryRandom.RandDec(10, 2),
          false);  // Using Random value for Quantity.
        LineAmount := PurchaseLine."Line Amount";

        CreatePurchaseHeader(PurchaseHeader2, PurchaseHeader."Document Type"::"Return Order", PurchaseLine."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader2, PurchaseLine2.Type::Item, PurchaseLine."No.", PurchaseLine.Quantity);
        LineAmount2 := PurchaseLine2."Line Amount";
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.", true);
        ModifyPurchaseLine(PurchaseLine2, ItemLedgerEntry."Entry No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, false);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(PurchaseLine2."No.", '');
        CostAmountExpected := LineAmount2 - LineAmount;

        // Verify: Verify Adjusted Cost Amount in Value Entry.
        ValueEntry.SetRange("Item No.", PurchaseLine."No.");
        ValueEntry.SetRange(Adjustment, true);
        ValueEntry.FindFirst();
        Assert.AreEqual(CostAmountExpected, ValueEntry."Cost Amount (Expected)", CostAmountMustBeSame);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorUsingApplyFromItemEntry()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Error while applying on Service Credit Memo.

        // Setup: Create and Receive Purchase Order, Create and Ship Service Order and Create Service Credit Memo.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem(Item."Costing Method"::LIFO, Item."Order Tracking Policy"::None), LibraryRandom.RandDec(10, 2),
          false);  // Using Random value for Quantity.
        SetupApplyServiceDocument(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.", true);

        // Exercise.
        asserterror ServiceLine.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");

        // Verify: Verify Error while validating Appl.-from Item Entry on Service Order.
        Assert.ExpectedTestFieldError(ItemLedgerEntry.FieldCaption(Positive), Format(false));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReceiptErrorUsingLotNo()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Error while posting Service Order with Item Tracking Lot Number.

        // Setup: Create and Receive Purchase Order, Create and Ship Service Order.
        Initialize();
        LibraryVariableStorage.Enqueue(AvailabilityWarning);
        ServiceDocumentWithPurchaseOrder(
          ServiceLine, GlobalItemTrackingAction::AssignLotNo, LibraryUtility.GetGlobalNoSeriesCode(), true, false,
          GlobalItemTrackingAction::AssignLotNo);
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // Exercise.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Verify.
        Assert.IsTrue(StrPos(GetLastErrorText, ItemTrackingLotNoError) > 0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorUsingApplToItemEntry()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceLine: Record "Service Line";
    begin
        // Verify Error while Applying Return Order with 'Entry No.' from  Item Ledger Entry.

        // Setup: Create and Receive Purchase Order, Create and Ship Service Order with Item Tracking.
        Initialize();
        ServiceDocumentWithPurchaseOrder(
          ServiceLine, GlobalItemTrackingAction::SelectEntriesLotNo, LibraryUtility.GetGlobalNoSeriesCode(), true, false,
          GlobalItemTrackingAction::AssignLotNo);
        ServiceLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.

        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::"Return Order", GlobalVendorNo, ServiceLine."No.", ServiceLine.Quantity);
        FindItemLedgerEntry(ItemLedgerEntry, ServiceLine."No.", true);

        // Exercise.
        asserterror PurchaseLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");

        // Verify: Verify error message while Applying Purchase Return Order.
        Assert.ExpectedError(StrSubstNo(ReturnOrderTrackingError));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceCreditMemoError()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Error while posting Service Credit Memo.

        // Setup: Create and Receive Purchase Order, Create and Ship Service Order and Create Service Credit Memo.
        Initialize();
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None), LibraryRandom.RandDec(10, 2),
          false);  // Using Random value for Quantity.
        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Customer No.", PurchaseLine."No.",
          PurchaseLine.Quantity);
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.", false);
        ModifyServiceLine(ServiceLine, ItemLedgerEntry."Entry No.");

        // Exercise: Post Service Credit Memo.
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // Verify: Verify Error while validating posting Service Credit Memo.
        Assert.ExpectedError(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PurchaseLineTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyToEntryUsingOrderTracking()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Order Tracking page values using Item Ledger Entries.

        // Setup: Create and Receive Purchase Order and Return Order.
        Initialize();
        LibraryVariableStorage.Enqueue(TrackingAndActionMessage);
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::"Tracking & Action Msg."),
          LibraryRandom.RandDec(10, 2), false);  // Using Random value for Quantity.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseLine."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLine."No.", PurchaseLine.Quantity);
        GlobalQuantity := PurchaseLine.Quantity;
        GlobalItemNo := PurchaseLine."No.";

        // Exercise: Open Order Tracking page from Purchase Line.
        OpenOrderTracking(PurchaseLine);

        // Verify: Verification done in 'PurchaseLineTrackingPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingActionMessage()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Tracking Message using Order Tracking Policy as 'Tracking & Action Msg.'.

        // Setup: Create and Receive Purchase Order.
        Initialize();
        LibraryVariableStorage.Enqueue(TrackingAndActionMessage);
        LibraryVariableStorage.Enqueue(OrderTrackingMessage);
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::"Tracking & Action Msg."),
          LibraryRandom.RandDec(10, 2), false);  // Using Random value for Quantity.
        GlobalQuantity := PurchaseLine.Quantity;

        // Exercise: Open Order Tracking page from Purchase Line.
        OpenOrderTracking(PurchaseLine);

        // Verify: Verification done in 'MessageHandler' and 'OrderTrackingPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler,AutoReservUsingReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationErrorUsingServiceReturnOrder()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Reservation error while posting Purchase Return Order with Appl.-to Item Entry.

        // Setup: Create and Receive Purchase Order, Create and Ship Service Order and create a Purchase Return Order and perform Reservation.
        Initialize();
        LibraryVariableStorage.Enqueue(TrackingAndActionMessage);
        LibraryVariableStorage.Enqueue(UndoShipmentLine);
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::"Tracking Only"),
          LibraryRandom.RandDec(10, 2), false);  // Using Random value for Quantity.
        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        UndoShipment(ServiceHeader."No.");
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", PurchaseLine."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLine."No.", PurchaseLine.Quantity);
        FindItemLedgerEntry(ItemLedgerEntry, PurchaseLine."No.", true);
        ModifyPurchaseLine(PurchaseLine, ItemLedgerEntry."Entry No.");
        PurchaseLine.ShowReservation();

        // Exercise.
        LibraryVariableStorage.Enqueue(ReservationDisruptedWarningMsg);
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify Reservation error while posting Purchase Return Order with Appl.-to Item Entry
        Assert.ExpectedError(ReservationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostValueEntryToGLWithZeroPurchaseCost()
    begin
        // Post Value Entry to G/L is correct with Zero Cost - Purchase and Verify Quantity, Actual/Expected Cost in Item Ledger Entry.
        Initialize();
        PostValueEntryToGLWithZeroCost();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostValueEntryToGLWithZeroCostACYCostAmount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // This test case verifies Post Value Entry to G/L and ACY Cost Amount is correct with Zero costs in Purchase transaction.

        // Setup: Create Currency and updated then same on General Ledger Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateAddCurrencySetup(CreateCurrency());
        PostValueEntryToGLWithZeroCost();

        // Tear Down: Rollback General Ledger Setup.
        UpdateAddCurrencySetup(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    local procedure PostValueEntryToGLWithZeroCost()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
        Component: Code[20];
        Component2: Code[20];
        Quantity: Decimal;
        ProductionQuantity: Decimal;
    begin
        // This test case verifies Post Value Entry to G/L and ACY Cost Amount is correct with Zero costs in Purchase transaction.

        // Setup: Create Purchase Order for Production and Component Item. Post as Receive.
        Quantity := 10 + LibraryRandom.RandInt(100);  // Using Random value for Quantity.
        ProductionQuantity := LibraryRandom.RandInt(Quantity);  // Using Random value of Quantity for Production Quantity.
        ItemNo :=
          SetupProductionItem(
            Item."Costing Method"::Standard, Item."Replenishment System"::"Prod. Order", LibraryRandom.RandDec(10, 2));  // Using Random value for Standard Cost.
        Component := SetupProductionItem(Item."Costing Method"::FIFO, Item."Replenishment System"::Purchase, 0);  // Using 0 for Standard Cost.
        Component2 := SetupProductionItem(Item."Costing Method"::FIFO, Item."Replenishment System"::Purchase, 0);  // Using 0 for Standard Cost.

        // Added Production BOM No. on Item.
        Item.Get(ItemNo);
        Item.Validate(
          "Production BOM No.", LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, Component, Component2, 1));
        Item.Modify(true);
        UpdateInventorySetup(false, false, "Average Cost Calculation Type"::Item);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Component, Quantity);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Component2, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Create Production Order, Refresh, Post Production Jounral and change status from Release to Finish.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, ProductionQuantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);
        PostProductionJournal(ProductionOrder);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Exercise: Run Adjust Cost Item Entries report.
        LibraryCosting.AdjustCostItemEntries(StrSubstNo(ItemFilter, ItemNo, Component, Component2), '');

        // Verify: Verify Quantity Expected/Actual Cost ACY for Component Item in Item Ledger Entry.
        VerifyItemLedgerEntry(Component, true, Quantity);
        VerifyItemLedgerEntry(Component, false, -ProductionQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RevaluationUsingServiceAndPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ItemJournalLine: Record "Item Journal Line";
        Vendor: Record Vendor;
    begin
        // Verify Reservation using Item with Order Tracking Policy as Tracking Only.

        // Setup: Create and Receive Purchase Order, Create and Ship Service Order.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::Order, Vendor."No.",
          CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None), LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Create and post Service Order and run Adjust Cost Item Entrie batch job.
        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');

        // Exercise.
        CreateItemJournalForRevaluation(ItemJournalLine, PurchaseLine."No.");

        // Verify: Verify Revaluated value in the Revaluation Journal.
        Item.Get(PurchaseLine."No.");
        ItemJournalLine.SetRange("Item No.", PurchaseLine."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Unit Cost (Revalued)", Item."Last Direct Cost");
        ItemJournalLine.TestField("Inventory Value (Revalued)", Round(Item."Last Direct Cost" * PurchaseLine.Quantity));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VarianceInValueEntryUsingItemWithStandardCost()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
    begin
        // Verify Variance entry from Value Entry using Item with Standard Cost.

        // Setup: Create and Receive Purchase Invoice, Create and Ship Service Order.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::Invoice, Vendor."No.",
          CreateItem(Item."Costing Method"::Standard, Item."Order Tracking Policy"::None), LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Create and post Service Order.
        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Item.Get(PurchaseLine."No.");
        UpdateItemCostInfo(Item);

        // Exercise: Create Service Credit Memo using Item with Standard Cost.
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Customer No.", Item."No.", PurchaseLine.Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        // Verify: Verify Variance entry from Value Entry using Item with Standard Cost.
        ValueEntry.SetRange("Item No.", ServiceLine."No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Variance);
        ValueEntry.FindFirst();
        Assert.AreEqual(ValueEntry."Cost Amount (Actual)", -Round(Item."Last Direct Cost" * PurchaseLine.Quantity), CostAmountMustBeSame);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntryLinesUsingAdjustment()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
    begin
        // Verify that there should be showing all value entries for Direct Cost, Variance, Service Shipment, Service Credit Memo and Adjustment.

        // Setup: Create and post Purchase Invoice, Create and Ship Service Order and Create Service Credit Memo.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::Invoice, Vendor."No.",
          CreateItem(Item."Costing Method"::Standard, Item."Order Tracking Policy"::None), LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Create and post Service Order.
        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        Item.Get(PurchaseLine."No.");
        UpdateItemCostInfo(Item);

        // Create Customer, Create and apply Service Credit Memo.
        LibrarySales.CreateCustomer(Customer);
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Customer No.", Item."No.", PurchaseLine.Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        FindItemLedgerEntry(ItemLedgerEntry, ServiceLine."No.", false);
        ModifyServiceLine(ServiceLine, ItemLedgerEntry."Entry No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(ServiceLine."No.", '');

        // Verify: Verify that there should be showing all value entries for Direct Cost, Variance, Service Shipment, Service Credit Memo and Adjustment.
        VerifyValueEntryLines(
          ValueEntry, ServiceLine."No.", ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Document Type"::"Purchase Invoice", false);
        VerifyValueEntryLines(
          ValueEntry, ServiceLine."No.", ValueEntry."Entry Type"::Variance, ValueEntry."Document Type"::"Purchase Invoice", false);
        VerifyValueEntryLines(
          ValueEntry, ServiceLine."No.", ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Document Type"::"Service Shipment", false);
        VerifyValueEntryLines(
          ValueEntry, ServiceLine."No.", ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Document Type"::"Service Credit Memo", false);
        VerifyValueEntryLines(
          ValueEntry, ServiceLine."No.", ValueEntry."Entry Type"::"Direct Cost", ValueEntry."Document Type"::"Service Credit Memo", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWithCreditMemoUsingCloseInventoryPeriod()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Vendor: Record Vendor;
        InventoryPeriod: Record "Inventory Period";
    begin
        // Verify Close Inventory Period error.

        // Setup: Create and Receive Purchase Order, Create and Ship Service Order.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::Order, Vendor."No.",
          CreateItem(Item."Costing Method"::Standard, Item."Order Tracking Policy"::None), LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Create and post Service Order.
        CreateAndUpdateServiceLine(ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Exercise.
        asserterror CloseInventoryPeriod(InventoryPeriod, ServiceLine."No.", false);

        // Verify: Verify Close Invetory Period error.
        Assert.ExpectedError(StrSubstNo(CloseInventoryPeriodError));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustmentUsingItemJournal()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNo: Code[20];
    begin
        // Verify Item Ledger Entry for Positive and Negative Adjustment and Item Application Entry.

        // Setup: Create Item and Item Journal Line for Positive and Negative Adjustment.
        Initialize();
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        ItemNo := CreateItem(Item."Costing Method"::Average, Item."Order Tracking Policy"::None);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandIntInRange(50, 100));
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine2, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine2."Entry Type"::"Negative Adjmt.", ItemNo, LibraryRandom.RandInt(50));

        // Exercise.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Verify: Verify Item Ledger Entry for Positive and Negative Adjustment and Item Application Entry.
        VerifyItemLedgerCostAmount(
          ItemLedgerEntry, ItemNo, ItemJournalLine.Quantity, Round(ItemJournalLine.Quantity * ItemJournalLine."Unit Cost"), true);
        VerifyItemLedgerCostAmount(
          ItemLedgerEntry, ItemNo, -ItemJournalLine2.Quantity, -Round(ItemJournalLine2.Quantity * ItemJournalLine2."Unit Cost"), false);
        VerifyItemApplicationEntry(ItemLedgerEntry."Entry No.", -ItemJournalLine2.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesUsingItemJournal()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
        ValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        // Verify Adjusted Cost Amount in Value Entry.

        // Setup: Create Item and Item Journal Line for Positive and Negative Adjustment.
        Initialize();
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        ItemNo := CreateItem(Item."Costing Method"::Average, Item."Order Tracking Policy"::None);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandIntInRange(50, 100));
        ModifyItemJournalLine(ItemJournalLine);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine2, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine2."Entry Type"::"Negative Adjmt.", ItemNo, LibraryRandom.RandInt(50));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Exercise:
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');  // Using blank value for Item Category.

        // Verify: Verify Adjusted Cost Amount in Value Entry.
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange(Adjustment, true);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Actual)", Round(ValueEntry."Valued Quantity" * ValueEntry."Cost per Unit"));
    end;

    [Test]
    [HandlerFunctions('ViewAppliedEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplicationWorksheetUsingItemJournal()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ApplicationWorksheet: TestPage "Application Worksheet";
    begin
        // Verify Applied Quantity on View Applied Entries page.

        // Setup: Create Item, post Item Journal Line for Positive and Negative Adjustment and open Application Worksheet page.
        Initialize();
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        GlobalItemNo := CreateItem(Item."Costing Method"::Average, Item."Order Tracking Policy"::None);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", GlobalItemNo, LibraryRandom.RandInt(50));  // Taking Random Quantity.

        ModifyItemJournalLine(ItemJournalLine);
        LibraryVariableStorage.Enqueue(-ItemJournalLine.Quantity);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Negative Adjmt.", GlobalItemNo, ItemJournalLine.Quantity);  // Taking Random Quantity.
        GlobalQuantity := -ItemJournalLine.Quantity;
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ApplicationWorksheet.OpenEdit();
        ApplicationWorksheet.FILTER.SetFilter("Item No.", GlobalItemNo);

        // Exercise: Open View Applied Entres page.
        ApplicationWorksheet.AppliedEntries.Invoke();

        // Verify: Verification done in 'ViewAppliedEntriesPageHandler' page handler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostValueEntryToGLWithZeroSalesCost()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // Post Value Entry to G/L is correct with Zero Cost - Sales and Verify Item in Post Value Entry To G/L.

        // Setup: Create Item Journal for Positive Entry, Make Sales Order Post as Ship and Update Unit Cost with 0 value.Again Post same Order as Invoice.
        Initialize();
        UpdateInventorySetup(false, false, "Average Cost Calculation Type"::Item);
        ItemNo := SetupProductionItem(Item."Costing Method"::FIFO, Item."Replenishment System"::Purchase, 0);  // Using 0 for Standard Cost.
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateSalesOrder(SalesLine, ItemJournalLine."Item No.", ItemJournalLine.Quantity);
        PostSalesDocument(SalesLine, true, false);  // FALSE for Invoice.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        UpdateUnitCostOnSalesLine(SalesLine, 0);  // Using 0 for UnitCostLCY.

        // Post  Sales Order as Invoice and Run Adjust Cost Item Entries Batch Job.
        PostSalesDocument(SalesLine, false, true);  // TRUE for Invoice.
        LibraryCosting.AdjustCostItemEntries(ItemJournalLine."Item No.", '');

        // Exercise: Run Post Inventory Cost to G/L Report.
        LibraryVariableStorage.Enqueue(ValueEntriesWerePostedTxt);
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify: Verify Post Value Entry To G/L should not exist any entry for given Item.
        PostValueEntryToGL.SetRange("Item No.", ItemJournalLine."Item No.");
        Assert.RecordIsEmpty(PostValueEntryToGL);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemUnitCostUsingRevaluationJournal()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // Verify Unit Cost on the Item Card with Unit Cost (Calculated) on Revaluation Journal.

        Initialize();

        LibraryInventory.SetAverageCostSetup("Average Cost Calculation Type"::Item, AverageCostPeriod::Day);

        // Setup: Create and Receive Purchase Order.
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem(Item."Costing Method"::Average, Item."Order Tracking Policy"::None), LibraryRandom.RandDec(10, 2),
          true);  // Using Random value for Quantity.

        // Create Sales Order and run Adjust Cost Item Entries batch job.
        CreateSalesOrder(SalesLine, PurchaseLine."No.", PurchaseLine.Quantity);
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');

        // Exercise.
        CreateItemJournalForRevaluation(ItemJournalLine, PurchaseLine."No.");

        // Verify: Verify Unit Cost on the Item Card with Unit Cost (Calculated) on Revaluation Journal.
        Item.Get(PurchaseLine."No.");
        ItemJournalLine.SetRange("Item No.", PurchaseLine."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Unit Cost (Calculated)", Item."Unit Cost");
        ItemJournalLine.TestField("Inventory Value (Revalued)", Round(Item."Unit Cost" * PurchaseLine.Quantity));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReclassJournalUsingNewLocationCode()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        InventorySetup: Record "Inventory Setup";
        ReclassificationItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Applies-to Entry Reclassification Journal and Invoiced Quantity must be same as Item Ledger Entry.

        // Setup: Update Inventory Setup, create Reclassification Journal Line for Positive and Negative Adjustment and find Item Ledger Entry.
        Initialize();
        InventorySetup.Get();
        UpdateInventorySetup(true, true, "Average Cost Calculation Type"::"Item & Location & Variant");
        ReclassificationJournalUsingAdjustment(ReclassificationItemJournalLine);
        FindItemLedgerEntry(ItemLedgerEntry, ReclassificationItemJournalLine."Item No.", false);

        // Exercise: Apply Reclassification Journal Line with Item Ledger Entry.
        ReclassificationItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ReclassificationItemJournalLine.Modify(true);
        LibraryCosting.AdjustCostItemEntries(ReclassificationItemJournalLine."Item No.", '');

        // Verify: Verify Applies-to Entry on Reclassification Journal must be same as Item Ledger Entry.
        ReclassificationItemJournalLine.TestField("Applies-to Entry", ItemLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinePageHandler')]
    [Scope('OnPrem')]
    procedure CostAmountExpectedWithPartialSalesReturnOrder()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Cost Amount Expected is reversed when Sales Return Order is not fully Invoiced using Get Posted Document Lines To Reverse.

        // Setup: Create and post Purchase Order, Sales Order.Create and post Sales Return Order with partial Quantity.
        Initialize();

        UpdateInventorySetup(false, true, "Average Cost Calculation Type"::Item);
        CreateAndPostPurchaseDocument(
          PurchaseLine, CreateItem(Item."Costing Method"::Average, Item."Order Tracking Policy"::None), LibraryRandom.RandDec(100, 2),
          true);  // Using Random value for Quantity.
        CreateAndPostSalesOrder(SalesHeader, PurchaseLine."No.", PurchaseLine.Quantity / 2);  // Sale Partial Quantity.
        CreatePostSalesReturnOrderShipOnly(SalesLine, SalesHeader."Sell-to Customer No.");
        PostPartialSales(SalesLine);

        // Exercise:
        LibraryCosting.AdjustCostItemEntries(SalesLine."No.", '');

        // Verify: Verify Reversed Cost Amount Expected on Item Ledger Entry.
        Item.Get(SalesLine."No.");
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Return Receipt");
        FindItemLedgerEntry(ItemLedgerEntry, SalesLine."No.", true);
        ItemLedgerEntry.CalcFields("Cost Amount (Expected)");
        Assert.AreNearlyEqual(
          ItemLedgerEntry."Cost Amount (Expected)", Round(Item."Last Direct Cost" * SalesLine."Qty. to Invoice"),
          LibraryERM.GetAmountRoundingPrecision(), ValueNotMatchedError);
    end;

    [Test]
    [HandlerFunctions('SuggestSalesPriceOnWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceWithCreatedNewPricesFalse()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        CustomerPriceGroup: Code[10];
        ItemNo: Code[20];
        UnitPrice: Decimal;
    begin
        // Verify Suggest Sales Price on Worksheet function with Create New Prices FALSE.

        // Setup: Create Items, Customer Price Group ,Sales Prices and using Random value for Unit Price.
        Initialize();
        ItemNo := CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None);
        UnitPrice := LibraryRandom.RandDec(100, 1);
        CustomerPriceGroup := CreateCustomerPriceGroup();
        SetupSuggestSalesPrice(SalesPrice, CustomerPriceGroup, CustomerPriceGroup, 0, ItemNo, WorkDate(), false, UnitPrice);  // Using 0 for Random date not required.

        // Verify: Verify Sales Price Worksheet.
        VerifySalesPriceWorksheet(SalesPrice, SalesPrice."Starting Date", ItemNo, SalesPrice."Sales Code", UnitPrice, UnitPrice);
        VerifySalesPriceWorksheet(
          SalesPrice, SalesPrice."Starting Date", SalesPrice."Item No.", SalesPrice."Sales Code", SalesPrice."Unit Price",
          SalesPrice."Unit Price");
    end;

    [Test]
    [HandlerFunctions('SuggestSalesPriceOnWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceWithDifferentEndingDate()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        SalesPriceWorksheet: Record "Sales Price Worksheet";
        ItemNo: Code[20];
        CustomerPriceGroup: Code[10];
        UnitPrice: Decimal;
    begin
        // Verify Suggest Sales Price not Created if New Prices FALSE and apply Filter with different Ending Date.

        // Setup: Create Items, Customer Price Group ,Sales Prices and using Random value for Unit Price.
        Initialize();
        ItemNo := CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None);
        UnitPrice := LibraryRandom.RandDec(100, 1);
        CustomerPriceGroup := CreateCustomerPriceGroup();
        SetupSuggestSalesPrice(
          SalesPrice, CustomerPriceGroup, CustomerPriceGroup, LibraryRandom.RandInt(5), ItemNo, WorkDate(), false, UnitPrice);  // Calculate Random value to Calculate Ending Date.

        // Exercise: Run Suggest Sales Price on Worksheet.
        asserterror SalesPriceWorksheet.Get(
            SalesPrice."Starting Date", SalesPrice."Ending Date", SalesPrice."Sales Type", SalesPrice."Sales Code", '', ItemNo, '',
            SalesPrice."Unit of Measure Code", 0);  // 0 for Minimum Amount.

        // Verify: Verify Sales Price Worksheet Error.
        Assert.ExpectedErrorCannotFind(Database::"Sales Price Worksheet");
    end;

    [Test]
    [HandlerFunctions('SuggestSalesPriceOnWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceWithCreatedNewPricesTrue()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        CustomerPriceGroup: Code[10];
        CustomerPriceGroup2: Code[10];
        ItemNo: Code[20];
        StartingDate: Date;
        UnitPrice: Decimal;
    begin
        // Verify Suggest Sales Price on Worksheet function with Create New Prices TRUE.

        // Setup: Create Items, Customer Price Group ,Sales Prices and using Random value for Unit Price.
        Initialize();
        ItemNo := CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None);
        UnitPrice := LibraryRandom.RandDec(100, 1);
        CustomerPriceGroup := CreateCustomerPriceGroup();
        CustomerPriceGroup2 := CreateCustomerPriceGroup();
        StartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());  // Calculate Random Starting Date.
        SetupSuggestSalesPrice(SalesPrice, CustomerPriceGroup, CustomerPriceGroup2, 0, ItemNo, StartingDate, true, UnitPrice);  // Using 0 for Random date not required.

        // Verify: Verify Sales Price Worksheet.
        VerifySalesPriceWorksheet(SalesPrice, WorkDate(), ItemNo, CustomerPriceGroup2, 0, UnitPrice);
        VerifySalesPriceWorksheet(SalesPrice, WorkDate(), SalesPrice."Item No.", CustomerPriceGroup2, 0, SalesPrice."Unit Price");
    end;

    [Test]
    [HandlerFunctions('SuggestSalesPriceOnWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceWithNewPricesTrueAndDifferentCustomePriceGroup()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        CustomerPriceGroup: Code[10];
        CustomerPriceGroup2: Code[10];
        ItemNo: Code[20];
        StartingDate: Date;
        UnitPrice: Decimal;
    begin
        // Verify Suggest Sales Price not Created if New Prices TRUE and apply Filter with different Customer Price Group.

        // Setup: Create Items, Customer Price Group ,Sales Prices and using Random value for Unit Price.
        Initialize();
        ItemNo := CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None);
        UnitPrice := LibraryRandom.RandDec(100, 1);
        CustomerPriceGroup := CreateCustomerPriceGroup();
        CustomerPriceGroup2 := CreateCustomerPriceGroup();

        StartingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());  // Calculate Random Starting Date.
        SetupSuggestSalesPrice(SalesPrice, CustomerPriceGroup, CustomerPriceGroup2, 0, ItemNo, StartingDate, true, UnitPrice);  // Using 0 for Random date not required.

        // Exercise: Run Suggest Sales Price on Worksheet.
        asserterror VerifySalesPriceWorksheet(SalesPrice, WorkDate(), ItemNo, CustomerPriceGroup, 0, UnitPrice);

        // Verify: Verify Sales Price Worksheet Error.
        Assert.ExpectedErrorCannotFind(Database::"Sales Price Worksheet");
    end;

    [Test]
    [HandlerFunctions('SalesListPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithDropShptAndSpclOrder()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesPrice: Record "Sales Price";
        SalesLine: Record "Sales Line";
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        SalesHeader: Record "Sales Header";
        SalesLineDiscount: Record "Sales Line Discount";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader1: Record "Purchase Header";
        PriceListLine: Record "Price List Line";
        LineDicountPct: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify Line Discount and Unit Price on posted Sales Invoice created from Drop Shipment and Special Order.
        Initialize();
        PriceListLine.DeleteAll();

        // Setup: Create Item, create Vendor, Customer and update Line Discount, Unit Price.
        Item.Get(CreateAndUpdateItem(CreateVendor()));
        LibrarySales.CreateCustomer(Customer);

        // Use random for Unit Price and Minimum Quantity.
        CreateAndUpdateSalesPrice(
          SalesPrice, "Sales Price Type"::Customer, Customer."No.", Item."No.", Item."Base Unit of Measure", WorkDate(), WorkDate(),
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        LineDicountPct := LibraryRandom.RandDec(10, 2);  // Take random for Line Discount Pct.
        CreateLineDiscForCustomer(SalesPrice, LineDicountPct);
        CreateAndUpdatePurchasePrice(PurchasePrice, Item."Vendor No.", Item."No.");
        CreateLineDiscForVendor(PurchasePrice);

        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // Create Sales Order with Drop Shipment and Special Order, Get Sales Order On Requisition Worksheet and Carry Out Action Msg.
        CreateAndUpdateSalesLine(
          SalesHeader, Item."No.", Customer."No.", SalesPrice."Minimum Quantity" + LibraryRandom.RandDec(10, 2));  // Take Quantity more than Minimum Quantity.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        GetSalesOrderOnReqWkshtAndCarryOutActionMsg(Item."No.");

        // Receive Purchase Order.
        PurchaseHeader.SetRange("Buy-from Vendor No.", Item."Vendor No.");
        PurchaseHeader.FindFirst();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Get Drop Shipment order in new Purchase Order.
        // because it's not allowed to get both Special Order and Drop Shipment in single Purchase Order,
        CreatePurchaseHeader(PurchaseHeader1, PurchaseHeader1."Document Type"::Order, Item."Vendor No.");
        PurchaseHeader1.Validate("Sell-to Customer No.", Customer."No.");
        PurchaseHeader1.Modify(true);
        LibraryPurchase.GetDropShipment(PurchaseHeader1);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader1, true, false);

        // Exercise: Post Sales Order.
        DocumentNo := PostSalesDocument(SalesLine, true, true);

        // Verify: Verify Line Discount and Unit Price On Posted Sales Invoice Line.
        VerifySalesInvoiceLine(DocumentNo, true, SalesPrice."Unit Price", LineDicountPct);
        VerifySalesInvoiceLine(DocumentNo, false, SalesPrice."Unit Price", LineDicountPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAdjustmentOfNegativeEntryWithBothExpectedAndActualCosts()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnPurchaseHeader: Record "Purchase Header";
        ReturnPurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Adjust Cost] [Purchase] [Order] [Return Order] [Expected Cost]
        // [SCENARIO 304178] Total cost (actual + expected cost) of partially invoiced purchase return matches the total cost of the purchase order it is applied to.
        Initialize();

        // [GIVEN] Item with "FIFO" costing method.
        Item.Get(CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None));

        // [GIVEN] Purchase order. Quantity = 10, "Direct Unit Cost" = 5.0
        // [GIVEN] Post the purchase receipt.
        Qty := LibraryRandom.RandIntInRange(10, 20);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", true);

        // [GIVEN] Purchase return order. Quantity = 10, "Direct Unit Cost" = 4.0.
        // [GIVEN] Apply the purchase line to the posted receipt.
        // [GIVEN] Post the purchase return shipment.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          ReturnPurchaseHeader, ReturnPurchaseLine, ReturnPurchaseHeader."Document Type"::"Return Order", '', Item."No.", Qty, '', WorkDate());
        ReturnPurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        ReturnPurchaseLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReturnPurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(ReturnPurchaseHeader, true, false);

        // [GIVEN] Reopen the purchase order and set "Qty. to Invoice" = 7, "Direct Unit Cost" to 4.0.
        // [GIVEN] Invoice the purchase order.
        PurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        UpdateUnitCostAndQtyToInvoiceOnPurchLine(
          PurchaseLine, LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandInt(Qty - 1));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Reopen the purchase return order and set "Qty. to Invoice" = 6, "Direct Unit Cost" = 7.0.
        // [GIVEN] Invoice the purchase return.
        ReturnPurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(ReturnPurchaseHeader);
        UpdateUnitCostAndQtyToInvoiceOnPurchLine(
          ReturnPurchaseLine, LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandInt(Qty - 1));
        LibraryPurchase.PostPurchaseDocument(ReturnPurchaseHeader, false, true);

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] The sum of expected and actual cost is 3 * 5.0 + 7 * 4.0 = 43.0.
        // [THEN] This matches the sum of expected and actual cost of the purchase return.
        VerifyPairedItemLedgerEntriesAmount(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAdjustmentHandlesExpectedCostFirst()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnPurchaseHeader: Record "Purchase Header";
        ReturnPurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Adjust Cost] [Purchase] [Order] [Return Order] [Expected Cost]
        // [SCENARIO 304178] Adjust Cost batch job handles value entries for expected cost before ones for actual cost.
        Initialize();

        // [GIVEN] Item with "FIFO" costing method.
        Item.Get(CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None));

        // [GIVEN] Purchase order. Quantity = 10, "Direct Unit Cost" = 5.0
        // [GIVEN] Post the purchase receipt.
        Qty := LibraryRandom.RandIntInRange(10, 20);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", true);

        // [GIVEN] Purchase return order. Quantity = 10, "Direct Unit Cost" = 4.0.
        // [GIVEN] Apply the purchase line to the posted receipt.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          ReturnPurchaseHeader, ReturnPurchaseLine, ReturnPurchaseHeader."Document Type"::"Return Order", '', Item."No.", Qty, '', WorkDate());
        ReturnPurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        ReturnPurchaseLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReturnPurchaseLine.Modify(true);

        // [GIVEN] Set "Invoice No." and "Return Shipment No." so that the number of invoice goes alphabetically before the number of return shipment.
        ReturnPurchaseHeader.Validate("Posting No. Series", '');
        ReturnPurchaseHeader.Validate("Posting No.", LibraryUtility.GenerateGUID());
        ReturnPurchaseHeader.Validate("Return Shipment No. Series", '');
        ReturnPurchaseHeader.Validate("Return Shipment No.", LibraryUtility.GenerateGUID());
        ReturnPurchaseHeader.Modify(true);

        // [GIVEN] Post the purchase return shipment.
        LibraryPurchase.PostPurchaseDocument(ReturnPurchaseHeader, true, false);

        // [GIVEN] Reopen the purchase order and set "Qty. to Invoice" = 7, "Direct Unit Cost" to 4.0.
        // [GIVEN] Invoice the purchase order.
        PurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        UpdateUnitCostAndQtyToInvoiceOnPurchLine(
          PurchaseLine, LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandInt(Qty - 1));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Reopen the purchase return order and set "Qty. to Invoice" = 6, "Direct Unit Cost" = 7.0.
        // [GIVEN] Invoice the purchase return.
        ReturnPurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(ReturnPurchaseHeader);
        UpdateUnitCostAndQtyToInvoiceOnPurchLine(
          ReturnPurchaseLine, LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandInt(Qty - 1));
        LibraryPurchase.PostPurchaseDocument(ReturnPurchaseHeader, false, true);

        // [WHEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] The sum of expected and actual cost is 3 * 5.0 + 7 * 4.0 = 43.0.
        // [THEN] This matches the sum of expected and actual cost of the purchase return.
        VerifyPairedItemLedgerEntriesAmount(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAdjustmentAfterLastAccoutingPeriod()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InventorySetup: Record "Inventory Setup";
        AccountingPeriod: Record "Accounting Period";
        Qty: Decimal;
    begin
        // [FEATURE] [Adjust Cost] [Purchase] [Sales] [Order] [Expected Cost]
        Initialize();

        // [GIVEN] Inventory Setup -> Automatic Cost Adjustment = Always and Costing Period as Accounting Period
        InventorySetup.FindFirst();
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Always;
        InventorySetup."Average Cost Period" := InventorySetup."Average Cost Period"::"Accounting Period";
        InventorySetup.Modify();
        if not AccountingPeriod.FindLast() then begin
            CreateAccountingPeriod();
            AccountingPeriod.FindLast();
        end;

        // [GIVEN] Item with "Average" costing method.
        Item.Get(CreateItem(Item."Costing Method"::Average, Item."Order Tracking Policy"::None));

        // [GIVEN] Sales Order. Quantity = 10, "Unit Cost" = 4.0.
        // [GIVEN] Post the Sales Order
        Qty := LibraryRandom.RandIntInRange(10, 20);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());
        SalesHeader.Validate("Posting Date", CalcDate('<2D>', AccountingPeriod."Starting Date"));
        SalesHeader.Modify(true);
        SalesLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Purchase Order. Quantity = 10, "Direct Unit Cost" = 5.0
        // [GIVEN] Post the purchase receipt.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());
        PurchaseHeader.Validate("Posting Date", CalcDate('<2D>', AccountingPeriod."Starting Date"));
        PurchaseHeader.Modify();
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] The sum of expected and actual cost is 3 * 5.0 + 7 * 4.0 = 43.0.
        // [THEN] This matches the sum of expected and actual cost.
        VerifyPairedItemLedgerEntriesAmount(Item."No.");
    end;

    [Test]
    [HandlerFunctions('SuggestSalesPriceOnWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceWithDifferentCustomePriceGroup()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerPriceGroup2: Record "Customer Price Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATBusinessPostingGroup2: Record "VAT Business Posting Group";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales Price]
        // [SCENARIO 382762] Suggested Sales Prices inherit target Customer Price Group
        Initialize();

        // [GIVEN] Created two Customer Price Groups with different "Allow Invoice Disc.", "Allow Line Disc.", "Price Includes VAT", "VAT Bus. Posting Gr. (Price)"
        ItemNo := CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup2);
        CreateCustomCustomerPriceGroup(CustomerPriceGroup, true, true, true, VATBusinessPostingGroup.Code);
        CreateCustomCustomerPriceGroup(CustomerPriceGroup2, false, false, false, VATBusinessPostingGroup2.Code);

        // [WHEN] Run Suggest Sales Price on Worksheet from "Customer Price Group 1" to "Customer Price Group 2"
        SetupSuggestSalesPrice(
          SalesPrice, CustomerPriceGroup.Code, CustomerPriceGroup2.Code, 0, ItemNo, WorkDate(), true, LibraryRandom.RandDec(100, 1));

        // [THEN] "Allow Invoice Disc.", "Allow Line Disc.", "Price Includes VAT", "VAT Bus. Posting Gr. (Price)" are the same as in "Customer Price Group 2"
        VerifyCustomerPriceGroupFieldsOnSalesPriceWorksheet(
          SalesPrice, WorkDate(), ItemNo, CustomerPriceGroup2.Code,
          CustomerPriceGroup2."Allow Invoice Disc.", CustomerPriceGroup2."Allow Line Disc.",
          CustomerPriceGroup2."Price Includes VAT", CustomerPriceGroup2."VAT Bus. Posting Gr. (Price)");
    end;

    [Test]
    procedure CostAdjustmentCompletelyCorrectsSalesPostedInTwoIterations()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Adjust Cost] [Purchase] [Sales] [Item Charge] [Invoice]
        // [SCENARIO 391553] Cost adjustment takes into consideration all value entries for a sales order posted in two iterations.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] FIFO item.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Modify(true);

        // [GIVEN] Receive and invoice purchase order for 10 pcs. Posted purchase receipt = "R".
        CreateAndPostPurchaseDocument(PurchaseLine, Item."No.", Qty, true);
        FindPurchRcptLine(PurchRcptLine, PurchaseLine);

        // [GIVEN] Create sales order for 10 pcs.
        // [GIVEN] Post the shipment.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Post the invoice in two iterations, 5 pcs each.
        PostPartialSales(SalesLine);
        PostPartialSales(SalesLine);

        // [GIVEN] Create and post purchase invoice with item charge assigned to the receipt "R".
        CreateAndPostPurchInvoiceWithItemCharge(PurchRcptLine);

        // [GIVEN] Run the cost adjustment.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [GIVEN] Create and post one more purchase invoice with item charge assigned to the receipt "R".
        CreateAndPostPurchInvoiceWithItemCharge(PurchRcptLine);

        // [WHEN] Run the cost adjustment again.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] The item is fully adjusted - the sum of actual and expected cost amount = 0.
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Expected)");
        ValueEntry.TestField("Cost Amount (Actual)", 0);
        ValueEntry.TestField("Cost Amount (Expected)", 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Costing Orders");
        // Clear Global variables.
        GlobalItemNo := '';
        GlobalVendorNo := '';
        GlobalQuantity := 0;
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Costing Orders");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Costing Orders");
    end;

    local procedure CreateAccountingPeriod()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.GetFiscalYearStartDate(WorkDate()) = 0D then begin
            AccountingPeriod.Init();
            AccountingPeriod."Starting Date" := CalcDate('<-CY>', WorkDate());
            AccountingPeriod."New Fiscal Year" := true;
            AccountingPeriod.Insert();
        end;
    end;

    local procedure CreateCustomCustomerPriceGroup(var CustomerPriceGroup: Record "Customer Price Group"; AllowInvDisc: Boolean; AllowLineDisc: Boolean; PriceInclVAT: Boolean; VATBusPostGroup: Code[20])
    begin
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPriceGroup.Validate("Allow Invoice Disc.", AllowInvDisc);
        CustomerPriceGroup.Validate("Allow Line Disc.", AllowLineDisc);
        CustomerPriceGroup.Validate("Price Includes VAT", PriceInclVAT);
        CustomerPriceGroup.Validate("VAT Bus. Posting Gr. (Price)", VATBusPostGroup);
        CustomerPriceGroup.Modify(true);
    end;

    local procedure VerifyCustomerPriceGroupFieldsOnSalesPriceWorksheet(SalesPrice: Record "Sales Price"; StartingDate: Date; ItemNo: Code[20]; SalesCode: Code[20]; AllowInvDisc: Boolean; AllowLineDisc: Boolean; PriceInclVAT: Boolean; VATBusPostGroup: Code[20])
    var
        SalesPriceWorksheet: Record "Sales Price Worksheet";
    begin
        SalesPriceWorksheet.Get(
          StartingDate, SalesPrice."Ending Date", SalesPrice."Sales Type", SalesCode, SalesPrice."Currency Code", ItemNo,
          SalesPrice."Variant Code", SalesPrice."Unit of Measure Code", SalesPrice."Minimum Quantity");
        SalesPriceWorksheet.TestField("Allow Invoice Disc.", AllowInvDisc);
        SalesPriceWorksheet.TestField("Allow Line Disc.", AllowLineDisc);
        SalesPriceWorksheet.TestField("Price Includes VAT", PriceInclVAT);
        SalesPriceWorksheet.TestField("VAT Bus. Posting Gr. (Price)", VATBusPostGroup);
    end;

    local procedure CloseInventoryPeriod(var InventoryPeriod: Record "Inventory Period"; ItemNo: Code[20]; ReOpen: Boolean)
    var
        CloseInventoryPeriod: Codeunit "Close Inventory Period";
    begin
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');  // Using blank value for Item Category.
        LibraryInventory.CreateInventoryPeriod(InventoryPeriod, WorkDate());
        CloseInventoryPeriod.SetReOpen(ReOpen);
        CloseInventoryPeriod.SetHideDialog(true);
        CloseInventoryPeriod.Run(InventoryPeriod);
    end;

    local procedure CreateAndModifyLocation(var Location: Record Location; BaseCalendarCode: Code[10])
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Base Calendar Code", BaseCalendarCode);
        Evaluate(Location."Inbound Whse. Handling Time", '<' + Format(LibraryRandom.RandInt(5)) + 'D>');  // Random value is taken for Handling Time and 'D' is used for Day.
        Location.Validate("Outbound Whse. Handling Time", Location."Inbound Whse. Handling Time");
        Location.Modify(true);
    end;

    local procedure CreateAndUpdateSalesPrice(var SalesPrice: Record "Sales Price"; SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; ItemNo: Code[20]; BaseUnitOfMeasure: Code[10]; StartingDate: Date; EndingDate: Date; UnitPrice: Decimal; MinimumQuantity: Decimal)
    begin
        LibraryCosting.CreateSalesPrice(SalesPrice, SalesType, SalesCode, ItemNo, StartingDate, '', '', BaseUnitOfMeasure, MinimumQuantity);
        SalesPrice.Validate("Unit Price", UnitPrice);
        SalesPrice.Validate("Ending Date", EndingDate);
        SalesPrice.Modify(true);
    end;

    local procedure CreateAndUpdateSalesLine(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; CustomerNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLineWithPurchCode(SalesHeader, ItemNo, CreatePurchasingCode(true, false), Quantity);
        CreateSalesLineWithPurchCode(SalesHeader, ItemNo, CreatePurchasingCode(false, true), Quantity);
    end;

    local procedure CreateAndUpdateItem(VendorNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None));
        Item.Validate("Vendor No.", VendorNo);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndUpdatePurchasePrice(var PurchasePrice: Record "Purchase Price"; VendorNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryCosting.CreatePurchasePrice(PurchasePrice, VendorNo, ItemNo, WorkDate(), '', '', '', LibraryRandom.RandDec(10, 2));  // Use random for Minimum Quanity.
        PurchasePrice.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Use random for Direct Unit Cost.
        PurchasePrice.Modify(true);
    end;

    local procedure CreateBaseCalendarChange(var BaseCalendarChange: Record "Base Calendar Change"; BaseCalendarCode: Code[10]; Day: Option; Day2: Option)
    begin
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendarCode, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D, Day);  // '0D' is taken for blank date.
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendarCode, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D, Day2);  // '0D' is taken for blank date.
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomerPriceGroup(): Code[10]
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPriceGroup.Validate("Allow Invoice Disc.", true);
        CustomerPriceGroup.Validate("Allow Line Disc.", true);
        CustomerPriceGroup.Modify(true);
        exit(CustomerPriceGroup.Code);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, JournalTemplateName, JournalBatchName, EntryType, ItemNo, LibraryRandom.RandInt(100));  // Taking Random Quantity.
    end;

    local procedure CreateLineDiscForCustomer(SalesPrice: Record "Sales Price"; LineDiscountPct: Decimal)
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, SalesPrice."Item No.", SalesLineDiscount."Sales Type"::Customer,
          SalesPrice."Sales Code", WorkDate(), '', '', '', SalesPrice."Minimum Quantity");
        SalesLineDiscount.Validate("Line Discount %", LineDiscountPct);
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateLineDiscForVendor(PurchasePrice: Record "Purchase Price")
    var
        PurchaseLineDiscount: Record "Purchase Line Discount";
    begin
        LibraryERM.CreateLineDiscForVendor(
          PurchaseLineDiscount, PurchasePrice."Item No.", PurchasePrice."Vendor No.", WorkDate(), '', '', '', PurchasePrice."Minimum Quantity");
        PurchaseLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));  // Take random for Line Discount.
        PurchaseLineDiscount.Modify(true);
    end;

    local procedure CreateTransferOrderWithBaseCalendar(var TransferLine: Record "Transfer Line")
    var
        BaseCalendar: Record "Base Calendar";
        BaseCalendar2: Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryService.CreateBaseCalendar(BaseCalendar2);
        CreateBaseCalendarChange(BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange.Day::Saturday, BaseCalendarChange.Day::Sunday);
        CreateBaseCalendarChange(BaseCalendarChange, BaseCalendar2.Code, BaseCalendarChange.Day::Sunday, BaseCalendarChange.Day::Monday);
        CreateTransferOrderWithModifiedLocation(TransferLine, BaseCalendar.Code, BaseCalendar2.Code);
    end;

    local procedure CreateTransferOrderWithModifiedLocation(var TransferLine: Record "Transfer Line"; BaseCalendarCode: Code[10]; BaseCalendarCode2: Code[10])
    var
        Location: Record Location;
        Location2: Record Location;
    begin
        CreateAndModifyLocation(Location, BaseCalendarCode);
        CreateAndModifyLocation(Location2, BaseCalendarCode2);
        CreateTransferOrder(TransferLine, Location.Code, Location2.Code);
    end;

    local procedure CreateTransferOrder(var TransferLine: Record "Transfer Line"; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        Location: Record Location;
        TransferHeader: Record "Transfer Header";
    begin
        LibraryWarehouse.CreateInTransitLocation(Location);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationCode, LocationCode2, Location.Code);
        LibraryWarehouse.CreateTransferLine(
          TransferHeader, TransferLine, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));  // Random value taken for Quantity.
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Using Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchasingCode(DropShipment: Boolean; SpecialOrder: Boolean): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", DropShipment);
        Purchasing.Validate("Special Order", SpecialOrder);
        Purchasing.Modify(true);
        exit(Purchasing.Code);
    end;

    local procedure CreateItem(CostingMethod: Enum "Costing Method"; OrderTrackingPolicy: Enum "Order Tracking Policy"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemJournalForRevaluation(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        CreateRevaluationJournalBatch(ItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, WorkDate(), LibraryUtility.GetGlobalNoSeriesCode(), "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false);
    end;

    local procedure CreateAndUpdateServiceLine(var ServiceLine: Record "Service Line"; No: Code[20]; Quantity: Decimal)
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateServiceDocument(ServiceLine, ServiceHeader."Document Type"::Order, Customer."No.", No, Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        UpdateUnitCostOnSalesLine(SalesLine, LibraryRandom.RandDec(100, 1));  // Using Random for UnitCostLCY.
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20]; No: Code[20]; Quantity: Decimal)
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, No);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Cost.
        ServiceLine.Modify(true);
    end;

    local procedure CreateTrackedItem(LotNos: Code[20]; SerialNos: Code[20]; LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean; CostingMethod: Enum "Costing Method"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(Item, LotNos, SerialNos, FindItemTrackingCode(LotSpecificTracking, SerialNoSpecificTracking));
        Evaluate(Item."Expiration Calculation", '<' + Format(LibraryRandom.RandInt(5)) + 'D>'); // Using Random value for Expiration Calculation.
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; No: Code[20]; Quantity: Decimal; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Order, CreateVendor(), No, Quantity);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);
    end;

    local procedure CreateAndPostPurchInvoiceWithItemCharge(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt,
          PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; No: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesLine, No, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random value for Unit Price.
        SalesLine.Modify(true);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostSalesReturnOrderShipOnly(var SalesLine: Record "Sales Line"; SellToCustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SellToCustomerNo);
        SalesReturnOrderGetPostedDocumentLinesToReverse(SalesHeader."No.");
        FindAndUpdateSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    local procedure CreateRevaluationJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateSalesLineWithPurchCode(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; PurchasingCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure EnqueVariables(BaseUnitOfMeasure: Code[10]; CustomerPriceGroup: Code[10]; EndingDate: Date; NewPrices: Boolean)
    var
        SalesPrice: Record "Sales Price";
    begin
        LibraryVariableStorage.Enqueue(CustomerPriceGroup);  // Enque Customer Price Group
        LibraryVariableStorage.Enqueue(EndingDate); // EndingDate
        LibraryVariableStorage.Enqueue(NewPrices);  // New Price
        LibraryVariableStorage.Enqueue(SalesPrice."Sales Type"::"Customer Price Group");
        LibraryVariableStorage.Enqueue(WorkDate());  // StartDate
        LibraryVariableStorage.Enqueue(BaseUnitOfMeasure);
    end;

    local procedure FindAndUpdateSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetFilter(Type, '<>''''');
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        SalesLine.Modify(true);
    end;

    local procedure FindItemTrackingCode(LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.SetRange("Man. Expir. Date Entry Reqd.", false);
        ItemTrackingCode.SetRange("Lot Specific Tracking", LotSpecificTracking);
        ItemTrackingCode.SetRange("Lot Sales Inbound Tracking", LotSpecificTracking);
        ItemTrackingCode.SetRange("Lot Sales Outbound Tracking", LotSpecificTracking);
        ItemTrackingCode.SetRange("SN Specific Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.SetRange("SN Sales Inbound Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.SetRange("SN Sales Outbound Tracking", SerialNoSpecificTracking);
        ItemTrackingCode.FindFirst();
        exit(ItemTrackingCode.Code);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; Positive: Boolean)
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange(Positive, Positive);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line")
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure GetSalesOrderOnReqWkshtAndCarryOutActionMsg(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure ModifyServiceLine(var ServiceLine: Record "Service Line"; EntryNo: Integer)
    begin
        ServiceLine.Validate("Appl.-from Item Entry", EntryNo);
        ServiceLine.Modify(true);
    end;

    local procedure ModifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; EntryNo: Integer)
    begin
        PurchaseLine.Validate("Appl.-to Item Entry", EntryNo);
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));  // Taking Random Unit Cost.
        ItemJournalLine.Modify(true);
    end;

    local procedure OpenOrderTracking(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseOrderSubform: Page "Purchase Order Subform";
    begin
        PurchaseOrderSubform.SetRecord(PurchaseLine);
        PurchaseOrderSubform.ShowTracking();
    end;

    local procedure PostProductionJournal(var ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        ProductionJournalMgt.InitSetupValues();
        ProductionJournalMgt.SetTemplateAndBatchName();
        ProductionJournalMgt.CreateJnlLines(ProductionOrder, ProdOrderLine."Line No.");
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Document No.", ProductionOrder."No.");
        ItemJournalLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    local procedure PostPurchaseOrderWithItemTracking(var PurchaseLine: Record "Purchase Line"; LotNos: Code[20]; SerialNos: Code[20]; LotSpecificTracking: Boolean; SerialNoSpecificTracking: Boolean; ItemTrackingAction: Option; CostingMethod: Enum "Costing Method")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        GlobalItemNo := CreateTrackedItem(LotNos, SerialNos, LotSpecificTracking, SerialNoSpecificTracking, CostingMethod);  // Assign Item No. to global variable and blank value is taken for Serial No.
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, GlobalItemNo, LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        GlobalVendorNo := PurchaseHeader."Buy-from Vendor No.";
        FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.");
        GlobalItemTrackingAction := ItemTrackingAction;
        PurchaseLine.OpenItemTrackingLines();  // Assign Item Tracking on page handler.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure PostPartialSales(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Invoice", SalesLine.Quantity / 2);
        SalesLine.Modify(true);
        PostSalesDocument(SalesLine, false, true);  // Invoice partial Quantity.
    end;

    local procedure PostSalesDocument(SalesLine: Record "Sales Line"; Ship: Boolean; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice));
    end;

    local procedure ReclassificationJournalUsingAdjustment(var ReclassificationItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        Location: Record Location;
        ReclassificationItemJournalTemplate: Record "Item Journal Template";
        ReclassificationItemJournalBatch: Record "Item Journal Batch";
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // Use Random value for Quantity.
        Quantity := LibraryRandom.RandDec(100, 2);
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Transfer);
        ItemNo := CreateItem(Item."Costing Method"::Average, Item."Order Tracking Policy"::None);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemNo, Quantity + LibraryRandom.RandDec(10, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        LibraryWarehouse.CreateLocation(Location);
        SelectItemJournalBatch(ReclassificationItemJournalBatch, ReclassificationItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ReclassificationItemJournalLine, ReclassificationItemJournalBatch."Journal Template Name",
          ReclassificationItemJournalBatch.Name, ReclassificationItemJournalLine."Entry Type"::Transfer, ItemNo,
          -LibraryRandom.RandDec(10, 2));
        ReclassificationItemJournalLine.Validate("New Location Code", Location.Code);
        ReclassificationItemJournalLine.Modify(true);
    end;

    local procedure RunSuggestSalesPriceOnWkshReport(CustomerPriceGroup: Code[10]; StartingDate: Date; EndingDate: Date)
    var
        SalesPrice: Record "Sales Price";
        SuggestSalesPriceOnWksh: Report "Suggest Sales Price on Wksh.";
    begin
        Clear(SuggestSalesPriceOnWksh);
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", CustomerPriceGroup);
        SalesPrice.SetRange("Starting Date", StartingDate);
        SalesPrice.SetRange("Ending Date", EndingDate);
        SuggestSalesPriceOnWksh.SetTableView(SalesPrice);
        SuggestSalesPriceOnWksh.UseRequestPage(true);
        SuggestSalesPriceOnWksh.RunModal();
    end;

    local procedure SalesReturnOrderGetPostedDocumentLinesToReverse(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        Commit();
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure SetupApplyServiceDocument(var ServiceLine: Record "Service Line"; No: Code[20]; Quantity: Decimal)
    var
        ServiceHeader: Record "Service Header";
    begin
        CreateAndUpdateServiceLine(ServiceLine, No, Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        CreateServiceDocument(ServiceLine, ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Customer No.", No, Quantity);
    end;

    local procedure ServiceDocumentWithPurchaseOrder(var ServiceLine: Record "Service Line"; TrackingAction: Option; LotNos: Code[20]; LotSpecific: Boolean; SerialSpecific: Boolean; GlobalAction: Option)
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
    begin
        PostPurchaseOrderWithItemTracking(
          PurchaseLine, LotNos, LibraryUtility.GetGlobalNoSeriesCode(), LotSpecific, SerialSpecific, GlobalAction, Item."Costing Method"::FIFO);
        CreateAndUpdateServiceLine(ServiceLine, GlobalItemNo, PurchaseLine.Quantity);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        GlobalItemTrackingAction := TrackingAction;
    end;

    local procedure SetupProductionItem(CostingMethod: Enum "Costing Method"; ReplenishmentSystem: Enum "Replenishment System"; StandardCost: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem(CostingMethod, Item."Order Tracking Policy"::None));
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Standard Cost", StandardCost);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure SetupSuggestSalesPrice(var SalesPrice: Record "Sales Price"; CustomerPriceGroup: Code[10]; CustomerPriceGroup2: Code[10]; Range: Integer; ItemNo: Code[20]; StartingDate: Date; NewPrice: Boolean; UnitPrice: Decimal)
    var
        Item: Record Item;
        Item2: Record Item;
        SalesPriceWorksheet: Record "Sales Price Worksheet";
        EndingDate: Date;
    begin
        Item.Get(ItemNo);
        Item2.Get(CreateItem(Item."Costing Method"::FIFO, Item."Order Tracking Policy"::None));
        EndingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Calculate Random Ending Date.

        CreateAndUpdateSalesPrice(
          SalesPrice, "Sales Price Type"::"Customer Price Group", CustomerPriceGroup, Item."No.", Item."Base Unit of Measure",
          StartingDate, EndingDate, UnitPrice, 0);
        CreateAndUpdateSalesPrice(
          SalesPrice, "Sales Price Type"::"Customer Price Group", CustomerPriceGroup, Item2."No.", Item2."Base Unit of Measure",
          StartingDate, EndingDate, LibraryRandom.RandDec(100, 1), 0);
        SalesPriceWorksheet.DeleteAll();
        EnqueVariables(Item."Base Unit of Measure", CustomerPriceGroup2, CalcDate('<' + Format(Range) + 'M>', EndingDate), NewPrice);  // Calcualte Ending Date Parameter as different Tests required.
        Commit();

        // Exercise: Run Suggest Sales Price on Worksheet.
        RunSuggestSalesPriceOnWkshReport(CustomerPriceGroup, StartingDate, EndingDate);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure UpdateAddCurrencySetup(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UndoShipment(OrderNo: Code[20])
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        ServiceShipmentLine.FindFirst();
        LibraryService.UndoShipmentLinesByServiceDocNo(ServiceShipmentLine."Document No.");
    end;

    local procedure UpdateInventorySetup(AutomaticCostPosting: Boolean; ExpectedCostPostingtoGL: Boolean; AvgCostCalcType: Enum "Average Cost Calculation Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryInventory.SetAutomaticCostPosting(AutomaticCostPosting);
        LibraryInventory.SetExpectedCostPosting(ExpectedCostPostingtoGL);
        LibraryInventory.SetAverageCostSetup(AvgCostCalcType, InventorySetup."Average Cost Period"::Day);
    end;

    local procedure UpdateItemCostInfo(var Item: Record Item)
    var
        ItemCost: Decimal;
    begin
        ItemCost := LibraryRandom.RandInt(10); // Using Random value for all below used field.
        Item.Validate("Indirect Cost %", ItemCost);
        Item.Validate("Overhead Rate", ItemCost);
        Item.Validate("Standard Cost", ItemCost);
        Item.Modify(true);
    end;

    local procedure UpdateUnitCostOnSalesLine(var SalesLine: Record "Sales Line"; UnitCostLCY: Decimal)
    begin
        SalesLine.Validate("Unit Cost (LCY)", UnitCostLCY);
        SalesLine.Modify(true);
    end;

    local procedure UpdateUnitCostAndQtyToInvoiceOnPurchLine(var PurchaseLine: Record "Purchase Line"; DirectUnitCost: Decimal; QtyToInvoice: Decimal)
    begin
        PurchaseLine.Find();
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; Positive: Boolean; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo, Positive);
        ItemLedgerEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Cost Amount (Expected)", 0);
        ItemLedgerEntry.TestField("Cost Amount (Actual)", 0);
        ItemLedgerEntry.TestField("Cost Amount (Expected) (ACY)", 0);
        ItemLedgerEntry.TestField("Cost Amount (Actual) (ACY)", 0);
    end;

    local procedure VerifyPairedItemLedgerEntriesAmount(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalCost: Decimal;
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo, true);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
        TotalCost := ItemLedgerEntry."Cost Amount (Actual)" + ItemLedgerEntry."Cost Amount (Expected)";

        FindItemLedgerEntry(ItemLedgerEntry, ItemNo, false);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
        Assert.AreEqual(
          -TotalCost, ItemLedgerEntry."Cost Amount (Actual)" + ItemLedgerEntry."Cost Amount (Expected)",
          'Costs on inbound and applied outbound item entries do not match.');
    end;

    local procedure VerifyValueEntryLines(var ValueEntry: Record "Value Entry"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; DocumentType: Enum "Item Ledger Document Type"; Adjustment: Boolean)
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Entry Type", EntryType);
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange(Adjustment, Adjustment);
        ValueEntry.FindFirst();
    end;

    local procedure VerifyItemLedgerCostAmount(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; Quantity: Decimal; CostAmountActual: Decimal; Positive: Boolean)
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo, Positive);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    local procedure VerifyItemApplicationEntry(EntryNo: Integer; Quantity: Decimal)
    var
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        ItemApplicationEntry.SetRange("Item Ledger Entry No.", EntryNo);
        ItemApplicationEntry.SetRange("Cost Application", false);
        ItemApplicationEntry.FindFirst();
        ItemApplicationEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifySalesPriceWorksheet(SalesPrice: Record "Sales Price"; StartingDate: Date; ItemNo: Code[20]; SalesCode: Code[20]; CurrentUnitPrice: Decimal; NewUnitPrice: Decimal)
    var
        SalesPriceWorksheet: Record "Sales Price Worksheet";
    begin
        SalesPriceWorksheet.Get(
          StartingDate, SalesPrice."Ending Date", SalesPrice."Sales Type", SalesCode, SalesPrice."Currency Code", ItemNo,
          SalesPrice."Variant Code", SalesPrice."Unit of Measure Code", SalesPrice."Minimum Quantity");
        SalesPriceWorksheet.TestField("New Unit Price", NewUnitPrice);
        SalesPriceWorksheet.TestField("Current Unit Price", CurrentUnitPrice);
    end;

    local procedure VerifySalesInvoiceLine(DocumentNo: Code[20]; DropShipment: Boolean; UnitPrice: Decimal; LineDiscountPct: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("Drop Shipment", DropShipment);
        SalesInvoiceLine.FindFirst();

        SalesInvoiceLine.TestField("Unit Price", UnitPrice);
        SalesInvoiceLine.TestField("Line Discount %", LineDiscountPct);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        Commit();
        case GlobalItemTrackingAction of
            GlobalItemTrackingAction::SelectEntriesLotNo:
                ItemTrackingLines."Select Entries".Invoke();
            GlobalItemTrackingAction::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinePageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.PostedShipmentsBtn.SetValue('Posted Invoices');
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseLineTrackingPageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        OrderTracking."Item No.".AssertEquals(GlobalItemNo);
        OrderTracking."Total Quantity".AssertEquals(GlobalQuantity);
        OrderTracking.Quantity.AssertEquals(-GlobalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingPageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        OrderTracking."Untracked Quantity".AssertEquals(GlobalQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AutoReservUsingReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestSalesPriceOnWkshRequestPageHandler(var SuggestSalesPriceOnWksh: TestRequestPage "Suggest Sales Price on Wksh.")
    var
        CustomerPriceGroupCode: Variant;
        EndDate: Variant;
        NewPrices: Variant;
        SalesType: Variant;
        StartDate: Variant;
        UnitOfMeasureCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerPriceGroupCode);
        LibraryVariableStorage.Dequeue(EndDate);
        LibraryVariableStorage.Dequeue(NewPrices);
        LibraryVariableStorage.Dequeue(SalesType);
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(UnitOfMeasureCode);

        SuggestSalesPriceOnWksh.SalesType.SetValue(SalesType);
        SuggestSalesPriceOnWksh.SalesCodeCtrl.SetValue(CustomerPriceGroupCode);
        SuggestSalesPriceOnWksh.UnitOfMeasureCode.SetValue(UnitOfMeasureCode);
        SuggestSalesPriceOnWksh.ToStartDateCtrl.SetValue(StartDate);
        SuggestSalesPriceOnWksh.ToEndDateCtrl.SetValue(EndDate);
        SuggestSalesPriceOnWksh.CreateNewPrices.SetValue(NewPrices);
        SuggestSalesPriceOnWksh.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ViewAppliedEntriesPageHandler(var ViewAppliedEntries: TestPage "View Applied Entries")
    var
        AppliedQuantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(AppliedQuantity);
        ViewAppliedEntries.FILTER.SetFilter("Item No.", GlobalItemNo);
        ViewAppliedEntries."Invoiced Quantity".AssertEquals(GlobalQuantity);
        ViewAppliedEntries.ApplQty.AssertEquals(AppliedQuantity);
        ViewAppliedEntries.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue Variable.
        Assert.ExpectedMessage(ExpectedMessage, Question);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK().Invoke();
    end;
}
