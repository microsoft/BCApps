codeunit 137295 "SCM Inventory Misc. III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryJob: Codeunit "Library - Job";
        LibraryRandom: Codeunit "Library - Random";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo;
        isInitialized: Boolean;
        ChangeBaseUnitOfMeasureError: Label 'You cannot change Base Unit of Measure because there are one or more open ledger entries for this item.';
        CancelReservationMessage: Label 'Do you want to cancel all reservations in ';
        ClosedFiscalYear: Label 'Once the fiscal year is closed it cannot be opened again, and the periods in the fiscal year cannot be changed.';
        DeleteEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
        ExpectedMessage: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        JournalLinesRegistered: Label 'The journal lines were successfully registered.You are now in the ';
        FinishProductionOrder: Label 'Production Order %1 has not been finished:\\  * Some output is still missing.';
        PhysInvLedgerEntriesExists: Label 'Physical Inventory Ledger Entries Must Be Deleted.';
        ProdOrderCreated: Label 'Prod. Order';
        PostJournalLines: Label 'Do you want to post the journal lines';
        RegisterJournalLines: Label 'Do you want to register the journal lines?';
        SuccessfullyPostLines: Label 'The journal lines were successfully posted';
        ValidationError: Label '%1 must be %2.', Comment = '%1:Field1,%2:Value1';
        StandardCostRollup: Label 'The standard costs have been rolled up successfully.';
        UnadjustedValueEntriesMessage: Label 'Some unadjusted value entries will not be covered with the new setting. You must run the Adjust Cost - Item Entries batch job once to adjust these.';
        ItemFilter: Label '%1|%2', Locked = true;
        ProductionOrderCreatedMsg: Label 'Released Prod. Order';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        UsageNotLinkedToBlankLineTypeMsg: Label 'Usage will not be linked to the project planning line because the Line Type field is empty';
        ReasonCodeErr: Label 'Reason Code not matched.';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReserveQtyOnProdOrderFromSalesOrder()
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // Verify Quantity and Reserved Quantity on Planned Production Order Created from Sales Order.

        // Setup.
        Initialize();

        // Exercise: Create Sales Order, Planned Production order from Sales Order.
        CreateProdOrderFromSalesOrder(SalesLine, ProductionOrder.Status::Planned, "Create Production Order Type"::ItemOrder);

        // Verify: Verify Quantity and Reserved Quantity on Production Order.
        VerifyQuantityOnProdOrderLine(SalesLine."No.", SalesLine.Quantity, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReserveQtyErrorOnProdOrderFromSalesOrder()
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Verify error while Refresh Planned Production Order created from Sales Order.

        // Setup: Create Sales Order, Planned Production order from Sales Order.
        Initialize();
        CreateProdOrderFromSalesOrder(SalesLine, ProductionOrder.Status::Planned, "Create Production Order Type"::ItemOrder);
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Planned, SalesLine."No.");

        // Exercise: Refresh Production Order.
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify error while Refresh Planned Production Order.
        Assert.ExpectedTestFieldError(ProdOrderLine.FieldCaption("Reserved Qty. (Base)"), Format(0));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReserveQtyOnProdOrderAfterChangeStatus()
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // Verify Quantity and Reserved Quantity on Production Order created from Sales Order and after changing the Production Order status from Planned to Firm Planned.

        // Setup: Create Sales Order, Planned Production order from Sales Order.
        Initialize();
        CreateProdOrderFromSalesOrder(SalesLine, ProductionOrder.Status::Planned, "Create Production Order Type"::ItemOrder);
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Planned, SalesLine."No.");

        // Exercise: Change Status on Production Order.
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::"Firm Planned", WorkDate(), false);

        // Verify: Verify Quantity and Reserved Quantity on Production Order.
        VerifyQuantityOnProdOrderLine(SalesLine."No.", SalesLine.Quantity, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReserveQtyErrorOnProdOrderAfterChangeStatus()
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Verify error while Refresh Planned Production Order created from Sales Order and after changing the Production Order status from Planned to Firm Planned.

        // Setup: Create Sales Order, Planned Production order from Sales Order.
        Initialize();
        CreateProdOrderFromSalesOrder(SalesLine, ProductionOrder.Status::Planned, "Create Production Order Type"::ItemOrder);
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Planned, SalesLine."No.");

        // Change Status on Production Order.
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::"Firm Planned", WorkDate(), false);
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesLine."No.");

        // Exercise: Refresh Production Order.
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify error while Refresh Firm Planned Production Order.
        Assert.ExpectedTestFieldError(ProdOrderLine.FieldCaption("Reserved Qty. (Base)"), Format(0));
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderReservationCancel()
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // Verify Reserved Quantity on Production Order created from Sales Order after cancellation of reservation.

        // Setup: Create Sales Order, Firm Planned Production order from Sales Order.
        Initialize();
        CreateProdOrderFromSalesOrder(SalesLine, ProductionOrder.Status::"Firm Planned", "Create Production Order Type"::ItemOrder);

        // Exercise: Cancel reservation on Production Order.
        CancelReservationOnProductionOrder(SalesLine."No.");

        // Verify: Verify there is no Reserved Quantity on Production Order Line after cancellation of reservation
        VerifyQuantityOnProdOrderLine(SalesLine."No.", SalesLine.Quantity, 0);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderAutoReservation()
    var
        SalesLine: Record "Sales Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        ReservOption: Option AutoReserve,CancelReserv;
    begin
        // Verify Reserved Quantity on Production Order created from Sales Order after Auto Reservation.

        // Setup: Create Sales Order, Planned Production order from Sales Order and cancel reservation on Production Order.
        Initialize();
        CreateProdOrderFromSalesOrder(SalesLine, ProductionOrder.Status::"Firm Planned", "Create Production Order Type"::ItemOrder);
        CancelReservationOnProductionOrder(SalesLine."No.");
        FindProdOrderLine(ProdOrderLine, SalesLine."No.");
        LibraryVariableStorage.Enqueue(ReservOption::AutoReserve);  // Enqueue for ReservationPageHandler.

        // Exercise: Auto reservation on Production Order.
        ProdOrderLine.ShowReservation();

        // Verify: Verify Reserved Quantity on Production Order Line.
        VerifyQuantityOnProdOrderLine(SalesLine."No.", SalesLine.Quantity, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CheckProdOrderStatusPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReserveQtyOnProdOrderAfterUpdateQty()
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Verify Quantity on Production Order Line after creating Production Order from Sales Order and updating Quantity on Sales Line.

        // Setup: Create production Order from Sales Order, update Quantity on Sales Line.
        Initialize();
        CreateProdOrderFromSalesOrder(SalesLine, ProductionOrder.Status::Released, "Create Production Order Type"::ProjectOrder);
        Quantity := UpdateQuantityOnSalesLine(SalesLine);
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Released, SalesLine."Document No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(FinishProductionOrder, ProductionOrder."No."));  // Enqueue fo MessageHandler.

        // Exercise: Change Production Order Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify Quantity on Production Order Line.
        VerifyQuantityOnProdOrderLine(SalesLine."No.", Quantity, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPhysInvJournalAfterUpdateQty()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Item Ledger Entry when Qty. (Phys. Inventory) is updated for an Item with Overhead Cost and having costing method Average.

        // Setup: Create and post Purchase Order, run Adjust cost Item Entries, calculate Inventory and update "Qty. (Phys. Inventory)" on Physical Inventory Journal.
        Initialize();
        CreateAndPostPurchaseOrder(
          PurchaseLine, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::Average));
        LibraryCosting.AdjustCostItemEntries(PurchaseLine."No.", '');
        RunCalculateInventoryReport(ItemJournalLine, PurchaseLine."No.");
        UpdateQtyOnPhysInvJournal(ItemJournalLine);

        // Exercise: Post Physical Inventory Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify Quantity and Cost Amount (Actual) on Item Ledger Entry.
        VerifyItemLedgerEntry(
          ItemJournalLine."Item No.", ItemJournalLine."Entry Type"::"Negative Adjmt.", -ItemJournalLine.Quantity,
          -ItemJournalLine.Quantity * ItemJournalLine."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAmountOnItemLedgerEntry()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Verify Item Ledger Entry after posting Item Journal Line for Item having costing method Average.

        // Setup: Create and post Item Journal Line.
        Initialize();
        CreateAndPostItemJournalLine(
          ItemJournalLine, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::Average));
        Quantity := ItemJournalLine.Quantity;

        // Create Item Journal Line and apply to existing Item ledger Entry for Item.
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemJournalLine."Item No.", ItemJournalLine.Quantity / 2,
          ItemJournalLine."Unit Cost");
        UpdateItemJournalLineAppliesToEntry(ItemJournalLine);

        // Exercise: Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // verify: Verify Quantity and Cost Amount (Actual) on Item Ledger Entry.
        VerifyItemLedgerEntry(
          ItemJournalLine."Item No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, Quantity * ItemJournalLine."Unit Cost");
        VerifyItemLedgerEntry(
          ItemJournalLine."Item No.", ItemJournalLine."Entry Type"::"Negative Adjmt.", -ItemJournalLine.Quantity,
          -ItemJournalLine.Quantity * ItemJournalLine."Unit Cost");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesAfterPostInvCostToGL()
    var
        JobJournalLine: Record "Job Journal Line";
        GLEntry: Record "G/L Entry";
        Item: Record Item;
    begin
        // Verify G/L Entries after running Adjust Cost Item Entries and post Inventory to G/L batch job for an Item.

        // Setup: Create and post Job Journal Line and run Adjust Cost Item Entries.
        Initialize();
        CreateAndPostJobJournalLine(
          JobJournalLine,
          CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::Average), LibraryRandom.RandDec(10, 2));
        LibraryCosting.AdjustCostItemEntries(JobJournalLine."No.", '');

        // Exercise: Post Inventory to G/L batch job.
        LibraryVariableStorage.Enqueue(ValueEntriesWerePostedTxt);
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify: Verify Amount on G/L Entries.
        GLEntry.SetRange("Job No.", JobJournalLine."Job No.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, -Round(JobJournalLine.Quantity * JobJournalLine."Unit Cost"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInvCostToGLWithPostMethodPerEntry()
    var
        JobJournalLine: Record "Job Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        ValueEntry: Record "Value Entry";
        Item: Record Item;
        CostAmount: Decimal;
    begin
        // Verify Value Entry after running Post Inventory Cost To G/L batch job using Post Method 'Per Entry'.

        // Setup: Create and post Job Journal Line, create and post Item Journal Line, run Adjust Cost Item Entries.
        Initialize();
        CreateAndPostJobJournalLine(
          JobJournalLine,
          CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::Average), LibraryRandom.RandDec(10, 2));
        CreateAndPostItemJournalLine(ItemJournalLine, JobJournalLine."No.");
        LibraryCosting.AdjustCostItemEntries(JobJournalLine."No.", '');

        // Exercise: Post Inventory to G/L batch job.
        LibraryVariableStorage.Enqueue(ValueEntriesWerePostedTxt);
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // Verify: Verify Value Entry after running Post Inventory Cost To G/L batch job.
        CostAmount := Round((JobJournalLine."Unit Cost" - ItemJournalLine."Unit Cost") * JobJournalLine.Quantity);
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.", JobJournalLine."No.", CostAmount);
    end;

    [Test]
    [HandlerFunctions('CalculatePhysInvtCountingPageHandler,PhysInvtItemSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure CountingPeriodOnPhysInvJournalWithDim()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
    begin
        // Verify Physical Inventory Journal after calculate Counting Periods for an Item if Dimensions are selected.

        // Setup: Create Item, update Dimension and Physical Inventory Counting period on Item, create and post Item Journal Line.
        Initialize();
        Item.Get(CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::Average));
        UpdateCountingPeriodOnItem(Item);
        UpdateItemDimension(Item."No.");
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");
        LibraryVariableStorage.Enqueue(ItemJournalLine."Item No.");  // Enqueue for PhysInvtItemSelectionPageHandler.
        CreateItemJournalLineForPhysInv(ItemJournalLine2);
        Commit();

        // Exercise: Calculate Counting Period on Physical Inventory Journal.
        LibraryInventory.CalculateCountingPeriod(ItemJournalLine2);

        // Verify: Verify Quantity on Physical Inventory Journal.
        VerifyPhysInvJournalQty(Item."No.", ItemJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('DeletePhysInventoryLedgerPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DeletePhysInvLedgerEntries()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        // Verify deletion of Physical Inventory Ledger Entries.

        // Setup: Create Item, close Fiscal Year, Create and Post Physical Inventory Journal.
        Initialize();
        CloseFiscalYear();
        CreateAndPostItemJournalLine(
          ItemJournalLine, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::Average));
        RunCalculateInventoryReport(ItemJournalLine, ItemJournalLine."Item No.");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Exercise.
        DeletePhysInvLedger(ItemJournalLine."Item No.");

        // Verify: Verify deletion of Physical Inventory Ledger Entries
        PhysInventoryLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        Assert.IsFalse(PhysInventoryLedgerEntry.FindFirst(), PhysInvLedgerEntriesExists);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpdateItemUnitOfMeasureError()
    var
        Item: Record Item;
    begin
        // Verify error while update Base Unit of Measure if there are one or more open Ledger Entries for Item.

        // Setup: Create Item, create and register Warehouse Journal and Calculate Warehouse Adjustment.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateLotWhseTrackingCode());
        CreateAndRegisterWhseJournal(Item."No.");
        CalculateWhseAdjustment(Item);

        // Exercise: Update Base Unit of Measure on Item.
        asserterror UpdateItemBaseUnitOfMeasure(Item);

        // Verify:  Verify error while update Base Unit of Measure.
        Assert.ExpectedError(ChangeBaseUnitOfMeasureError);
    end;

    [Test]
    [HandlerFunctions('RollUpStandardCostReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RollUpStdCostOnStdCostWorkSheet()
    var
        Item: Record Item;
        Item2: Record Item;
        StandardCostWorksheetName: Record "Standard Cost Worksheet Name";
    begin
        // Verify Filtered Data Of Standard Cost Worksheet.

        // Setup: Create Item.
        Initialize();
        LibraryInventory.CreateStandardCostWorksheetName(StandardCostWorksheetName);
        Item.Get(CreateAndModifyItem(Item."Replenishment System"::"Prod. Order", Item."Costing Method"::Standard));
        Item2.Get(CreateAndModifyItem(Item2."Replenishment System"::"Prod. Order", Item2."Costing Method"::Standard));
        LibraryVariableStorage.Enqueue(StandardCostRollup);  // Enqueue value for MessageHandler.

        // Exercise: Apply Roll Up Standard Cost on Standard Cost WorkSheet.
        RunRollUpStandardCost(StandardCostWorksheetName.Name, Item."No.", Item2."No.");

        // Verify: Verify Standard Cost of Standard Cost Worksheet.
        VerifyStandardCost(Item2."No.", Item2."Standard Cost");
    end;

    [Test]
    [HandlerFunctions('RollUpStandardCostReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RollUpStdCostAfterUpdateInvPostingGroup()
    var
        Item: Record Item;
        Item2: Record Item;
        StandardCostWorksheetName: Record "Standard Cost Worksheet Name";
    begin
        // Verify Filtered Data Of Standard Cost Worksheet After Modify Item.

        // Setup: Create Item and Update Inventory Posting Group.
        Initialize();
        LibraryInventory.CreateStandardCostWorksheetName(StandardCostWorksheetName);
        Item.Get(CreateAndModifyItem(Item."Replenishment System"::"Prod. Order", Item."Costing Method"::Standard));
        Item2.Get(CreateAndModifyItem(Item2."Replenishment System"::"Prod. Order", Item2."Costing Method"::Standard));
        UpdateItemInvPostingGroup(Item2);
        LibraryVariableStorage.Enqueue(StandardCostRollup);  // Enqueue value for MessageHandler.

        // Exercise: Apply Roll Up Standard Cost on Standard Cost WorkSheet.
        RunRollUpStandardCost(StandardCostWorksheetName.Name, Item."No.", Item2."No.");

        // Verify: Verify Standard Cost of Standard Cost Worksheet.
        VerifyStandardCost(Item."No.", Item."Standard Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyingRevaluedInboundEntryToOutbound()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostingDate: Date;
    begin
        // Verify Item Ledger Entries when Item Costing Method is Average and after applying Revalued Inbound Entry to Outbound.

        // Setup: Create Item,Create and Post Item Journal with Postive adjustment,Create and Post Revaluation Journal,Create Item Journal with Negative adjustment.
        Initialize();
        CreateAndPostItemJournalLine(
          ItemJournalLine, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::Standard));  // Random value for Quantity and Unit Cost.
        LibraryCosting.AdjustCostItemEntries(ItemJournalLine."Item No.", '');  // Blank value for ItemCategoryFilter.
        CreateandPostItemJournalForRevaluation(ItemJournalLine, ItemJournalLine."Item No.");
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", ItemJournalLine."Item No.", LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10));  // Random value for Quantity and Unit Cost.
        PostingDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Excercise: Apply Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(ItemJournalLine."Item No.", '');  // Blank value for ItemCategoryFilter.

        // Verify: Verify Item Ledger Entry.
        FindItemLedgerEntry(ItemLedgerEntry, ItemJournalLine."Item No.", ItemJournalLine."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.TestField(Quantity, -ItemJournalLine.Quantity);
        ItemLedgerEntry.TestField("Posting Date", PostingDate);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesPageHandler,MessageHandler,CreditMemoConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ApplyToItemZeroErrorOnPurchReturnOrder()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify error while posting Purchase Return Order when Apply to Item Entry is Zero using Get Posted Document Lines to Reverse.

        // Setup: Update Inventory Setup and Purchase Payable Setup.
        Initialize();
        InventorySetup.Get();
        UpdateInventorySetup(InventorySetup."Automatic Cost Adjustment"::Always);
        PurchasesPayablesSetup.Get();
        UpdatePurchasesPayablesSetup(true);

        // Create and post Purchase Order, Create Purchase Return Order.
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO));
        LibraryVariableStorage.Enqueue(DocumentNo);
        CreatePurchRetOrderGetPstdDocLineToRev(PurchaseHeader, PurchaseLine."Buy-from Vendor No.");
        UpdateApplyToItemEntryOnPurchLine(PurchaseLine, PurchaseHeader."No.");

        // Exercise: Post Purchase Return Order.
        asserterror PostPurchaseDocument(PurchaseHeader);

        // Verify: Verify error while posting Purchase Return Order when Apply to Item Entry is Zero.
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Appl.-to Item Entry"), '');

        // Tear Down.
        UpdateInventorySetup(InventorySetup."Automatic Cost Adjustment");
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Exact Cost Reversing Mandatory");
    end;

    [Normal]
    local procedure DeleteApplOnPurchReturnOrder(Serial: Boolean; Lot: Boolean; TrackingOption: Option)
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify there is no error when posting unapplied Purchase Return Order with serial/lot numbers.
        // VSTF: 212797.

        // Setup: Update Inventory Setup and Purchase Payable Setup.
        Initialize();
        InventorySetup.Get();
        UpdateInventorySetup(InventorySetup."Automatic Cost Adjustment"::Always);
        PurchasesPayablesSetup.Get();
        UpdatePurchasesPayablesSetup(true);

        // Create and post Purchase Order, Create Purchase Return Order.
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(Serial, Lot));
        DocumentNo := CreateAndPostPurchaseOrderWithIT(PurchaseHeader, Item."No.", TrackingOption, LibraryRandom.RandInt(10), 2);

        LibraryVariableStorage.Enqueue(DocumentNo);
        CreatePurchRetOrderGetPstdDocLineToRev(PurchaseHeader, PurchaseHeader."Buy-from Vendor No.");
        UpdateApplyToItemEntryOnPurchLine(PurchaseLine, PurchaseHeader."No.");

        // Exercise: Post Purchase Return Order.
        PostPurchaseDocument(PurchaseHeader);

        // Verify: No error when posting. Resulting value entries are unapplied.
        VerifyValueEntryNoApplication(Item."No.");

        // Tear Down.
        UpdateInventorySetup(InventorySetup."Automatic Cost Adjustment");
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Exact Cost Reversing Mandatory");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,PostedPurchaseDocumentLinesPageHandler,MessageHandler,CreditMemoConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DeleteApplOnPurchReturnOrderWithSerial()
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo;
    begin
        // VSTF: 212797.
        DeleteApplOnPurchReturnOrder(true, false, TrackingOption::AssignSerialNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PostedPurchaseDocumentLinesPageHandler,MessageHandler,CreditMemoConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DeleteApplOnPurchReturnOrderWithLot()
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo;
    begin
        // VSTF: 245050, 252794.
        DeleteApplOnPurchReturnOrder(false, true, TrackingOption::SetLotNo);
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesPageHandler,ReservationPageHandler,MessageHandler,CreditMemoConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DeleteApplOnPurchReturnOrderWithReservation()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservOption: Option AutoReserve,CancelReserv;
        DocumentNo: Code[20];
    begin
        // Verify there is no error when posting unapplied Purchase Return Order with reservations.
        // VSTF: 212797.

        // Setup: Update Inventory Setup and Purchase Payable Setup.
        Initialize();
        InventorySetup.Get();
        UpdateInventorySetup(InventorySetup."Automatic Cost Adjustment"::Always);
        PurchasesPayablesSetup.Get();
        UpdatePurchasesPayablesSetup(true);

        // Create and post Purchase Order, Create Purchase Return Order.
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO));

        LibraryVariableStorage.Enqueue(DocumentNo);
        CreatePurchRetOrderGetPstdDocLineToRev(PurchaseHeader, PurchaseLine."Buy-from Vendor No.");
        UpdateApplyToItemEntryOnPurchLine(PurchaseLine, PurchaseHeader."No.");

        LibraryVariableStorage.Enqueue(ReservOption::AutoReserve);  // Enqueue for ReservationPageHandler.
        PurchaseLine.ShowReservation();

        // Exercise: Post Purchase Return Order.
        PostPurchaseDocument(PurchaseHeader);

        // Verify: No error when posting. Resulting value entries are unapplied.
        VerifyValueEntryNoApplication(PurchaseLine."No.");

        // Tear Down.
        UpdateInventorySetup(InventorySetup."Automatic Cost Adjustment");
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Exact Cost Reversing Mandatory");
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesPageHandler,MessageHandler,CreditMemoConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ApplyFromItemZeroErrorOnSalesReturnOrder()
    var
        InventorySetup: Record "Inventory Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify error while posting sales Return Order when Apply from Item Entry is Zero using Get Posted Document Lines to Reverse.

        // Setup: Update Inventory Setup and Sales Receivable Setup.
        Initialize();
        InventorySetup.Get();
        UpdateInventorySetup(InventorySetup."Automatic Cost Adjustment"::Always);
        SalesReceivablesSetup.Get();
        UpdateSalesReceivablesSetup(true, SalesReceivablesSetup."Stockout Warning");

        // Create and post Sales order, create Sales Return Order.
        DocumentNo := CreateAndPostSalesOrder(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(DocumentNo);
        GetPostedDocToReverseOnSalesReturnOrder(SalesHeader2."No.");
        UpdateApplyFromItemEntryOnSalesLine(SalesLine, SalesHeader2."No.");

        // Exercise: Post Sales Return Order.
        asserterror PostSalesDocument(SalesLine, true);

        // Verify: Verify error while posting sales Return Order when Apply from Item Entry is Zero.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Appl.-from Item Entry"), '');

        // Tear Down.
        UpdateInventorySetup(InventorySetup."Automatic Cost Adjustment");
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Exact Cost Reversing Mandatory", SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchOrderWithFullInvoicedItemCharge()
    var
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        DocumentNo: Code[20];
    begin
        // Verify G/L Entries after posting Purchase Order as Invoice if Item Charge Line is fully invoiced.

        // Setup: Create Purchase Order with Item Charge and receive it.
        Initialize();
        CreateAndReceivePurchOrderWithItemCharge(PurchaseLine);

        // Exercise: Update Quantity to Invoice and Invoice Item Charge.
        DocumentNo := UpdateQtyAndInvoicePurchaseOrder(PurchaseLine);

        // Verify: Verify G/L Entries after posting Purchase Order as Invoice.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntries(DocumentNo, GeneralPostingSetup."Purch. Account", PurchaseLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceForCustomer()
    var
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
    begin
        // Verify Unit Price on Sales Line when Order Date is same as Starting Date of Sales Price with Sales Type Customer.

        // Setup:
        Initialize();

        // Exercise: Create Sales Order.
        CreateSalesOrderWithSalesPriceOnCustomer(SalesLine, WorkDate());

        // Verify: Verify Unit Price on Sales Line when Order Date is same as Starting Date of Sales Price.
        SalesPrice.SetRange("Item No.", SalesLine."No.");
        SalesPrice.FindFirst();
        SalesLine.TestField("Unit Price", SalesPrice."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceForCustomerFromItem()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Verify Unit Price on Sales Line when Order Date is before Starting Date of Sales Price with Sales Type Customer.

        // Setup.
        Initialize();

        // Exercise: Create Sales Order.
        CreateSalesOrderWithSalesPriceOnCustomer(SalesLine, CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));

        // Verify: Verify Unit Price on Sales Line when Order Date is before Starting Date of Sales Price.
        Item.Get(SalesLine."No.");
        SalesLine.TestField("Unit Price", Item."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceForCustPriceGroup()
    var
        Item: Record Item;
        CustomerPriceGroup: Record "Customer Price Group";
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify Unit Price on Sales Line when Customer Pricing Group defined on Sales Price.

        // Setup: Create Item, create Sales Price with Type Customer Pricing Group.
        Initialize();
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CreateSalesPrice(
          SalesPrice, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO),
          "Sales Price Type"::"Customer Price Group", CustomerPriceGroup.Code, 0, '');  // 0 for Minimum Quantity.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CopyAllSalesPriceToPriceListLine();

        // Exercise.
        CreateSalesOrderWithOrderDate(
          SalesLine, CreateAndUpdateCustomer(CustomerPriceGroup.Code, VATPostingSetup."VAT Bus. Posting Group", ''), SalesPrice."Item No.",
          WorkDate(), '', SalesPrice."Minimum Quantity");

        // Verify: Verify Unit Price on Sales Line when Customer Pricing Group defined on Sales Price.
        SalesLine.TestField("Unit Price", SalesPrice."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceForCustPriceGroupFromItem()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
    begin
        // Verify Unit Price on Sales Line when Sales Order is created with another Customer and Customer Pricing Group is defined on Sales Price.

        // Setup: Create Item, create Sales Price with Type Customer Pricing Group, create Customer.
        Initialize();
        CreateSalesPriceWithCustomerPriceGroup(SalesPrice);
        CopyAllSalesPriceToPriceListLine();

        // Exercise.
        CreateSalesOrderWithOrderDate(SalesLine, CreateCustomer(), SalesPrice."Item No.", WorkDate(), '', SalesPrice."Minimum Quantity");

        // Verify: Verify Unit Price on Sales Line when Sales Order is created with another Customer.
        Item.Get(SalesLine."No.");
        SalesLine.TestField("Unit Price", Item."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceForAllCustomer()
    var
        SalesPrice: Record "Sales Price";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Verify Unit Price on Sales Line when Sales Price with Type All Customer is defined for Item.

        // Setup: Create Item, create Sales Price.
        Initialize();
        CreateSalesPrice(
          SalesPrice, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO),
          "Sales Price Type"::"All Customers", '', 0, '');  // 0 for Minimum Quantity.
        CopyAllSalesPriceToPriceListLine();

        // Exercise.
        CreateSalesOrderWithOrderDate(SalesLine, CreateCustomer(), SalesPrice."Item No.", WorkDate(), '', SalesPrice."Minimum Quantity");

        // Verify: Verify Unit Price on Sales Line.
        SalesLine.TestField("Unit Price", SalesPrice."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceForCustomerWithCurrency()
    var
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        Item: Record Item;
    begin
        // Verify Unit Price on Sales Line when Sales Price is defined for Customer with Currency.

        // Setup:
        Initialize();
        CreateSalesPrice(
          SalesPrice, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO),
          "Sales Price Type"::Customer, CreateCustomer(), 0, CreateCurrency());  // 0 for Minimum Qunatity.
        CopyAllSalesPriceToPriceListLine();

        // Exercise: Create Sales Order with Currency.
        CreateSalesOrderWithOrderDate(
          SalesLine, SalesPrice."Sales Code", SalesPrice."Item No.", WorkDate(), SalesPrice."Currency Code", SalesPrice."Minimum Quantity");

        // Verify: Verify Unit Price on Sales Line.
        SalesLine.TestField("Unit Price", SalesPrice."Unit Price");
    end;

    [Test]
    [HandlerFunctions('CreditMemoConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesPriceForCustomerWithPartialQty()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Unit Price on Posted Sales Invoice after posting Partial Quantity on Sales Order and updating Unit Price on Sales Price.

        // Setup: Create Item, create Customer, create Sales Price and Update Unit Price, create Sales Order.
        Initialize();
        CreateSalesPrice(
          SalesPrice, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO),
          "Sales Price Type"::Customer, CreateCustomer(), 0, '');  // 0 for Minimum Quantity.
        CopyAllSalesPriceToPriceListLine();
        CreateAndUpdateSalesOrder(SalesLine, SalesPrice."Sales Code", SalesPrice."Item No.", LibraryRandom.RandDec(10, 2));  // Take random for Quantity.
        UpdateUnitPriceOnSalesPrice(SalesPrice);
        CopyAllSalesPriceToPriceListLine();

        // Exercise: Post Sales Order.
        DocumentNo := PostSalesDocument(SalesLine, true);  // TRUE for Invoice.

        // Verify: Verify Unit Price on Posted Sales Invoice after updating Unit Price on Sales Price.
        VerifySalesInvoiceLine(DocumentNo, SalesPrice."Unit Price", 0);
    end;

    [Test]
    [HandlerFunctions('CreditMemoConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostSalesInvUsingCopyDoc()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        UnitPrice: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify Unit Price on Posted Sales Invoice after posting Sales Invoice using Copy Document and updating Unit Price on Sales Price.

        // Setup: Create Sales Price, create Sales Order.
        Initialize();
        SalesReceivablesSetup.Get();
        UpdateSalesReceivablesSetup(false, false);
        CreateSalesPrice(
          SalesPrice, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO),
          "Sales Price Type"::Customer, CreateCustomer(), 0, '');  // Take 0 for Minimum Quantity.
        CreateAndUpdateSalesOrder(SalesLine, SalesPrice."Sales Code", SalesPrice."Item No.", LibraryRandom.RandDec(10, 2));  // Take random for Quantity.

        // Post Sales Order, update Sales Price, create Sales Invoice using Copy Document.
        DocumentNo := PostSalesDocument(SalesLine, false);  // FALSE for Invoice.
        UnitPrice := UpdateUnitPriceOnSalesPrice(SalesPrice);
        CopyAllSalesPriceToPriceListLine();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SalesPrice."Sales Code");
        Commit();  // COMMIT required to run CopySalesDocument.
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Shipment", DocumentNo, false, true);

        // Exercise: Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Unit Price on Posted Sales Invoice after updating Unit Price on Sales Price.
        VerifySalesInvoiceLine(DocumentNo, UnitPrice, 0);

        // Tear Down.
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Exact Cost Reversing Mandatory", SalesReceivablesSetup."Stockout Warning");
    end;

    local procedure CopyAllSalesPriceToPriceListLine()
    var
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.DeleteAll();
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceStatisticsPageHandler,CreditMemoConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PstdSalesInvStatisticsWithSalesPrice()
    var
        SalesLine: Record "Sales Line";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // Verify Amount on Posted Sales Invoice Statistics after posting Sales Order.

        // Setup: Create Sales Order, define Sales Price on Customer,.
        Initialize();
        CreateSalesOrderWithSalesPriceOnCustomer(SalesLine, WorkDate());
        LibraryVariableStorage.Enqueue(SalesLine."Line Amount");  // Enqueue for SalesInvoiceStatisticsPageHandler.

        // Exercise: Post Sales Order.
        DocumentNo := PostSalesDocument(SalesLine, true);  // TRUE for Invoice.

        // verify: Verify Amount on Posted Sales Invoice Statistics.Verification done in SalesInvoiceStatisticsPageHandler..
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", DocumentNo);
        PostedSalesInvoice.Statistics.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceOnItemJournal()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Unit Amount on Item Journal Line when Sales Price is defined for Item.

        // Setup: Create Item, create Sales Price for All Customer.
        Initialize();
        CreateSalesPrice(
          SalesPrice, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO),
          "Sales Price Type"::"All Customers", '', LibraryRandom.RandDec(10, 2), '');
        CopyAllSalesPriceToPriceListLine();

        // Exercise: Create Item Journal Line.
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::Sale, SalesPrice."Item No.", SalesPrice."Minimum Quantity", 0);  // 0 for Unit Cost

        // Verify:  Verify Unit Amount on Item Journal Line.
        ItemJournalLine.TestField("Unit Amount", SalesPrice."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountForCustomer()
    var
        SalesLineDiscount: Record "Sales Line Discount";
        SalesLine: Record "Sales Line";
    begin
        // Verify Line Discount on Sales Line when Sales Line Discount for Sale Type Customer is defined.

        // Setup: Create Sales Line Discount for Sales Type Customer.
        Initialize();
        CreateLineDiscForCustomer(SalesLineDiscount, SalesLineDiscount."Sales Type"::Customer, CreateCustomer());
        CopyAllSalesPriceToPriceListLine();

        // Exercise.
        CreateSalesOrderWithOrderDate(
          SalesLine, SalesLineDiscount."Sales Code", SalesLineDiscount.Code, WorkDate(), '', SalesLineDiscount."Minimum Quantity");

        // Verify: Verify Line Discount on Sales Line for Sale Type Customer.
        SalesLine.TestField("Line Discount %", SalesLineDiscount."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountForCustomerDiscountGroup()
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
        SalesLineDiscount: Record "Sales Line Discount";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Verify Line Discount on Sales Line when Sales Line Discount for Sale Type Customer Discount Group is defined.

        // Setup: Create Item, create Sales Line Discount with Type Customer Discount Group.
        Initialize();
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        CreateLineDiscForCustomer(SalesLineDiscount, SalesLineDiscount."Sales Type"::"Customer Disc. Group", CustomerDiscountGroup.Code);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CopyAllSalesPriceToPriceListLine();

        // Exercise.
        CreateSalesOrderWithOrderDate(
          SalesLine, CreateAndUpdateCustomer('', VATPostingSetup."VAT Bus. Posting Group", CustomerDiscountGroup.Code),
          SalesLineDiscount.Code, WorkDate(), '', SalesLineDiscount."Minimum Quantity");

        // Verify: Verify Line Discount on Sales Line for Sale Type Customer Discount Group.
        SalesLine.TestField("Line Discount %", SalesLineDiscount."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountForAllCustomer()
    var
        SalesLineDiscount: Record "Sales Line Discount";
        SalesLine: Record "Sales Line";
    begin
        // Verify Line Discount on Sales Line when Sales Line Discount for Sales Type All Customer is defined.

        // Setup: Create Item, create Line Discount for Customer.
        Initialize();
        CreateLineDiscForCustomer(SalesLineDiscount, SalesLineDiscount."Sales Type"::"All Customers", '');
        CopyAllSalesPriceToPriceListLine();

        // Exercise.
        CreateSalesOrderWithOrderDate(SalesLine, CreateCustomer(), SalesLineDiscount.Code, WorkDate(), '', SalesLineDiscount."Minimum Quantity");

        // Verify: Verify Line Discount on Sales Line for Sales Type All Customer.
        SalesLine.TestField("Line Discount %", SalesLineDiscount."Line Discount %");
    end;

    [Test]
    [HandlerFunctions('CreditMemoConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure LineDiscountForCustomerWithPartialQty()
    var
        SalesLineDiscount: Record "Sales Line Discount";
        Item: Record Item;
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Line Discount on Posted Sales Invoice after posting Partial Quantity on Sales Order and updating Line Discount on Sales Line Discount.

        // Setup: Create Item, create Customer, create Sales Line Discount and Update Line Discount, create Sales Order.
        Initialize();
        CreateLineDiscForCustomer(SalesLineDiscount, SalesLineDiscount."Sales Type"::Customer, CreateCustomer());
        CopyAllSalesPriceToPriceListLine();
        CreateAndUpdateSalesOrder(SalesLine, SalesLineDiscount."Sales Code", SalesLineDiscount.Code, SalesLineDiscount."Minimum Quantity");
        UpdateDiscOnSalesLineDiscount(SalesLineDiscount);
        CopyAllSalesPriceToPriceListLine();

        // Exercise: Post Sales Order.
        DocumentNo := PostSalesDocument(SalesLine, true);  // TRUE for Invoice.

        // Verify: Verify Line Discount on Posted Sales Invoice after updating Line Discount on Sales Line Discount.
        Item.Get(SalesLine."No.");
        VerifySalesInvoiceLine(DocumentNo, Item."Unit Price", SalesLineDiscount."Line Discount %");
    end;

    [Test]
    [HandlerFunctions('CreditMemoConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure LineDiscOnPostSalesInvUsingCopyDoc()
    var
        Item: Record Item;
        SalesLineDiscount: Record "Sales Line Discount";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LineDiscPct: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify Line Discount on Posted Sales Invoice after posting Sales Invoice using Copy Document and updating Line Discount on Sales Line Discount.

        // Setup: Create Item, create Customer, create Sales Line Discount, create Sales Order.
        Initialize();
        SalesReceivablesSetup.Get();
        UpdateSalesReceivablesSetup(false, false);
        CreateLineDiscForCustomer(SalesLineDiscount, SalesLineDiscount."Sales Type"::Customer, CreateCustomer());
        CreateAndUpdateSalesOrder(SalesLine, SalesLineDiscount."Sales Code", SalesLineDiscount.Code, SalesLineDiscount."Minimum Quantity");

        // Post Sales Order, update Line Discount, create Sales Invoice using Copy Document.
        DocumentNo := PostSalesDocument(SalesLine, false);  // FALSE for Invoice.
        LineDiscPct := UpdateDiscOnSalesLineDiscount(SalesLineDiscount);
        CopyAllSalesPriceToPriceListLine();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SalesLineDiscount."Sales Code");
        Commit();  // COMMIT required to run CopySalesDocument.
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Shipment", DocumentNo, false, true);

        // Exercise: Post Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Line Discount on Posted Sales Invoice after updating Line Discount on Sales Line Discount for Customer.
        Item.Get(SalesLine."No.");
        VerifySalesInvoiceLine(DocumentNo, Item."Unit Price", LineDiscPct);

        // Tear Down.
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Exact Cost Reversing Mandatory", SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceForCustomerWithPriceInclVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
    begin
        // Verify Unit Price on Sales Line when Sales Price Sales Type Customer is defined with Price Including VAT TRUE.

        // Setup: Create Customer with Price Including VAT TRUE.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CustomerNo := CreateAndUpdateCustomer('', VATPostingSetup."VAT Bus. Posting Group", '');

        // Exercise & Verify.
        SalesPriceForPriceInclVAT(VATPostingSetup, "Sales Price Type"::Customer, CustomerNo, CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceForCustPriceGrpWithPriceInclVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerPriceGroup: Code[10];
    begin
        // Verify Unit Price on Sales Line when Sales Price Sales Type Customer Price Group is defined with Price Including VAT TRUE.

        // Setup: Create Customer and Customer Price Group with Price Including VAT TRUE.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CustomerPriceGroup := CreateAndUpdateCustPriceGroup(VATPostingSetup."VAT Bus. Posting Group");

        // Exercise & Verify.
        SalesPriceForPriceInclVAT(
          VATPostingSetup, "Sales Price Type"::"Customer Price Group", CustomerPriceGroup,
          CreateAndUpdateCustomer(CustomerPriceGroup, VATPostingSetup."VAT Bus. Posting Group", ''));
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReduceQtyOnPartialReceivedSalesReturnOrder()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNo: Code[20];
        ReturnQtyReceived: Decimal;
    begin
        // Verify Quantity can be reduced on partial received Sales Return Order created by using Get Posted Document Line to Reverse.
        // Setup: Create and post Sales Order, create Sales Return Order using Get Posted Document Lines To Reverse.
        Initialize();
        DocumentNo := CreateAndPostSalesOrder(SalesHeader1); // Using Random Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Return Order", SalesHeader1."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(DocumentNo); // Enqueue value for PostedSalesDocumentLinesPageHandler.
        GetPostedDocToReverseOnSalesReturnOrder(SalesHeader2."No.");

        // Exercise: Update "Return Qty. to Receive" on Sales Return Line and post the Sales Return Order.
        ReturnQtyReceived := UpdateReturnQtyToReceiveOnSalesLine(SalesHeader2."No.", SalesHeader2."Document Type");
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // Reopen the Sales Return Order.
        LibrarySales.ReopenSalesDocument(SalesHeader2);

        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();

        // Exercise & Verify: No error when reduce the Quantity in the Sales Line on page - not repro on the table.
        // Quantity=[SalesLine."Return Qty. Received",SalesLine.Quantity).
        UpdateQtyOnSalesReturnOrder(SalesHeader2."No.", SalesInvoiceLine."No.",
          LibraryRandom.RandDecInDecimalRange(ReturnQtyReceived, SalesInvoiceLine.Quantity - 0.01, 2));
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ReduceQtyOnPartialShippedPurchaseReturnOrder()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        ReturnQtyShipped: Decimal;
    begin
        // Verify Quantity can be reduced on partial shipped Purchase Return Order created by using Get Posted Document Line to Reverse.
        // Setup: Create Item,Create and post Purchase Order, create Purchase Return Order using Get Posted Document Lines To Reverse.
        Initialize();
        LibraryInventory.CreateItem(Item);
        DocumentNo := CreateAndPostPurchaseOrder(PurchaseLine, Item."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader,
          PurchaseHeader."Document Type"::"Return Order", PurchaseLine."Buy-from Vendor No.");
        LibraryVariableStorage.Enqueue(DocumentNo); // Enqueue value for PostedPurchaseDocumentLinesPageHandler.
        GetPostedDocToReverseOnPurchReturnOrder(PurchaseHeader."No.");

        // Exercise: Update "Return Qty. to Ship" on Purchase Return Line and post the Purchase Return Order.
        ReturnQtyShipped := UpdateReturnQtyToShipOnPurchLine(PurchaseHeader."No.", PurchaseHeader."Document Type");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Reopen the Purchase Return Order.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // Exercise & Verify: No error when reduce the Quantity in the Purchase Line on page - not repro on the table.
        // Quantity=[PurchaseLine."Return Qty. Shipped",PurchaseLine.Quantity).
        UpdateQtyOnPurchReturnOrder(PurchaseHeader."No.", Item."No.",
          LibraryRandom.RandDecInDecimalRange(ReturnQtyShipped, PurchaseLine.Quantity - 0.01, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReduceQtyOnPartialShippedSalesOrderWithNegativeQuantity()
    var
        SalesHeader1: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        DocumentNo: Code[20];
        QtyShipped: Decimal;
    begin
        // Verify quantity can be reduced after partially shipping sales order with negative quantity created by using Appl.-from Item Entry.
        // Setup: Create and post Sales Order.
        Initialize();
        DocumentNo := CreateAndPostSalesOrder(SalesHeader1);

        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();

        // Exercise: Create Sales Order with negative quantity using Appl.-from Item Entry, update "Qty. to Ship" and shipped.
        QtyShipped := CreateAndParitialShipSalesOrderWithNegativeQty(
            SalesHeader2, SalesLine2, SalesInvoiceLine."No.", -SalesInvoiceLine.Quantity, false);

        // Reopen the Sales Order with negative quantity.
        LibrarySales.ReopenSalesDocument(SalesHeader2);

        // Exercise & Verify: No error when reduce the Quantity in the sales line on page - not repro on the table.
        // Quantity=[SalesLine."Qty. Shipped",SalesLine.Quantity).
        UpdateQtyOnSalesOrder(SalesHeader2."No.", SalesInvoiceLine."No.",
          LibraryRandom.RandDecInDecimalRange(-(SalesInvoiceLine.Quantity - 0.01), QtyShipped, 2));
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler,ReservationPageHandler,CreditMemoConfirmHandlerYes,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReservationFromBoundProductionOrder()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ReservationEntry: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
    begin
        // Verify Expected Receipt and Shipment Date on Reservation Entries of Sales and Production Orders after cancelling reservation
        // from order-to-order bound Production Order

        // Setup: Create Released Production Order From Sales Order with Tracking.
        Initialize();
        CreateProdOrderFromSalesOrderUsingPlanning(SalesLine);
        FindProdOrderLine(ProdOrderLine, SalesLine."No.");
        AssignLotNoOnBoundProductionOrder(ProdOrderLine);

        // Exercise: Cancel Reservation on Released Production Order
        CancelReservationOnProductionOrder(ProdOrderLine."Item No.");

        // Verify: Verify Expected Receipt and Shipment Date on Reservation Entries of Sales and Production Orders after cancelling reservation
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, ProdOrderLine."Item No.", DATABASE::"Sales Line",
          SalesLine."Document Type"::Order.AsInteger(), false, SalesLine."Shipment Date", 0D);
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, ProdOrderLine."Item No.", DATABASE::"Prod. Order Line",
          ProdOrderLine.Status::Released.AsInteger(), true, 0D, ProdOrderLine."Due Date");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,CreditMemoConfirmHandlerYes,ReservationPageHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReservationFromBoundPurchaseOrder()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        LotNo: Code[10];
        Quantity: Decimal;
    begin
        // Verify Expected Receipt and Shipment Date on Reservation Entries of Sales and Purchase Orders after cancelling reservation
        // from order-to-order bound Purchase Order.

        // Setup: Create Sales and Purchase Order and Reserve Sales against Purchase.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateLotWhseTrackingCode());
        CreatePurchaseOrderWithItemTracking(PurchaseLine, PurchaseLine."Document Type"::Order, Item."No.", Quantity, LotNo);
        CreateSalesOrderWithItemTracking(SalesLine, SalesLine."Document Type"::Order, Item."No.", Quantity, LotNo);
        SalesLine.Validate("Shipment Date", CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(5)), WorkDate()));
        SalesLine.Modify(true);
        CreateReservationForBoundSalesOrder(SalesLine);

        // Exercise: Cancel Reservation on Purchase Order
        CancelReservationOnBoundPurchaseOrder(PurchaseLine);

        // Verify: Verify Expected Receipt and Shipment Date on Reservation Entries of Sales and Purchase Orders after cancelling reservation
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, Item."No.", DATABASE::"Sales Line",
          SalesLine."Document Type"::Order.AsInteger(), false, SalesLine."Shipment Date", 0D);
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, Item."No.", DATABASE::"Purchase Line",
          PurchaseLine."Document Type"::Order.AsInteger(), true, 0D, PurchaseLine."Expected Receipt Date");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,CreditMemoConfirmHandlerYes,ReservationPageHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReservationFromBoundSalesOrderWithNegativeQuantity()
    var
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        SalesLineWithNegativeQuantity: Record "Sales Line";
        SalesLine: Record "Sales Line";
        LotNo: Code[10];
        Quantity: Decimal;
    begin
        // Verify Expected Receipt and Shipment Date on Reservation Entries of Sales Order and Sales Order with Negative Quantity after cancelling reservation
        // from order-to-order bound Sales Order with Negative Quantity.

        // Setup: Create Negative and Positive Quantity Sales Order and Reserve Positive Sales Order against Negative.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateLotWhseTrackingCode());
        CreateSalesOrderWithItemTracking(SalesLineWithNegativeQuantity, SalesLine."Document Type"::Order, Item."No.", -Quantity,
          LotNo);
        CreateSalesOrderWithItemTracking(SalesLine, SalesLine."Document Type"::Order, Item."No.", Quantity, LotNo);
        SalesLine.Validate("Shipment Date", CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(5)), WorkDate()));
        SalesLine.Modify(true);
        CreateReservationForBoundSalesOrder(SalesLine);

        // Exercise: Cancel Reservation on Sales Order with Negative Quantity
        CancelReservationOnBoundSalesOrder(SalesLineWithNegativeQuantity);

        // Verify: Verify Expected Receipt and Shipment Date on Reservation Entries of Sales Order and Sales Order with Negative Quantity after cancelling reservation
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, Item."No.", DATABASE::"Sales Line",
          SalesLine."Document Type"::Order.AsInteger(), true, 0D, SalesLineWithNegativeQuantity."Shipment Date");
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, Item."No.", DATABASE::"Sales Line",
          SalesLine."Document Type"::Order.AsInteger(), false, SalesLine."Shipment Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,CreditMemoConfirmHandlerYes,ReservationPageHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReservationFromBoundPurchaseOrderWithNegativeQuantity()
    var
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        PurchaseLineWithNegativeQuantity: Record "Purchase Line";
        LotNo: Code[10];
        Quantity: Decimal;
    begin
        // Verify Expected Receipt and Shipment Date on Reservation Entries of Sales Return Order and Purchase Order with Negative Quantity after cancelling reservation
        // from order-to-order bound Purchase Order with Negative Quantity.

        // Setup: Create Sales Order and Negative Quantity Purchase Order and Reserve Purchase against Sales Return.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateLotWhseTrackingCode());
        CreateSalesOrderWithItemTracking(SalesLine, SalesLine."Document Type"::"Return Order", Item."No.", Quantity, LotNo);
        CreatePurchaseOrderWithItemTracking(PurchaseLineWithNegativeQuantity, PurchaseLineWithNegativeQuantity."Document Type"::Order,
          Item."No.", -Quantity, LotNo);
        PurchaseLineWithNegativeQuantity.Validate(
          "Expected Receipt Date", CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(5)), WorkDate()));
        PurchaseLineWithNegativeQuantity.Modify(true);
        CreateReservationForBoundPurchaseOrder(PurchaseLineWithNegativeQuantity);

        // Exercise: Cancel Reservation On Purchase Order
        CancelReservationOnBoundPurchaseOrder(PurchaseLineWithNegativeQuantity);

        // Verify: Verify Expected Receipt and Shipment Date on Reservation Entries of Sales Return Order and Purchase Order with Negative Quantity after cancelling reservation
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, Item."No.", DATABASE::"Sales Line",
          SalesLine."Document Type"::"Return Order".AsInteger(), true, 0D, SalesLine."Shipment Date");
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, Item."No.", DATABASE::"Purchase Line",
          PurchaseLineWithNegativeQuantity."Document Type"::Order.AsInteger(), false, PurchaseLineWithNegativeQuantity."Expected Receipt Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,CreditMemoConfirmHandlerYes,ReservationPageHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReservationFromBoundReturnSalesOrder()
    var
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        SalesLineReturn: Record "Sales Line";
        SalesLine: Record "Sales Line";
        LotNo: Code[10];
        Quantity: Decimal;
    begin
        // Verify Expected Receipt and Shipment Date on Reservation Entries of Sales Return Order and Sales Order after cancelling reservation
        // from order-to-order bound Sales Return Order.

        // Setup: Create Sales Order and Return Sales Order and Reserve Sales against Sales Return.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateLotWhseTrackingCode());
        CreateSalesOrderWithItemTracking(SalesLineReturn, SalesLine."Document Type"::"Return Order", Item."No.", Quantity, LotNo);
        CreateSalesOrderWithItemTracking(SalesLine, SalesLine."Document Type"::Order, Item."No.", Quantity, LotNo);
        SalesLine.Validate("Shipment Date", CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(5)), WorkDate()));
        SalesLine.Modify(true);
        CreateReservationForBoundSalesOrder(SalesLine);

        // Exercise: Cancel Reservation on Return Sales Order
        CancelReservationOnBoundSalesOrder(SalesLineReturn);

        // Verify: Verify Expected Receipt and Shipment Date on Reservation Entries of Sales Return Order and Sales Order after cancelling reservation
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, Item."No.", DATABASE::"Sales Line",
          SalesLine."Document Type"::"Return Order".AsInteger(), true, 0D, SalesLineReturn."Shipment Date");
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, Item."No.", DATABASE::"Sales Line",
          SalesLine."Document Type"::Order.AsInteger(), false, SalesLine."Shipment Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,CreditMemoConfirmHandlerYes,ReservationPageHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure CancelReservationFromBoundReturnPurchaseOrder()
    var
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineReturn: Record "Purchase Line";
        LotNo: Code[10];
        Quantity: Decimal;
    begin
        // Verify Expected Receipt and Shipment Date on Reservation Entries of Purchase Order and Purchase Return Order after cancelling reservation
        // from order-to-order bound Sales Return Order.

        // Setup: Create Purchase Order and Return Purchase Order and Reserve Purchase against Purchase Return.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateLotWhseTrackingCode());
        CreatePurchaseOrderWithItemTracking(PurchaseLine, PurchaseLine."Document Type"::Order, Item."No.", Quantity, LotNo);
        CreatePurchaseOrderWithItemTracking(PurchaseLineReturn, PurchaseLine."Document Type"::"Return Order", Item."No.", Quantity,
          LotNo);
        PurchaseLineReturn.Validate("Expected Receipt Date", CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(5)), WorkDate()));
        PurchaseLineReturn.Modify(true);
        CreateReservationForBoundPurchaseOrder(PurchaseLineReturn);

        // Exercise: Cancel Reservation from Purchase Order
        CancelReservationOnBoundPurchaseOrder(PurchaseLine);

        // Verify: Verify Expected Receipt and Shipment Date on Reservation Entries of Purchase Order and Purchase Return Order after cancelling reservation
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, Item."No.", DATABASE::"Purchase Line",
          PurchaseLine."Document Type"::Order.AsInteger(), true, 0D, PurchaseLine."Expected Receipt Date");
        VerifyShipmentAndExpRcptDateOnReservationEntry(ReservationEntry, Item."No.", DATABASE::"Purchase Line",
          PurchaseLine."Document Type"::"Return Order".AsInteger(), false, PurchaseLineReturn."Expected Receipt Date", 0D);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesReturnOrderByCopyDocumentWithSerialNo()
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
        CreateReturnOrderMethod: Option GetPostedDocumentLineToReserve,CopyDocument,ByManually;
    begin
        // Sales Return Order created by Copy Document with Serial No. on Item Tracking Line.
        CalcPlanAfterCreateSalesReturnOrderWithIT(true, false, false, TrackingOption::AssignSerialNo, CreateReturnOrderMethod::CopyDocument);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesReturnOrderByManuallyWithLotNo()
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
        CreateReturnOrderMethod: Option GetPostedDocumentLineToReserve,CopyDocument,ByManually;
    begin
        // Sales Return Order created by manually with Lot No. on Item Tracking Line.
        CalcPlanAfterCreateSalesReturnOrderWithIT(false, true, false, TrackingOption::SetLotNo, CreateReturnOrderMethod::ByManually);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PostedPurchaseDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchReturnOrderByGetPostedDocToReverseWithLotNo()
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
        CreateReturnOrderMethod: Option GetPostedDocumentLineToReserve,CopyDocument,ByManually;
    begin
        // Purchase Return Order created by Get Posted Document Line To Reserve with Lot No. on Item Tracking Line.
        CalcPlanAfterCreatePurchReturnOrderWithIT(
          false, true, TrackingOption::SetLotNo, CreateReturnOrderMethod::GetPostedDocumentLineToReserve);
    end;

    [Test]
    [HandlerFunctions('EnterQuantitytoCreatePageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchReturnOrderByCopyDocumentWithSerialNo()
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
        CreateReturnOrderMethod: Option GetPostedDocumentLineToReserve,CopyDocument,ByManually;
    begin
        // Purchase Return Order  created by copy Document with Serial No. on Item Tracking Line.
        CalcPlanAfterCreatePurchReturnOrderWithIT(true, false, TrackingOption::AssignSerialNo, CreateReturnOrderMethod::CopyDocument);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePurchReturnOrderByManuallyWithLotNo()
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
        CreateReturnOrderMethod: Option GetPostedDocumentLineToReserve,CopyDocument,ByManually;
    begin
        // Purchase Return Order  created by manually with Lot No. on Item Tracking Line.
        CalcPlanAfterCreatePurchReturnOrderWithIT(false, true, TrackingOption::SetLotNo, CreateReturnOrderMethod::ByManually);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,PostedSalesShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesReturnOrderApplFromPostedShptByGetPostedDocToRevWithSerialNo()
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
        CreateReturnOrderMethod: Option GetPostedDocumentLineToReserve,CopyDocument,ByManually;
    begin
        // Sales Return Order created by Get Posted Document Line To Reserve function and appl. from a Sales Shipment with Serial No. on Item Tracking Line.
        CalcPlanAfterCreateSalesReturnOrderWithIT(
          true, false, false, TrackingOption::AssignSerialNo, CreateReturnOrderMethod::GetPostedDocumentLineToReserve);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesReturnOrderApplFromPostedInvoiceByGetPostedDocToRevWithLotNo()
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
        CreateReturnOrderMethod: Option GetPostedDocumentLineToReserve,CopyDocument,ByManually;
    begin
        // Sales Return Order created by Get Posted Document Line To Reserve function and appl. from a Sales Invoice with Lot No. on Item Tracking Line.
        CalcPlanAfterCreateSalesReturnOrderWithIT(
          false, true, true, TrackingOption::SetLotNo, CreateReturnOrderMethod::GetPostedDocumentLineToReserve);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesReturnOrderApplFromPostedInvoiceByCopyDocWithSerialNo()
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
        CreateReturnOrderMethod: Option GetPostedDocumentLineToReserve,CopyDocument,ByManually;
    begin
        // Sales Return Order created by Copy Document function and appl. from a Sales Invoice with Serial No. on Item Tracking Line.
        CalcPlanAfterCreateSalesReturnOrderWithIT(true, false, true, TrackingOption::AssignSerialNo, CreateReturnOrderMethod::CopyDocument);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSalesLineDiscountPageforCustomerDiscountGroup()
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Check Customer Discount Group Code and Type on Sales line discount Page.

        // Setup: Create Customer Discount Group.
        Initialize();
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);

        // Exercise: Create Sales Discount line for Customer Discount Group.
        CreateLineDiscForCustomer(SalesLineDiscount, SalesLineDiscount."Sales Type"::"Customer Disc. Group", CustomerDiscountGroup.Code);

        // Verify: Verify Customer Discount Group Code and Type on Sales line discount Page.
        VerifySalesLineDiscountsOnPage(CustomerDiscountGroup, SalesLineDiscount.Type);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReasonCodeIsInheritedFromValueEntrytoGL()
    var
        Item: Record Item;
        ReasonCode: Record "Reason Code";
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [Post Inventory Cost To GL] [Reason Code]
        // [SCENARIO 379803] Reason Code field in General Ledger should be inherited from Item Journal on posting.
        Initialize();

        // [GIVEN] Posted Item Journal Line with Reason Code = "R".
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateReasonCode(ReasonCode);
        CreateAndPostItemJournalLineWithReasonCode(Item."No.", ReasonCode.Code);

        // [GIVEN] Adjust Cost-Item Entries batch job is run.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [WHEN] Post Inventory to G/L.
        LibraryVariableStorage.Enqueue(ValueEntriesWerePostedTxt);
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] General Ledger contains entries with Reason Code "R".
        GLEntry.Init();
        GLEntry.SetRange("Reason Code", ReasonCode.Code);
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostJobJournalLineWithNegativeQuantityOfServiceTypeItem()
    var
        Item: Record Item;
        JobJournalLine: Record "Job Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Inventory] [Item Type Service] [Job]
        // [SCENARIO 273186] When post job journal line with item of type Service with negative quantity the result negative adjustment item ledger entry has positive quantity
        Initialize();

        // [GIVEN] Item "I" with type Service
        LibraryInventory.CreateServiceTypeItem(Item);

        // [WHEN] Post job journal line with negative quantity "Q" of "I"
        CreateAndPostJobJournalLine(JobJournalLine, Item."No.", -LibraryRandom.RandInt(10));

        // [THEN] Item ledger entry contains the negative adjustment record for "I" with reverted (positive) quantity -"Q"
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
        ItemLedgerEntry.TestField(Quantity, -JobJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedItemShipmentWithReasonCode()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        Item: Record Item;
        ReasonCode: Record "Reason Code";
        GLEntry: Record "G/L Entry";
        InventorySetup: Record "Inventory Setup";
        ValueEntry: Record "Value Entry";
    begin
        // [SCENARIO 464704] Dealing with field reason code, behavior is different and not consistent comparing item journal with inventory shipment  where reason code is not kept.
        Initialize();

        // [GIVEN] Update Inventory Setup with "Automatic Cost Posting" = true and "Automatic Cost Adjustment" = Always
        UpdateInventorySetupWithAutomaticCostPosting(InventorySetup."Automatic Cost Adjustment"::Always);

        // [GIVEN] Create Location, Item  and Reason Code
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateReasonCode(ReasonCode);

        // [GIVEN] Create  Inventory Shipment with Shipment Line
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Shipment, Location.Code, '');

        // [GIVEN] Assign Posting No. on Inventory Document Header
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();

        // [GIVEN] Update Reason code and Unit Cost on Inventory Document Line
        InvtDocumentLine.Validate("Reason Code", ReasonCode.Code);
        InvtDocumentLine.Validate("Unit Cost", LibraryRandom.RandInt(10));
        InvtDocumentLine.Modify();

        // [WHEN] Post the Invt. Shipment document.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [VERIFY] Verify "G/L Entry" has Reason Code same as on  Inventory Document Line
        GLEntry.FindLast();
        Assert.AreEqual(ReasonCode.Code, GLEntry."Reason Code", ReasonCodeErr);

        // [VERIFY] Verify "Value Entry" has Reason Code same as on  Inventory Document Line
        ValueEntry.FindLast();
        Assert.AreEqual(ReasonCode.Code, ValueEntry."Reason Code", ReasonCodeErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedItemReceiptWithReasonCode()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        Item: Record Item;
        ReasonCode: Record "Reason Code";
        GLEntry: Record "G/L Entry";
        InventorySetup: Record "Inventory Setup";
        ValueEntry: Record "Value Entry";
    begin
        // [SCENARIO 464704] Dealing with field reason code, behavior is different and not consistent comparing item journal with inventory shipment  where reason code is not kept.
        Initialize();

        // [GIVEN] Update Inventory Setup with "Automatic Cost Posting" = true and "Automatic Cost Adjustment" = Always
        InventorySetup.Get();
        UpdateInventorySetupWithAutomaticCostPosting(InventorySetup."Automatic Cost Adjustment"::Always);


        // [GIVEN] Create Location, Item  and Reason Code
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateReasonCode(ReasonCode);

        // [GIVEN] Create  Inventory Shipment with Shipment Line
        CreateInvtDocumentWithLine(
          InvtDocumentHeader, InvtDocumentLine, Item, InvtDocumentHeader."Document Type"::Receipt, Location.Code, '');

        // [GIVEN] Assign Posting No. on Inventory Document Header
        InvtDocumentHeader."Posting No." := LibraryUtility.GenerateGUID();
        InvtDocumentHeader.Modify();

        // [GIVEN] Update Reason code and Unit Cost on Inventory Document Line
        InvtDocumentLine.Validate("Reason Code", ReasonCode.Code);
        InvtDocumentLine.Validate("Unit Cost", LibraryRandom.RandInt(10));
        InvtDocumentLine.Modify();

        // [WHEN] Post the Invt. Shipment document.
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [VERIFY] Verify "G/L Entry" has Reason Code same as on  Inventory Document Line
        GLEntry.FindLast();
        Assert.AreEqual(ReasonCode.Code, GLEntry."Reason Code", ReasonCodeErr);

        // [VERIFY] Verify "Value Entry" has Reason Code same as on  Inventory Document Line
        ValueEntry.FindLast();
        Assert.AreEqual(ReasonCode.Code, ValueEntry."Reason Code", ReasonCodeErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PriceListLine: Record "Price List Line";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Misc. III");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;

        PriceListLine.DeleteAll();

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Misc. III");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        UpdateInventorySetupCostPosting();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Misc. III");
    end;

    local procedure AssignLotNoOnBoundProductionOrder(var ProdOrderLine: Record "Prod. Order Line")
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::SetLotNo);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity);
        ProdOrderLine.OpenItemTrackingLines();
    end;

    local procedure AssignLotNoOnBoundPurchaseOrder(var PurchaseLine: Record "Purchase Line"; LotNo: Code[50])
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::SetLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure AssignLotNoOnBoundSalesOrder(var SalesLine: Record "Sales Line"; LotNo: Code[50])
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::SetLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CalculateWhseAdjustment(Item: Record Item)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CalcPlanAfterCreateSalesReturnOrderWithIT(Serial: Boolean; Lot: Boolean; Invoice: Boolean; TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry; CreateReturnOrderMethod: Option GetPostedDocumentLineToReserve,CopyDocument,ByManually)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SellToCustomerNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify 1.Values in Item Tracking Line are correct on existing Sales Return Orders after calculate Plan in Requisition Worksheet.
        // 2.Sales Return Order can be posted successfully when "Exact Cost Reversing Mandatory" is enabled.

        // Setup: Update Sales Receivable Setup: "Exact Cost Reversing Mandatory" is enabled.
        Initialize();
        SalesReceivablesSetup.Get();
        UpdateSalesReceivablesSetup(true, SalesReceivablesSetup."Stockout Warning");

        // Create Tracked Item, Create and post Purchase and Sales Order with Item Tracking.
        CreateTrackedItemWithReorderingPolicy(Item, Serial, Lot, Item."Reordering Policy"::"Lot-for-Lot");
        CreateAndPostPurchaseOrderWithIT(PurchaseHeader, Item."No.", TrackingOption, LibraryRandom.RandInt(100), 1); // Make Item has inventory.
        DocumentNo := CreateAndPostSalesOrderWithIT(SellToCustomerNo, Item."No.", 1, TrackingOption::SelectEntries, true, Invoice); // Quantity is 1, as Quantity(Base) cannot be more than 1 with Serial No.

        // Create Sales Return Order with Item Tracking.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Sale);
        case CreateReturnOrderMethod of
            CreateReturnOrderMethod::GetPostedDocumentLineToReserve:
                CreateSalesReturnOrderByGetPstdDocLineToRev(SalesHeader, Item, SellToCustomerNo, DocumentNo);
            CreateReturnOrderMethod::CopyDocument:
                if Invoice then
                    CreateSalesReturnOrderByCopyDocument(
                        SalesHeader, SellToCustomerNo, DocumentNo, "Sales Document Type From"::"Posted Invoice", false)
                else
                    CreateSalesReturnOrderByCopyDocument(
                        SalesHeader, SellToCustomerNo, DocumentNo, "Sales Document Type From"::"Posted Shipment", true);
            CreateReturnOrderMethod::ByManually:
                CreateSalesReturnOrderWithApplFromItemEntryOnItemTrackingLine(
                  SalesHeader, SellToCustomerNo, Item."No.", ItemLedgerEntry."Lot No.", 1, ItemLedgerEntry."Entry No."); // Quantity is 1, as Quantity(Base) cannot be more than 1 with Serial No.
        end;

        // Exercise: Calculate Plan on Requisition Worksheets.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), CalcDate('<CM>', WorkDate()));

        // Verify: The values on Item Tracking Line is correct on existing Sales Return Orders.
        if Lot then
            VerifyValuesOnTrackingLine(
              SalesHeader."Document Type", SalesHeader."No.", Item."No.",
              ItemLedgerEntry."Lot No.", '', ItemLedgerEntry."Entry No.", ItemLedgerEntry.Quantity);
        if Serial then
            VerifyValuesOnTrackingLine(
              SalesHeader."Document Type", SalesHeader."No.", Item."No.", '',
              ItemLedgerEntry."Serial No.", ItemLedgerEntry."Entry No.", ItemLedgerEntry.Quantity);

        // Exercise and Verify: Verify the Sales Return Order can be posted successfully.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Tear Down.
        UpdateSalesReceivablesSetup(SalesReceivablesSetup."Exact Cost Reversing Mandatory", SalesReceivablesSetup."Stockout Warning");
    end;

    local procedure CalcPlanAfterCreatePurchReturnOrderWithIT(Serial: Boolean; Lot: Boolean; TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry; CreateReturnOrderMethod: Option GetPostedDocumentLineToReserve,CopyDocument,ByManually)
    var
        Item: Record Item;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        DocumentNo: Code[20];
    begin
        // Verify 1.Value in Appl.-to Item Entry is correct on existing Purchase Return Orders after calculate Plan in Requisition Worksheet.
        // 2.Purchase Return Order can be posted successfully when "Exact Cost Reversing Mandatory" is enabled.

        // Setup: Update Purchase Payable Setup: "Exact Cost Reversing Mandatory" is enabled.
        Initialize();
        PurchasesPayablesSetup.Get();
        UpdatePurchasesPayablesSetup(true);

        // Create Item, Create and post Purchase Order with Item Tracking.
        CreateTrackedItemWithReorderingPolicy(Item, Serial, Lot, Item."Reordering Policy"::"Lot-for-Lot");
        DocumentNo := CreateAndPostPurchaseOrderWithIT(PurchaseHeader, Item."No.", TrackingOption, 1, 1); // Quantity is 1, as Quantity(Base) cannot be more than 1 for Serial No.

        // Create Purchase Return Order with Item Tracking.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Purchase);
        case CreateReturnOrderMethod of
            CreateReturnOrderMethod::GetPostedDocumentLineToReserve:
                begin
                    LibraryVariableStorage.Enqueue(DocumentNo);
                    CreatePurchRetOrderGetPstdDocLineToRev(PurchaseHeader2, PurchaseHeader."Buy-from Vendor No.");
                end;
            CreateReturnOrderMethod::CopyDocument:
                begin
                    LibraryPurchase.CreatePurchHeader(
                      PurchaseHeader2, PurchaseHeader2."Document Type"::"Return Order", PurchaseHeader."Buy-from Vendor No.");
                    LibraryPurchase.CopyPurchaseDocument(PurchaseHeader2, "Purchase Document Type From"::"Posted Invoice", DocumentNo, true, true);
                    PurchaseHeader2.Get(PurchaseHeader2."Document Type", PurchaseHeader2."No.");
                end;
            CreateReturnOrderMethod::ByManually:
                CreatePurchReturnOrderWithApplToItemEntryOnItemTrackingLine(
                  PurchaseHeader2, PurchaseHeader."Buy-from Vendor No.", Item."No.",
                  ItemLedgerEntry."Lot No.", ItemLedgerEntry.Quantity, ItemLedgerEntry."Entry No.");
        end;

        // Exercise: Calculate Plan on Requisition Worksheets.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), CalcDate('<CM>', WorkDate()));

        // Verify: The value of Appl.-to Item Entry of Item Tracking Line is correct on existing Purchase Return Orders.
        VerifyApplToItemEntryOnTrackingLine(
          PurchaseHeader2."Document Type", PurchaseHeader2."No.", Item."No.", ItemLedgerEntry."Entry No.");

        // Exercise and Verify: Verify the Purchase Return Order can be posted successfully.
        PostPurchaseReturnOrder(PurchaseHeader2);

        // Tear Down.
        UpdatePurchasesPayablesSetup(PurchasesPayablesSetup."Exact Cost Reversing Mandatory");
    end;

    local procedure CloseFiscalYear()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.Count > 1 then begin
            LibraryVariableStorage.Enqueue(ClosedFiscalYear);  // Enqueue for ConfirmHandler.
            LibraryVariableStorage.Enqueue(ClosedFiscalYear);  // Enqueue for ConfirmHandler.
            LibraryFiscalYear.CloseFiscalYear();
        end;
    end;

    local procedure CreateAndModifyItem(ReplenishmentSystem: Enum "Replenishment System"; CostingMethod: Enum "Costing Method"): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem(ReplenishmentSystem));
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Overhead Rate", LibraryRandom.RandDec(10, 2));  // Using Random value for Overhead Rate.
        Item.Validate("Standard Cost", LibraryRandom.RandDec(100, 1));  // Using Random value for Standard Cost.
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 1));  // Using Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    begin
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));  // Use random Quantity and Unit Cost.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournalLineWithReasonCode(ItemNo: Code[20]; ReasonCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Reason Code", ReasonCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; No: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrder(PurchaseLine, No);
        UpdateGeneralPostingSetup(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseOrderWithIT(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo; Quantity: Integer; LineCount: Integer): Code[20]
    var
        ReservationEntry: Record "Reservation Entry";
        PurchaseLine: Record "Purchase Line";
        LotNo: Code[50];
        "count": Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LotNo := LibraryUtility.GenerateRandomCode(ReservationEntry.FieldNo("Lot No."), DATABASE::"Reservation Entry");

        for count := 1 to LineCount do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Use Random Direct Unit Cost.
            PurchaseLine.Modify(true);
            LibraryVariableStorage.Enqueue(TrackingOption);  // Enqueue value for ItemTrackingLinesPageHandler.
            if TrackingOption = TrackingOption::SetLotNo then begin
                LibraryVariableStorage.Enqueue(LotNo);
                LibraryVariableStorage.Enqueue(PurchaseLine."Quantity (Base)");
            end;
            PurchaseLine.OpenItemTrackingLines();
        end;

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesOrderWithIT(var SellToCustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Integer; TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo; Ship: Boolean; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        ReservationEntry: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        LotNo: Code[50];
    begin
        SalesHeader.Init();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);

        LibraryVariableStorage.Enqueue(TrackingOption); // Enqueue value for ItemTrackingLinesPageHandler.
        if TrackingOption = TrackingOption::SetLotNo then begin
            LotNo := LibraryUtility.GenerateRandomCode(ReservationEntry.FieldNo("Lot No."), DATABASE::"Reservation Entry");
            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue(SalesLine."Quantity (Base)");
        end;
        SalesLine.OpenItemTrackingLines();
        SellToCustomerNo := SalesHeader."Sell-to Customer No.";
        exit(LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice));
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(Item."Replenishment System"::Purchase),
          LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndParitialShipSalesOrderWithNegativeQty(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; No: Code[20]; Quantity: Decimal; Invoice: Boolean): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, Quantity);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        ItemLedgerEntry.SetRange("Item No.", No);
        ItemLedgerEntry.FindFirst();
        SalesLine.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");

        // Update the "Qty. to Ship"=-(ABS(SalesLine."Qty. to Ship") - 1,ABS(SalesLine."Qty. to Ship") / 2),
        // not repro when the ABS("Qty. to Ship") is less than original ABS(SalesLine."Qty. to Ship") / 2.
        SalesLine.Validate("Qty. to Ship",
          -LibraryRandom.RandDecInDecimalRange(-SalesLine."Qty. to Ship" / 2 + 0.01, -SalesLine."Qty. to Ship" - 0.01, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, Invoice);
        SalesLine.GetBySystemId(SalesLine.SystemId);
        exit(SalesLine."Quantity Shipped");
    end;

    local procedure CreateAndPostJobJournalLine(var JobJournalLine: Record "Job Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::" ", JobTask, JobJournalLine);
        JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
        JobJournalLine.Validate("No.", ItemNo);
        JobJournalLine.Validate(Quantity, Quantity);
        JobJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        JobJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(PostJournalLines);  // Enqueue for MessageHandler.
        LibraryVariableStorage.Enqueue(UsageNotLinkedToBlankLineTypeMsg); // Enqueue for MessageHandler.
        LibraryVariableStorage.Enqueue(SuccessfullyPostLines);  // Enqueue for MessageHandler.
        LibraryJob.PostJobJournal(JobJournalLine);
    end;

    local procedure CreateAndReceivePurchOrderWithItemCharge(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        Item: Record Item;
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        CreatePurchaseOrder(PurchaseLine, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO));

        // Create ItemCharge Assign Purchase.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), PurchaseLine.Quantity);
        PurchaseLine2.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Use random value for Amount.
        PurchaseLine2.Modify(true);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine2, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Order, PurchaseHeader."No.",
          PurchaseLine."Line No.", PurchaseLine."No.");
        UpdateGeneralPostingSetup(PurchaseLine2);

        // Receive purchase order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateAndRegisterWhseJournal(ItemNo: Code[20])
    var
        Bin: Record Bin;
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        CreateWarehouseLocation(Location);
        LibraryWarehouse.FindBin(Bin, Location.Code, FindZone(Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true)), 1);  // Use 1 for Bin Index.
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, Bin."Zone Code",
          Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, 5);  // Value Zero Important for test.
        LibraryVariableStorage.Enqueue(WarehouseJournalLine.Quantity);
        WarehouseJournalLine.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(RegisterJournalLines);
        LibraryVariableStorage.Enqueue(JournalLinesRegistered);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, false);
    end;

    local procedure CreateAndUpdateSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateSalesOrderWithOrderDate(SalesLine, CustomerNo, ItemNo, WorkDate(), '', Quantity);
        SalesLine.Validate("Qty. to Invoice", SalesLine."Qty. to Invoice" / 2);  // Take partial Quantity.
        SalesLine.Modify(true);
    end;

    local procedure CreateAndUpdateCustomer(CustomerPricingGroup: Code[10]; VATBusPostingGroup: Code[20]; CustomerDiscountGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer.Validate("Customer Price Group", CustomerPricingGroup);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Customer Disc. Group", CustomerDiscountGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateAndUpdateSalesPrice(var SalesPrice: Record "Sales Price"; VATBusPostingGrPrice: Code[20]; ItemNo: Code[20]; SalesType: Enum "Sales Price Type"; SalesCode: Code[20])
    begin
        CreateSalesPrice(SalesPrice, ItemNo, SalesType, SalesCode, LibraryRandom.RandDec(10, 2), '');  // Take random for Quantity.
        SalesPrice.Validate("Price Includes VAT", true);
        SalesPrice.Validate("VAT Bus. Posting Gr. (Price)", VATBusPostingGrPrice);
        SalesPrice.Modify(true);
    end;

    local procedure CreateLotWhseTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateLineDiscForCustomer(var SalesLineDiscount: Record "Sales Line Discount"; SalesType: Option; SalesCode: Code[20])
    var
        Item: Record Item;
    begin
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item,
          CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO), SalesType, SalesCode, WorkDate(), '', '', '',
          LibraryRandom.RandDec(10, 2));  // Take random for Minimum Quantity.
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));  // Take random for Line Discount Pct.
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateItem(ReplenishmentSystem: Enum "Replenishment System"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithVAT(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO));
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateTrackedItemWithReorderingPolicy(var Item: Record Item; Serial: Boolean; Lot: Boolean; ReorderingPolicy: Enum "Reordering Policy")
    begin
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(Serial, Lot));
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateReleasedProductionOrderFromSalesOrder(var ProductionOrder: Record "Production Order"; SalesHeader: Record "Sales Header")
    begin
        LibraryVariableStorage.Enqueue(ProductionOrderCreatedMsg);  // Enqueue variable for created Production Order message in MessageHandler.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(SalesHeader, ProductionOrder.Status::Released, "Create Production Order Type"::ItemOrder);
    end;

    local procedure CreateProdOrderFromSalesOrder(var SalesLine: Record "Sales Line"; Status: Enum "Production Order Status"; OrderType: Enum "Create Production Order Type")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(Item."Replenishment System"::"Prod. Order"),
          LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        LibraryVariableStorage.Enqueue(ProdOrderCreated);  // Enqueue for MessageHandler.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(SalesHeader, Status, OrderType);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, LibraryRandom.RandDec(10, 2));  // Use random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Use Random Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithItemTracking(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; Quantity: Decimal; LotNo: Code[50])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        AssignLotNoOnBoundPurchaseOrder(PurchaseLine, LotNo);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", UnitCost);  // random unit cost.
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemJournalLineForPhysInv(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::"Phys. Inventory");
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
    end;

    local procedure CreateItemTrackingCode(SNSpecific: Boolean; LOTSpecific: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LOTSpecific);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LOTSpecific);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateandPostItemJournalForRevaluation(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
        NoSeries: Codeunit "No. Series";
    begin
        Item.SetRange("No.", ItemNo);
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Revaluation);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, WorkDate(), NoSeries.PeekNextNo(ItemJournalBatch."No. Series"), "Inventory Value Calc. Per"::Item,
          false, false, false, "Inventory Value Calc. Base"::" ", false);
        ItemJournalLine.SetRange("Item No.", ItemJournalLine."Item No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", LibraryRandom.RandInt(10));
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateSalesRetOrderGetPstdDocLineToRev(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]; DocumentNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SellToCustomerNo);
        LibraryVariableStorage.Enqueue(DocumentNo); // Enqueue value for PostedSalesDocumentLinesPageHandler / PostedSalesShipmentLinesPageHandler.
        GetPostedDocToReverseOnSalesReturnOrder(SalesHeader."No.");
    end;

    local procedure CreateSalesReturnOrderByGetPstdDocLineToRev(var SalesHeader: Record "Sales Header"; Item: Record Item; SellToCustomerNo: Code[20]; DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesRetOrderGetPstdDocLineToRev(SalesHeader, SellToCustomerNo, DocumentNo);
        FindSalesLine(SalesLine, SalesLine."Document Type"::"Return Order", SalesHeader."No.", Item."No.");
        SalesLine.Validate("VAT Identifier", Item."VAT Prod. Posting Group"); // It requires for IT database.
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesReturnOrderByCopyDocument(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; RecalcLines: Boolean)
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Return Order", SellToCustomerNo);
        LibrarySales.CopySalesDocument(SalesHeader, DocumentType, DocumentNo, true, RecalcLines);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
    end;

    local procedure CreatePurchRetOrderGetPstdDocLineToRev(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", BuyFromVendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        GetPostedDocToReverseOnPurchReturnOrder(PurchaseHeader."No.");
    end;

    local procedure CreateSalesOrderWithSalesPriceOnCustomer(var SalesLine: Record "Sales Line"; PostingDate: Date)
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
    begin
        // Create Item, Customer, create Sales Price and Sales Order.
        CreateSalesPrice(
          SalesPrice, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO),
          "Sales Price Type"::Customer, CreateCustomer(), 0, '');  // 0 for Minimum Qunatity.
        CopyAllSalesPriceToPriceListLine();
        CreateSalesOrderWithOrderDate(
          SalesLine, SalesPrice."Sales Code", SalesPrice."Item No.", PostingDate, '', LibraryRandom.RandDec(10, 2));  // Take random for Quantity.
    end;

    local procedure CreateSalesPriceWithCustomerPriceGroup(var SalesPrice: Record "Sales Price")
    var
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
    begin
        // Create Customer and update Customer Pricing Group on Customer, create Sales Price with Sales Type Customer Pricing Group.
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CreateSalesPrice(
          SalesPrice, CreateAndModifyItem(Item."Replenishment System"::Purchase, Item."Costing Method"::FIFO),
          "Sales Price Type"::"Customer Price Group", CustomerPriceGroup.Code, 0, '');  // 0 for Minimum Quantity.
    end;

    local procedure CreateSalesOrderWithItemTracking(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; Quantity: Decimal; LotNo: Code[50])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        AssignLotNoOnBoundSalesOrder(SalesLine, LotNo);
    end;

    local procedure CreateSalesReturnOrderWithApplFromItemEntryOnItemTrackingLine(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal; EntryNo: Option)
    var
        SalesLine: Record "Sales Line";
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SellToCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        AssignLotNoOnBoundSalesOrder(SalesLine, LotNo);

        LibraryVariableStorage.Enqueue(TrackingOption::SetApplFromItemEntry); // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(EntryNo);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchReturnOrderWithApplToItemEntryOnItemTrackingLine(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal; EntryNo: Option)
    var
        PurchaseLine: Record "Purchase Line";
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", BuyFromVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        AssignLotNoOnBoundPurchaseOrder(PurchaseLine, LotNo);

        LibraryVariableStorage.Enqueue(TrackingOption::SetApplToItemEntry); // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(EntryNo);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesOrderWithOrderDate(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; OrderDate: Date; CurrencyCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Order Date", OrderDate);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesPrice(var SalesPrice: Record "Sales Price"; ItemNo: Code[20]; SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; Quantity: Decimal; CurrencyCode: Code[10])
    begin
        LibraryCosting.CreateSalesPrice(SalesPrice, SalesType, SalesCode, ItemNo, WorkDate(), CurrencyCode, '', '', Quantity);
        SalesPrice.Validate("Ending Date", WorkDate());
        SalesPrice.Validate("Unit Price", LibraryRandom.RandDec(5, 2));  // Take random value for Unit Price.
        SalesPrice.Modify(true);
    end;

    local procedure CreateTrackedItemWithReplenishmentSystem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateLotWhseTrackingCode());
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateWarehouseLocation(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateReservationForBoundPurchaseOrder(var PurchaseLine: Record "Purchase Line")
    var
        ReservOption: Option AutoReserve,CancelReserv;
    begin
        LibraryVariableStorage.Enqueue(ReservOption::AutoReserve);
        PurchaseLine.ShowReservation();
    end;

    local procedure CreateReservationForBoundSalesOrder(var SalesLine: Record "Sales Line")
    var
        ReservOption: Option AutoReserve,CancelReserv;
    begin
        LibraryVariableStorage.Enqueue(ReservOption::AutoReserve);
        SalesLine.ShowReservation();
    end;

    local procedure CreateProdOrderFromSalesOrderUsingPlanning(var SalesLine: Record "Sales Line")
    var
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateTrackedItemWithReplenishmentSystem(),
          LibraryRandom.RandDec(10, 2));
        CreateReleasedProductionOrderFromSalesOrder(ProductionOrder, SalesHeader);
    end;

    local procedure CancelReservationOnProductionOrder(ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ReservOption: Option AutoReserve,CancelReserv;
    begin
        FindProdOrderLine(ProdOrderLine, ItemNo);
        LibraryVariableStorage.Enqueue(ReservOption::CancelReserv);  // Enqueue for ReservationPageHandler.
        LibraryVariableStorage.Enqueue(CancelReservationMessage);  // Enqueue for ConfirmHandler.
        ProdOrderLine.ShowReservation();
    end;

    local procedure CancelReservationOnBoundPurchaseOrder(var PurchaseLine: Record "Purchase Line")
    var
        ReservOption: Option AutoReserve,CancelReserv;
    begin
        LibraryVariableStorage.Enqueue(ReservOption::CancelReserv);
        PurchaseLine.ShowReservation();
    end;

    local procedure CancelReservationOnBoundSalesOrder(var SalesLine: Record "Sales Line")
    var
        ReservOption: Option AutoReserve,CancelReserv;
    begin
        LibraryVariableStorage.Enqueue(ReservOption::CancelReserv);
        SalesLine.ShowReservation();
    end;

    local procedure DeletePhysInvLedger(ItemNo: Code[20])
    var
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
        DeletePhysInventoryLedger: Report "Delete Phys. Inventory Ledger";
    begin
        LibraryVariableStorage.Enqueue(DeleteEntriesQst);
        Clear(DeletePhysInventoryLedger);
        PhysInventoryLedgerEntry.SetRange("Item No.", ItemNo);
        DeletePhysInventoryLedger.SetTableView(PhysInventoryLedgerEntry);
        DeletePhysInventoryLedger.Run();
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type")
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20])
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindZone(LocationCode: Code[10]; BinTypeCode: Code[10]): Code[10]
    var
        Zone: Record Zone;
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", BinTypeCode);
        Zone.FindFirst();
        exit(Zone.Code);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; No: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure GetPostedDocToReverseOnPurchReturnOrder(No: Code[20])
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", No);
        PurchaseReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure GetPostedDocToReverseOnSalesReturnOrder(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure CalculatePlanForRequisitionWorksheet(var RequisitionWkshName: Record "Requisition Wksh. Name"; var Item: Record Item; StartDate: Date; EndDate: Date)
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::"Req.");
        RequisitionWkshName.FindFirst();
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, StartDate, EndDate);
    end;

    local procedure UpdateItemInvPostingGroup(var Item: Record Item)
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        InventoryPostingGroup.SetFilter(Code, '<>%1', Item."Inventory Posting Group");
        InventoryPostingGroup.FindFirst();
        Item.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        Item.Modify(true);
    end;

    local procedure UpdateGeneralPostingSetup(PurchaseLine: Record "Purchase Line")
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        if GeneralPostingSetup."Purch. Account" = '' then begin
            LibraryERM.FindGLAccount(GLAccount);
            GeneralPostingSetup.Validate("Purch. Account", GLAccount."No.");
            GeneralPostingSetup.Modify(true);
        end;
    end;

    local procedure UpdateQuantityOnSalesLine(SalesLine: Record "Sales Line") Quantity: Decimal
    begin
        Quantity := SalesLine.Quantity;
        SalesLine.Validate(Quantity, SalesLine.Quantity + LibraryRandom.RandDec(10, 2));  // Take random Quantity.
        SalesLine.Modify(true);
    end;

    local procedure UpdateQtyAndInvoicePurchaseOrder(PurchaseLine: Record "Purchase Line") DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Update Quantity to Invoice on Purchase Line with Type Item, and Invoice Item Charge.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Invoice", 0);
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // Invoice Purchase Order.
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
    end;

    local procedure UpdateReturnQtyToReceiveOnSalesLine(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetFilter("No.", '<>%1', '');
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();

        // Update the "Return Qty. to Receive"=(SalesLine."Return Qty. to Receive" / 2,SalesLine."Return Qty. to Receive"),
        // not repro when the "Return Qty. to Receive" is less than original SalesLine."Return Qty. to Receive" / 2.
        SalesLine.Validate("Return Qty. to Receive",
          LibraryRandom.RandDecInDecimalRange(SalesLine."Return Qty. to Receive" / 2 + 0.01,
            SalesLine."Return Qty. to Receive" - 0.01, 2));
        SalesLine.Modify(true);
        exit(SalesLine."Return Qty. to Receive");
    end;

    local procedure UpdateReturnQtyToShipOnPurchLine(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetFilter("No.", '<>%1', '');
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();

        // Update the "Return Qty. to Ship"=(PurchaseLine."Return Qty. to Ship" / 2,PurchaseLine."Return Qty. to Ship"),
        // not repro when the "Return Qty. to Ship" is less than  original PurchaseLine."Return Qty. to Ship" / 2.
        PurchaseLine.Validate("Return Qty. to Ship",
          LibraryRandom.RandDecInDecimalRange(PurchaseLine."Return Qty. to Ship" / 2 + 0.01,
            PurchaseLine."Return Qty. to Ship" - 0.01, 2));
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Return Qty. to Ship");
    end;

    local procedure UpdateQtyOnSalesReturnOrder(DocumentNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", DocumentNo);
        SalesReturnOrder.SalesLines.FILTER.SetFilter("No.", ItemNo);
        SalesReturnOrder.SalesLines.Quantity.SetValue(Qty);
    end;

    local procedure UpdateQtyOnSalesOrder(DocumentNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", DocumentNo);
        SalesOrder.SalesLines.FILTER.SetFilter("No.", ItemNo);
        SalesOrder.SalesLines.Quantity.SetValue(Qty);
    end;

    local procedure UpdateQtyOnPurchReturnOrder(DocumentNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", DocumentNo);
        PurchaseReturnOrder.PurchLines.FILTER.SetFilter("No.", ItemNo);
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(Qty);
    end;

    local procedure PostPurchaseDocument(PurchaseHeader: Record "Purchase Header")
    begin
        ExecuteUIHandler();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostPurchaseReturnOrder(PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostSalesDocument(SalesLine: Record "Sales Line"; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        ExecuteUIHandler();
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));
    end;

    local procedure RunCalculateInventoryReport(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    begin
        CreateItemJournalLineForPhysInv(ItemJournalLine);
        LibraryInventory.CalculateInventoryForSingleItem(ItemJournalLine, ItemNo, WorkDate(), true, false);
    end;

    local procedure RunRollUpStandardCost(StandardCostWorksheetName: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        Item: Record Item;
        RollUpStandardCost: Report "Roll Up Standard Cost";
    begin
        Commit();  // Commit required for batch job reports.
        Item.SetFilter("No.", StrSubstNo(ItemFilter, ItemNo, ItemNo2));
        Item.Get(ItemNo);
        Item.SetRange("Inventory Posting Group", Item."Inventory Posting Group");
        Clear(RollUpStandardCost);
        RollUpStandardCost.SetTableView(Item);
        RollUpStandardCost.SetStdCostWksh(StandardCostWorksheetName);
        RollUpStandardCost.UseRequestPage(true);
        RollUpStandardCost.Run();
    end;

    local procedure SalesPriceForPriceInclVAT(VATPostingSetup: Record "VAT Posting Setup"; SalesType: Enum "Sales Price Type"; SalesCode: Code[20]; CusomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        UnitPrice: Decimal;
    begin
        CreateAndUpdateSalesPrice(
          SalesPrice, VATPostingSetup."VAT Bus. Posting Group", CreateItemWithVAT(VATPostingSetup."VAT Prod. Posting Group"), SalesType,
          SalesCode);
        CopyAllSalesPriceToPriceListLine();

        // Exercise: Create Sales Order.
        CreateSalesOrderWithOrderDate(SalesLine, CusomerNo, SalesPrice."Item No.", WorkDate(), '', SalesPrice."Minimum Quantity");

        // Verify: Verify Unit Price on Sales Line with Price Including VAT TRUE.
        UnitPrice := SalesPrice."Unit Price" - (SalesPrice."Unit Price" * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
        Assert.AreNearlyEqual(
          UnitPrice, SalesLine."Unit Price", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, SalesLine.FieldCaption("Unit Price"), UnitPrice));
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure UpdateApplyToItemEntryOnPurchLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetFilter("No.", '<>''''');
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Return Order");
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
        repeat
            PurchaseLine.Validate("Appl.-to Item Entry", 0);
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure UpdateApplyFromItemEntryOnSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetFilter("No.", '<>''''');
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        SalesLine.Validate("Appl.-from Item Entry", 0);
        SalesLine.Modify(true);
    end;

    local procedure UpdateInventorySetup(AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryVariableStorage.Enqueue(UnadjustedValueEntriesMessage);
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateItemDimension(ItemNo: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure UpdateCountingPeriodOnItem(Item: Record Item)
    var
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
    begin
        LibraryInventory.CreatePhysicalInventoryCountingPeriod(PhysInvtCountingPeriod);
        Item.Validate("Phys Invt Counting Period Code", PhysInvtCountingPeriod.Code);
        Item.Modify(true);
    end;

    local procedure UpdateItemBaseUnitOfMeasure(Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
    end;

    local procedure UpdateItemJournalLineAppliesToEntry(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemJournalLine."Item No.", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateQtyOnPhysInvJournal(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Qty. (Phys. Inventory)", ItemJournalLine."Qty. (Phys. Inventory)" / 2);
        ItemJournalLine.Modify(true);
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal; CostAmountActual: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemNo, EntryType);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField(Quantity, Quantity);
        Assert.AreNearlyEqual(
          CostAmountActual, ItemLedgerEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual));
    end;

    local procedure CreateAndUpdateCustPriceGroup(VATBusPostingGrPrice: Code[20]): Code[10]
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPriceGroup.Validate("Price Includes VAT", true);
        CustomerPriceGroup.Validate("VAT Bus. Posting Gr. (Price)", VATBusPostingGrPrice);
        CustomerPriceGroup.Modify(true);
        exit(CustomerPriceGroup.Code);
    end;

    local procedure UpdateDiscOnSalesLineDiscount(SalesLineDiscount: Record "Sales Line Discount"): Decimal
    begin
        SalesLineDiscount.Validate("Line Discount %", SalesLineDiscount."Line Discount %" + LibraryRandom.RandDec(10, 2));  // Take random for update Line Discount Pct.
        SalesLineDiscount.Modify(true);
        exit(SalesLineDiscount."Line Discount %");
    end;

    local procedure UpdatePurchasesPayablesSetup(ExactCostReversingMandatory: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(ExactCostReversingMandatory: Boolean; StockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateUnitPriceOnSalesPrice(SalesPrice: Record "Sales Price"): Decimal
    begin
        SalesPrice.Validate("Unit Price", SalesPrice."Unit Price" + LibraryRandom.RandDec(10, 2));  // Take random fo update Unit Price.
        SalesPrice.Modify(true);
        exit(SalesPrice."Unit Price");
    end;

    local procedure VerifyGLEntries(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyStandardCost(No: Code[20]; StandardCost: Decimal)
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
    begin
        StandardCostWorksheet.SetRange("No.", No);
        StandardCostWorksheet.FindFirst();
        StandardCostWorksheet.TestField("Standard Cost", StandardCost);
    end;

    local procedure VerifyQuantityOnProdOrderLine(ItemNo: Code[20]; Quantity: Decimal; ReservedQuantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProdOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField(Quantity, Quantity);
        ProdOrderLine.CalcFields("Reserved Quantity");
        ProdOrderLine.TestField("Reserved Quantity", ReservedQuantity);
    end;

    local procedure VerifyPhysInvJournalQty(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Qty. (Calculated)", Quantity);
        ItemJournalLine.TestField("Qty. (Phys. Inventory)", Quantity);
    end;

    local procedure VerifySalesInvoiceLine(DocumentNo: Code[20]; UnitPrice: Decimal; LineDiscountPct: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetFilter("No.", '<>''''');
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Unit Price", UnitPrice);
        SalesInvoiceLine.TestField("Line Discount %", LineDiscountPct);
    end;

    local procedure VerifyValueEntry(ItemLedgerEntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; CostAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange(Adjustment, true);
        ValueEntry.FindFirst();
        Assert.AreNearlyEqual(
          CostAmount, ValueEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), CostAmount));
    end;

    [Normal]
    local procedure VerifyValueEntryNoApplication(ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Credit Memo");
        ValueEntry.SetRange(Adjustment, false);
        ValueEntry.FindSet();
        repeat
            ValueEntry.TestField("Applies-to Entry", 0);
        until ValueEntry.Next() = 0;
    end;

    local procedure VerifyShipmentAndExpRcptDateOnReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; SourceType: Integer; SourceSubType: Option; Positive: Boolean; ShipmentDate: Date; ExpectedReceiptDate: Date)
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source Subtype", SourceSubType);
        ReservationEntry.SetRange(Positive, Positive);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Shipment Date", ShipmentDate);
        ReservationEntry.TestField("Expected Receipt Date", ExpectedReceiptDate);
    end;

    local procedure VerifyValuesOnTrackingLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; SerialNo: Code[50]; EntryNo: Integer; Quantity: Integer)
    var
        SalesLine: Record "Sales Line";
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::VerifyApplFromItemEntry);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(EntryNo);
        LibraryVariableStorage.Enqueue(-Quantity);
        FindSalesLine(SalesLine, DocumentType, DocumentNo, ItemNo);
        SalesLine.OpenItemTrackingLines(); // Verify values on ItemTrackingLinesPageHandler.
    end;

    local procedure VerifyApplToItemEntryOnTrackingLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; ItemNo: Code[20]; EntryNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::VerifyApplToItemEntry);
        LibraryVariableStorage.Enqueue(EntryNo);
        FindPurchaseLine(PurchaseLine, DocumentType, DocumentNo, ItemNo);
        PurchaseLine.OpenItemTrackingLines(); // Verify Appl.-to Item Entry on ItemTrackingLinesPageHandler.
    end;

    local procedure VerifySalesLineDiscountsOnPage(CustomerDiscountGroup: Record "Customer Discount Group"; SalesLineDiscountType: Enum "Sales Line Discount Type")
    var
        CustomerDiscGroups: TestPage "Customer Disc. Groups";
        SalesLineDiscounts: TestPage "Sales Line Discounts";
    begin
        CustomerDiscGroups.OpenEdit();
        CustomerDiscGroups.GotoRecord(CustomerDiscountGroup);
        SalesLineDiscounts.Trap();
        CustomerDiscGroups.SalesLineDiscounts.Invoke();
        SalesLineDiscounts.SalesCodeFilterCtrl.AssertEquals(CustomerDiscountGroup.Code);
        SalesLineDiscounts.Type.AssertEquals(SalesLineDiscountType);
    end;

    local procedure UpdateInventorySetupCostPosting()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", false);
        InventorySetup.Modify(true);
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

    local procedure UpdateInventorySetupWithAutomaticCostPosting(AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryVariableStorage.Enqueue(UnadjustedValueEntriesMessage);
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Validate("Automatic Cost Posting", true);
        InventorySetup.Modify(true);
    end;


    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePhysInvtCountingPageHandler(var CalculatePhysInvtCounting: TestRequestPage "Calculate Phys. Invt. Counting")
    begin
        CalculatePhysInvtCounting.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckProdOrderStatusPageHandler(var CheckProdOrderStatus: TestPage "Check Prod. Order Status")
    begin
        CheckProdOrderStatus.Yes().Invoke();
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CreditMemoConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeletePhysInventoryLedgerPageHandler(var DeletePhysInventoryLedger: TestRequestPage "Delete Phys. Inventory Ledger")
    begin
        DeletePhysInventoryLedger.StartingDate.SetValue(WorkDate());
        DeletePhysInventoryLedger.EndingDate.SetValue(WorkDate());
        DeletePhysInventoryLedger.OK().Invoke();
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
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue Variable.
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtItemSelectionPageHandler(var PhysInvtItemSelection: TestPage "Phys. Invt. Item Selection")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        PhysInvtItemSelection.FILTER.SetFilter("Item No.", ItemNo);
        PhysInvtItemSelection.OK().Invoke();  // Open Report- Calculate Phys.Invt. Counting on CalculatePhysInvtCountingPageHandler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseDocumentLinesPageHandler(var PostedPurchaseDocumentLines: TestPage "Posted Purchase Document Lines")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PostedPurchaseDocumentLines.PostedInvoices.FILTER.SetFilter("Document No.", DocumentNo);
        PostedPurchaseDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PostedSalesDocumentLines.PostedInvoices.FILTER.SetFilter("Document No.", DocumentNo);
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesShipmentLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    var
        DocumentNo: Variant;
        DocumentType: Option "Posted Shipments","Posted Invoices","Posted Return Receipt","Posted Cr. Memo";
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Shipments"));
        PostedSalesDocumentLines.PostedShpts.FILTER.SetFilter("Document No.", DocumentNo);
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    var
        OptionValue: Variant;
        OptionString: Option AutoReserve,CancelReserv;
        ReserveOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);
        ReserveOption := OptionValue;
        case ReserveOption of
            OptionString::CancelReserv:
                Reservation.CancelReservationCurrentLine.Invoke();
            OptionString::AutoReserve:
                Reservation."Auto Reserve".Invoke();
        end
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RollUpStandardCostReportHandler(var RollUpStandardCost: TestRequestPage "Roll Up Standard Cost")
    begin
        RollUpStandardCost.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatisticsPageHandler(var SalesInvoiceStatistics: TestPage "Sales Invoice Statistics")
    var
        AmountLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountLCY);
        SalesInvoiceStatistics.AmountLCY.AssertEquals(AmountLCY);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        Quantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(Quantity);
        WhseItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        WhseItemTrackingLines.Quantity.SetValue(Quantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        OptionValue: Variant;
        LotNo: Variant;
        SerialNo: Variant;
        Quantity: Variant;
        ApplFromItemEntry: Variant;
        ApplToItemEntry: Variant;
        OptionString: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,SetApplFromItemEntry,SetApplToItemEntry,VerifyApplFromItemEntry,VerifyApplToItemEntry;
        TrackingOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        TrackingOption := OptionValue;  // To convert Variant into Option.
        case TrackingOption of
            OptionString::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            OptionString::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            OptionString::SetLotNo:
                begin
                    LibraryVariableStorage.Dequeue(LotNo);
                    LibraryVariableStorage.Dequeue(Quantity);
                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                end;
            OptionString::SetApplFromItemEntry:
                begin
                    LibraryVariableStorage.Dequeue(ApplFromItemEntry); // Dequeue variable.
                    ItemTrackingLines."Appl.-from Item Entry".SetValue(ApplFromItemEntry);
                end;
            OptionString::SetApplToItemEntry:
                begin
                    LibraryVariableStorage.Dequeue(ApplToItemEntry); // Dequeue variable.
                    ItemTrackingLines."Appl.-to Item Entry".SetValue(ApplToItemEntry);
                end;
            OptionString::VerifyApplFromItemEntry:
                begin
                    LibraryVariableStorage.Dequeue(LotNo);
                    LibraryVariableStorage.Dequeue(SerialNo);
                    LibraryVariableStorage.Dequeue(ApplFromItemEntry);
                    LibraryVariableStorage.Dequeue(Quantity);
                    ItemTrackingLines."Appl.-from Item Entry".AssertEquals(ApplFromItemEntry);
                    ItemTrackingLines."Lot No.".AssertEquals(LotNo);
                    ItemTrackingLines."Serial No.".AssertEquals(SerialNo);
                    ItemTrackingLines."Quantity (Base)".AssertEquals(Quantity);
                end;
            OptionString::VerifyApplToItemEntry:
                begin
                    LibraryVariableStorage.Dequeue(ApplToItemEntry);
                    ItemTrackingLines."Appl.-to Item Entry".AssertEquals(ApplToItemEntry);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantitytoCreatePageHandler(var EnterQuantitytoCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantitytoCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;
}
