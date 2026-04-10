codeunit 137308 "SCM Planning Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [Reports] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
#if not CLEAN27
        LibraryReportDataset: Codeunit "Library - Report Dataset";
#endif
        LibraryUtility: Codeunit "Library - Utility";
#if not CLEAN27
        LibrarySales: Codeunit "Library - Sales";
#endif
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
#if not CLEAN27
        PlannedReceiptsErr: Label 'Wrong planned receipts qty.';
        ScheduledReceiptsErr: Label 'Wrong scheduled receipts qty.';
        ErrMsgRequisition: Label 'Requisition Line must not exist.';
        ErrMsgDocument: Label 'Document must not exist.';
        OutputConfirmMessage: Label '\\  * Some output is still missing.\  * Some consumption is still missing.\\ Do you still want to finish the order?';
#endif        
        RecordShould: Option Exist,"Not Exist";
        RecordExistenceErr: Label '%1 record should %2.';
#if not CLEAN27
    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForPurchaseReorderPolicyLotForLot()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForPurchase(Item."Reordering Policy"::"Lot-for-Lot");
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForPurchaseReorderPolicyFRQ()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForPurchase(Item."Reordering Policy"::"Fixed Reorder Qty.");
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForPurchaseReorderPolicyMQ()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForPurchase(Item."Reordering Policy"::"Maximum Qty.");
    end;

    local procedure PlanningAvailabilityForPurchase(ReorderingPolicy: Enum "Reordering Policy")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Create Item and Sales Order.
        CreateItem(Item, '', '', ReorderingPolicy, Item."Replenishment System"::Purchase);
        if ReorderingPolicy = Item."Reordering Policy"::"Fixed Reorder Qty." then
            UpdateItemReorderPointParameters(Item)
        else
            if ReorderingPolicy = Item."Reordering Policy"::"Maximum Qty." then
                UpdateItemMinMaxOrderQty(Item, 0, LibraryRandom.RandDec(5, 2) + 100);  // Value required.
        CreateSalesOrder(SalesLine, Item."No.");

        // Create Purchase Order with Planning Flexibility - None.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Gross Requirement, Scheduled Receipts, and Projected Balance in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        if (ReorderingPolicy = Item."Reordering Policy"::"Lot-for-Lot") or
           (ReorderingPolicy = Item."Reordering Policy"::"Fixed Reorder Qty.")
        then
            LibraryReportDataset.AssertElementWithValueExists('ProjectedBalance', PurchaseLine.Quantity - SalesLine.Quantity);

        VerifySalesGrossRequirement(SalesLine);
        Assert.AreEqual(PurchaseLine.Quantity, SelectScheduledReceipts(PurchaseLine."Document No."), ScheduledReceiptsErr);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForFirmPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityReport(ProductionOrder.Status::"Firm Planned", Item."Reordering Policy"::"Lot-for-Lot");
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForReleasedProdOrder()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityReport(ProductionOrder.Status::Released, Item."Reordering Policy"::"Lot-for-Lot");
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForFirmPlannedProdOrderReorderPolicyFRQ()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityReport(ProductionOrder.Status::"Firm Planned", Item."Reordering Policy"::"Fixed Reorder Qty.");
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForReleasedProdOrderReorderPolicyFRQ()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityReport(ProductionOrder.Status::Released, Item."Reordering Policy"::"Fixed Reorder Qty.");
    end;

    local procedure PlanningAvailabilityReport(ProductionOrderStatus: Enum "Production Order Status"; ItemReorderingPolicy: Enum "Reordering Policy")
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // Create Production Order.
        CreateProductionOrderSetup(ProductionOrder, ProductionOrderStatus, ItemReorderingPolicy);

        // Create Sales Order.
        CreateSalesOrder(SalesLine, ProductionOrder."Source No.");

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(ProductionOrder."Source No.", 0D);

        // Verify: Check values - Gross Requirement, Scheduled Receipts, and Projected Balance in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ProjectedBalance', ProductionOrder.Quantity - SalesLine.Quantity);
        VerifySalesGrossRequirement(SalesLine);
        Assert.AreEqual(ProductionOrder.Quantity, SelectScheduledReceipts(ProductionOrder."No."), ScheduledReceiptsErr);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanWithoutReorderPolicy()
    begin
        // Setup: Create Item without Re-order policy. Create Sales Order.
        Initialize();
        CalcPlanWithoutReorderPolicy(true);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanWithoutReorderPolicy()
    begin
        // Setup: Create Item without Re-order policy. Create Sales Order.
        Initialize();
        CalcPlanWithoutReorderPolicy(false);
    end;

    local procedure CalcPlanWithoutReorderPolicy(Regenerative: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        PlanningBuffer: Record "Planning Buffer";
    begin
        // Create Item without Re-order policy. Create Sales Order.
        CreateItem(Item, '', '', Item."Reordering Policy"::" ", Item."Replenishment System"::Purchase);
        CreateSalesOrder(SalesLine, Item."No.");

        // Planning Worksheet -> Calculate Regenerative plan Or Calculate Net Change plan.
        if Regenerative then
            LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate())
        else
            LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate(), WorkDate(), false);

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify:  Check values - Gross Requirement from Sales Order, but Requisition line is not available in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        VerifySalesGrossRequirement(SalesLine);
        LibraryReportDataset.SetRange('PlanningBuffDocType', PlanningBuffer."Document Type"::"Requisition Line");
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), ErrMsgRequisition);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanWithReorderPolicyAndPurchase()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CalcRegenerativePlanAndPlanningAvailability(Item."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanWithReorderPolicyAndProduction()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CalcRegenerativePlanAndPlanningAvailability(Item."Replenishment System"::"Prod. Order");
    end;

    local procedure CalcRegenerativePlanAndPlanningAvailability(ItemReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Create Item with Re-order policy- Lot-for-Lot. Create Sales Order.
        CreateItem(Item, '', '', Item."Reordering Policy"::"Lot-for-Lot", ItemReplenishmentSystem);
        CreateSalesOrder(SalesLine, Item."No.");

        // Planning Worksheet -> Calculate Regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Gross Requirement from Sales Order, and Planned Receipts from Requisition Line in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        VerifySalesGrossRequirement(SalesLine);
        Assert.AreEqual(CalcItemReorderQty(Item, SalesLine.Quantity, 0), SelectPlannedReceipts(), PlannedReceiptsErr);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMessageForPurchaseOrder()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CarryOutActionMessageAndPlanningAvailability(Item."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMessageForProductionOrder()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CarryOutActionMessageAndPlanningAvailability(Item."Replenishment System"::"Prod. Order");
    end;

    local procedure CarryOutActionMessageAndPlanningAvailability(ItemReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Create Item with Re-order policy- Lot-for-Lot and required replenishment. Create Sales Order.
        CreateItem(Item, '', '', Item."Reordering Policy"::"Lot-for-Lot", ItemReplenishmentSystem);
        CreateSalesOrder(SalesLine, Item."No.");

        // Planning Worksheet -> Calculate Regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Carry-Out Action Message.
        CarryOutActionMessageForRegenPlan(Item."No.");

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Gross Requirement from Sales Order, and Scheduled Receipts from newly created Purchase or Production Order, in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        VerifySalesGrossRequirement(SalesLine);
        VerifyRefOrder(Item);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMessageAndDeletePurchaseOrder()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CarryOutActionMessageAndDeleteOrder(Item."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMessageAndDeleteProductionOrder()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CarryOutActionMessageAndDeleteOrder(Item."Replenishment System"::"Prod. Order");
    end;

    local procedure CarryOutActionMessageAndDeleteOrder(ItemReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        PlanningBuffer: Record "Planning Buffer";
    begin
        // Create Item with Re-order policy - Lot-for-Lot and required replenishment. Create Sales Order.
        CreateItem(Item, '', '', Item."Reordering Policy"::"Lot-for-Lot", ItemReplenishmentSystem);
        CreateSalesOrder(SalesLine, Item."No.");

        // Planning Worksheet -> Calculate Regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Carry-Out Action Message.
        CarryOutActionMessageForRegenPlan(Item."No.");

        // Delete Purchase or Production Order.
        DeleteOrder(Item);

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check value - Gross Requirement from Sales Order, but newly created Purchase or Production Order are not available in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        VerifySalesGrossRequirement(SalesLine);
        LibraryReportDataset.SetRange('PlanningBuffDocType', PlanningBuffer."Document Type"::"Purchase Order");
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), ErrMsgDocument);

        LibraryReportDataset.SetRange('PlanningBuffDocType', PlanningBuffer."Document Type"::"Firm Planned Prod. Order");
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), ErrMsgDocument);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgPurchaseReorderPolicyLotForLot()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CarryOutActionMessageForDiffReplenishmentReorderPolicy(
          Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgProductionReorderPolicyLotForLot()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CarryOutActionMessageForDiffReplenishmentReorderPolicy(
          Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgPurchaseReorderPolicyOrder()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CarryOutActionMessageForDiffReplenishmentReorderPolicy(Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgProductionReorderPolicyOrder()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CarryOutActionMessageForDiffReplenishmentReorderPolicy(
          Item."Reordering Policy"::Order, Item."Replenishment System"::"Prod. Order");
    end;

    local procedure CarryOutActionMessageForDiffReplenishmentReorderPolicy(ItemReorderingPolicy: Enum "Reordering Policy"; ItemReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Create Item with required re-order policy and required replenishment system and create two Sales Order.
        CreateItem(Item, '', '', ItemReorderingPolicy, ItemReplenishmentSystem);
        CreateSalesOrder(SalesLine, Item."No.");
        CreateSalesOrder(SalesLine2, Item."No.");

        // Planning Worksheet -> Calculate Regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Carry-Out Action Message.
        CarryOutActionMessageForRegenPlan(Item."No.");

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Verify Sales Order entries and Scheduled Receipts in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PlanningBuffDocNo', SalesLine."Document No.");
        LibraryReportDataset.AssertElementWithValueExists('PlanningBuffDocNo', SalesLine2."Document No.");
        if ItemReorderingPolicy = Item."Reordering Policy"::"Lot-for-Lot" then
            LibraryReportDataset.AssertElementWithValueExists('PlngBuffScheduledReceipts', SalesLine.Quantity +
              SalesLine2.Quantity)
        else
            VerifyScheduledReceiptsForPolicyOrder(Item);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanForFirmPlannedOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Item, create and refresh Production Order.
        Initialize();
        CreateItem(Item, '', '', Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.");

        // Planning Worksheet -> Calculate Regenerative plan. Cancels Production Order.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Exercise: Generate the Planning Availability Report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check value - Scheduled Receipts and Planned Receipts in the Planning Availability Report are Zero.
        Assert.AreEqual(0, SelectPlannedReceipts(), PlannedReceiptsErr);
        Assert.AreEqual(0, SelectScheduledReceipts(ProductionOrder."No."), ScheduledReceiptsErr);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForFirmPlannedWithNewBOMVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForFirmPlannedOrdersWithBOMVersion(ProductionBOMVersion.Status::New, false, false);  // Calculate Regenerative Plan - False, BOM Version Item - False.
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanForFirmPlannedWithNewBOMVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForFirmPlannedOrdersWithBOMVersion(ProductionBOMVersion.Status::New, true, false);  // Calculate Regenerative Plan - True, BOM Version Item - False.
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForFirmPlannedProdItemWithCertifiedBOMVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForFirmPlannedOrdersWithBOMVersion(ProductionBOMVersion.Status::Certified, false, false);  // Calculate Regenerative Plan - False, BOM Version Item - False.
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForFirmPlannedBOMItemWithCertifiedBOMVersion()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForFirmPlannedOrdersWithBOMVersion(ProductionBOMVersion.Status::Certified, false, true);  // Calculate Regenerative Plan - False, BOM Version Item - True.
    end;

    local procedure PlanningAvailabilityForFirmPlannedOrdersWithBOMVersion(Status: Enum "BOM Status"; CalculateRegenerativePlan: Boolean; BOMVersionItem: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ItemNo: Code[20];
    begin
        // Create Item. Create Production BOM and Version, Create and Refresh Production Order.
        CreateItem(Item, '', '', Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
        ItemNo := Item."No.";

        // Create Purchase Order with two Lines.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(5, 2));  // Random Quantity for Purchase Line.
        CreateItem(Item2, '', '', Item2."Reordering Policy"::"Lot-for-Lot", Item2."Replenishment System"::Purchase);

        if BOMVersionItem then begin
            CreatePurchaseOrder(PurchaseHeader2, PurchaseLine3, Item2."No.");
            ItemNo := Item2."No.";
        end;

        CreateProductionBOMWithVersion(Item."Base Unit of Measure", Item2."No.", Status);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.");

        // Exercise: Generate the Planning Availability Report with Calculated Regenerative plan as required.
        if CalculateRegenerativePlan then
            LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        RunPlanningAvailabilityReport(ItemNo, 0D);

        // Verify: Check values- Scheduled Receipts from Production Order and Projected Balance in the Planning Availability Report.
        LibraryReportDataset.LoadDataSetFile();
        if BOMVersionItem then
            Assert.AreEqual(PurchaseLine3.Quantity, SelectScheduledReceipts(PurchaseLine3."Document No."), ScheduledReceiptsErr)
        else
            VerifyPurchaseAndFirmPlannedValues(PurchaseLine, PurchaseLine2, ProductionOrder, CalculateRegenerativePlan);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanForFirmPlannedWithSales()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Item, create and refresh Firm Planned Production Order and create Sales Order.
        Initialize();
        CreateItem(Item, '', '', Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.");
        CreateSalesOrder(SalesLine, ProductionOrder."Source No.");

        // Exercise: Generate the Planning Availability Report after Calculate Regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check value - Gross Requirement, Projected Balance and Planned receipts from Requisition Line in the Planning Availability Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ProjectedBalance', -SalesLine.Quantity);
        VerifySalesGrossRequirement(SalesLine);
        Assert.AreEqual(CalcItemReorderQty(Item, SalesLine.Quantity, 0), SelectPlannedReceipts(), PlannedReceiptsErr);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanWithReorderPolicyFRQAndPurchase()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CalcNetChangePlanAndPlanningAvailability(Item."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcNetChangePlanWithReorderPolicyFRQAndProduction()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CalcNetChangePlanAndPlanningAvailability(Item."Replenishment System"::"Prod. Order");
    end;

    local procedure CalcNetChangePlanAndPlanningAvailability(ItemReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Create Item with Re-order policy- Fixed Re-order Qty. Create Sales Order.
        CreateItem(Item, '', '', Item."Reordering Policy"::"Fixed Reorder Qty.", ItemReplenishmentSystem);
        UpdateItemReorderPointParameters(Item);
        CreateSalesOrder(SalesLine, Item."No.");

        // Planning Worksheet -> Calculate Net Change Plan.
        LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate(), WorkDate(), false);

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Gross Requirement from Sales Order, and Planned Receipts from Requisition Line in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        VerifySalesGrossRequirement(SalesLine);
        Assert.AreEqual(SalesLine.Quantity + CalcItemReorderQty(Item, SalesLine.Quantity, 0), SelectPlannedReceipts(), PlannedReceiptsErr);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForFirmPlannedNewBOMVersionReorderPolicyFRQ()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForFirmPlannedOrdersWithBOMVersionAndItemReorderPolicyFRQ(ProductionBOMVersion.Status::New, false, false);  // Calculate Net Change Plan - False, BOM Version Item - False.
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanForFirmPlannedNewBOMVersionReorderPolicyFRQ()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForFirmPlannedOrdersWithBOMVersionAndItemReorderPolicyFRQ(ProductionBOMVersion.Status::New, true, false);  // Calculate Net Change Plan - True, BOM Version Item - False.
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForFirmPlannedProdItemCertifiedBOMVersionReorderPolicyFRQ()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForFirmPlannedOrdersWithBOMVersionAndItemReorderPolicyFRQ(
          ProductionBOMVersion.Status::Certified, false, false);  // Calculate Net Change Plan - False, BOM Version Item - False.
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForFirmPlannedBOMItemCertifiedBOMVersionReorderPolicyFRQ()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForFirmPlannedOrdersWithBOMVersionAndItemReorderPolicyFRQ(ProductionBOMVersion.Status::Certified, false, true);  // Calculate Net Change Plan - False, BOM Version Item - True.
    end;

    local procedure PlanningAvailabilityForFirmPlannedOrdersWithBOMVersionAndItemReorderPolicyFRQ(Status: Enum "BOM Status"; CalculateNetChangePlan: Boolean; BOMVersionItem: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ItemNo: Code[20];
    begin
        // Create Item. Create Production BOM and Version, Create and Refresh Production Order.
        CreateItem(Item, '', '', Item."Reordering Policy"::"Fixed Reorder Qty.", Item."Replenishment System"::"Prod. Order");
        UpdateItemReorderPointParameters(Item);
        ItemNo := Item."No.";

        // Create Purchase Order with two Lines.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(5, 2));  // Random Quantity for Purchase Line.
        CreateItem(Item2, '', '', Item2."Reordering Policy"::"Fixed Reorder Qty.", Item2."Replenishment System"::Purchase);
        UpdateItemReorderPointParameters(Item2);

        if BOMVersionItem then begin
            CreatePurchaseOrder(PurchaseHeader2, PurchaseLine3, Item2."No.");
            ItemNo := Item2."No.";
        end;

        CreateProductionBOMWithVersion(Item."Base Unit of Measure", Item2."No.", Status);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.");

        // Exercise: Generate the Planning Availability Report with Calculate Net Change plan as required.
        if CalculateNetChangePlan then
            LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate(), WorkDate(), false);
        RunPlanningAvailabilityReport(ItemNo, 0D);

        // Verify: Check values- Scheduled Receipts from Production Order and Projected Balance in the Planning Availability Report.
        LibraryReportDataset.LoadDataSetFile();
        if BOMVersionItem then
            Assert.AreEqual(PurchaseLine3.Quantity, SelectScheduledReceipts(PurchaseLine3."Document No."), ScheduledReceiptsErr)
        else
            VerifyPurchaseAndFirmPlannedValuesForFRQItem(PurchaseLine, PurchaseLine2, ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityReportForProdWithRoutingAndMultipleSalesReorderPolicyLFL()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityReportForProdWithRoutingAndMultipleSales(Item."Reordering Policy"::"Lot-for-Lot");
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityReportForProdWithRoutingAndMultipleSalesReorderPolicyMQ()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityReportForProdWithRoutingAndMultipleSales(Item."Reordering Policy"::"Maximum Qty.");
    end;

    local procedure PlanningAvailabilityReportForProdWithRoutingAndMultipleSales(ReorderingPolicy: Enum "Reordering Policy")
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Create Item with Production BOM and Routing, create two Sales Order and Firm Planned Production Order.
        CreateSalesOrdersWithFirmPlannedProd(Item, ProductionOrder, SalesLine, SalesLine2, ReorderingPolicy);
        if ReorderingPolicy = Item."Reordering Policy"::"Maximum Qty." then
            UpdateItemMinMaxOrderQty(Item, 0, LibraryRandom.RandDec(5, 2) + 100);  // Value required.

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Gross Requirement,Production scheduled Receipts, Projected Balance in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyGrossReqAndProjectedBalanceForMultipleSales(SalesLine, SalesLine2, ProductionOrder);
        Assert.AreEqual(ProductionOrder.Quantity, SelectScheduledReceipts(ProductionOrder."No."), ScheduledReceiptsErr);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanForProdWithRoutingAndMultipleSalesReorderPolicyLFL()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CalcRegenerativePlanForProdWithRoutingAndMultipleSales(Item."Reordering Policy"::"Lot-for-Lot");
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanForProdWithRoutingAndMultipleSalesReorderPolicyMQ()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CalcRegenerativePlanForProdWithRoutingAndMultipleSales(Item."Reordering Policy"::"Maximum Qty.");
    end;

    local procedure CalcRegenerativePlanForProdWithRoutingAndMultipleSales(ReorderingPolicy: Enum "Reordering Policy")
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Create Item with Production BOM and Routing, create two Sales Order and Firm Planned Production Order.
        CreateSalesOrdersWithFirmPlannedProd(Item, ProductionOrder, SalesLine, SalesLine2, ReorderingPolicy);
        if ReorderingPolicy = Item."Reordering Policy"::"Maximum Qty." then
            UpdateItemMinMaxOrderQty(Item, 0, LibraryRandom.RandDec(5, 2) + 100);  // Value required.

        // Planning Worksheet -> Calculate Regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Gross Requirement,Projected Balance,Planned Receipts from Requisition Line in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyGrossReqAndProjectedBalanceForMultipleSales(SalesLine, SalesLine2, ProductionOrder);
        if ReorderingPolicy = Item."Reordering Policy"::"Maximum Qty." then
            Assert.AreEqual(ProductionOrder.Quantity, SelectScheduledReceipts(ProductionOrder."No."), ScheduledReceiptsErr)
        else
            Assert.AreEqual(SalesLine.Quantity + SalesLine2.Quantity - SelectScheduledReceipts(ProductionOrder."No."),
              SelectPlannedReceipts(), PlannedReceiptsErr);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgForProdWithRoutingAndMultipleSalesReorderPolicyLFL()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CarryOutActionMsgForProdWithRoutingAndMultipleSales(Item."Reordering Policy"::"Lot-for-Lot");
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgForProdWithRoutingAndMultipleSalesReorderPolicyMQ()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CarryOutActionMsgForProdWithRoutingAndMultipleSales(Item."Reordering Policy"::"Maximum Qty.");
    end;

    local procedure CarryOutActionMsgForProdWithRoutingAndMultipleSales(ReorderingPolicy: Enum "Reordering Policy")
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Create Item with Production BOM and Routing, create two Sales Order and Firm Planned Production Order.
        CreateSalesOrdersWithFirmPlannedProd(Item, ProductionOrder, SalesLine, SalesLine2, ReorderingPolicy);
        if ReorderingPolicy = Item."Reordering Policy"::"Maximum Qty." then
            UpdateItemMinMaxOrderQty(Item, 0, LibraryRandom.RandDec(5, 2) + 100);  // Value required.

        // Planning Worksheet -> Calculate Regenerative plan. Carry-Out Action Message.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        CarryOutActionMessageForRegenPlan(Item."No.");

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Gross Requirements, Scheduled Receipts, Projected Balance in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyGrossReqAndProjectedBalanceForMultipleSales(SalesLine, SalesLine2, ProductionOrder);
        LibraryReportDataset.Reset();
        if ReorderingPolicy = Item."Reordering Policy"::"Maximum Qty." then
            LibraryReportDataset.AssertElementWithValueExists('PlngBuffScheduledReceipts',
              SelectScheduledReceipts(ProductionOrder."No."));
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityReportForProdOrderWithBOMHierarchy()
    begin
        // Setup: Create Item with Order attributes. Create Production BOM and Routing with BOM hierarchy, create Sales Order and Firm Planned Production Order.
        Initialize();
        PlanningAvailabilityReportForProdOrderSetup(true);  // BOM Hierarchy- TRUE;
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityReportForProdItemWithoutRouting()
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityReportForProdOrderSetup(false);
    end;

    local procedure PlanningAvailabilityReportForProdOrderSetup(BOMHierarchy: Boolean)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SalesLine: Record "Sales Line";
    begin
        if BOMHierarchy then
            CreateSalesOrderWithFirmPlannedProdAndBOMHierarchy(Item, SalesLine, ProductionOrder)
        else
            CreateSalesOrderWtihProdOrderWithoutRouting(Item, SalesLine, ProductionOrder);

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Gross Requirement, Projected Balance in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ProjectedBalance', ProductionOrder.Quantity - SalesLine.Quantity);
        VerifySalesGrossRequirement(SalesLine);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityReportIncludesProductionForecast()
    var
        Item: Record Item;
        ProductionForecastEntry: Record "Production Forecast Entry";
        ProductionForecastName: Record "Production Forecast Name";
        EventDate: Date;
    begin
        // 1) Setup: Create a production forecast entry for an item with a Production BOM
        Initialize();
        CreateItemWithProductionBOM(Item);
        CreateForecastEntry(ProductionForecastEntry, ProductionForecastName, Item, EventDate);

        // 2) Exercise
        RunPlanningAvailabilityReport(Item."No.", EventDate);

        // 3) Verify
        VerifyProductionForecastGrossRequirement(ProductionForecastEntry);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanForProdOrderWithBOMHierarchy()
    begin
        // Setup: Create Item with Order attributes. Create Production BOM and Routing with BOM hierarchy, create Sales Order and Firm Planned Production Order.
        Initialize();
        CalcRegenerativePlanForProdOrderSetup(true);  // BOM Hierarchy- TRUE;
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalcRegenerativePlanForProdItemWithoutRouting()
    begin
        // Setup.
        Initialize();
        CalcRegenerativePlanForProdOrderSetup(false);
    end;

    local procedure CalcRegenerativePlanForProdOrderSetup(BOMHierarchy: Boolean)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SalesLine: Record "Sales Line";
    begin
        if BOMHierarchy then
            CreateSalesOrderWithFirmPlannedProdAndBOMHierarchy(Item, SalesLine, ProductionOrder)
        else
            CreateSalesOrderWtihProdOrderWithoutRouting(Item, SalesLine, ProductionOrder);

        // Planning Worksheet -> Calculate Regenerative plan
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, WorkDate(), CalcDate('<' + Format(LibraryRandom.RandInt(5) + 30) + 'D>', WorkDate()));

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Gross Requirement,Projected Balance,Planned Receipts from Requisition Line in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ProjectedBalance', -SalesLine.Quantity);
        VerifySalesGrossRequirement(SalesLine);
        Assert.AreEqual(CalcItemReorderQty(Item, SalesLine.Quantity, 0), SelectPlannedReceipts(), PlannedReceiptsErr);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgForProdOrderWithBOMHierarchy()
    begin
        // Setup: Create Item with Order attributes. Create Production BOM and Routing with BOM hierarchy, create Sales Order and Firm Planned Production Order.
        Initialize();
        CarryOutActionMessageForProductionSetup(true);  // BOM Hierarchy - TRUE.
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgForProdItemWithoutRouting()
    begin
        // Setup.
        Initialize();
        CarryOutActionMessageForProductionSetup(false);
    end;

    local procedure CarryOutActionMessageForProductionSetup(BOMHierarchy: Boolean)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SalesLine: Record "Sales Line";
    begin
        if BOMHierarchy then
            CreateSalesOrderWithFirmPlannedProdAndBOMHierarchy(Item, SalesLine, ProductionOrder)
        else
            CreateSalesOrderWtihProdOrderWithoutRouting(Item, SalesLine, ProductionOrder);

        // Planning Worksheet -> Calculate Regenerative plan. Carry-Out Action Message.
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, WorkDate(), CalcDate('<' + Format(LibraryRandom.RandInt(5) + 30) + 'D>', WorkDate()));
        CarryOutActionMessageForRegenPlan(Item."No.");

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Gross Requirement, Scheduled Receipts,Projected Balance in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        VerifySalesGrossRequirement(SalesLine);
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(ProductionOrder.Quantity, SelectScheduledReceipts(ProductionOrder."No."), ScheduledReceiptsErr);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityAfterSalesPostAndCalcRegenPlanReorderPolicyFRQ()
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityAfterSalesPostReorderPolicyFRQ(false);  // Carry Out Action Message - False.
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityAfterSalesPostAndCarryOutActionMsgReorderPolicyFRQ()
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityAfterSalesPostReorderPolicyFRQ(true);  // Carry Out Action Message - True.
    end;

    local procedure PlanningAvailabilityAfterSalesPostReorderPolicyFRQ(CarryOutActionMessage: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Create Item and Sales Order.
        CreateItem(Item, '', '', Item."Reordering Policy"::"Fixed Reorder Qty.", Item."Replenishment System"::Purchase);
        UpdateItemReorderQty(Item);
        CreateAndPostSalesOrder(SalesLine, Item."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        if CarryOutActionMessage then
            CarryOutActionMessageForRegenPlan(Item."No.");

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Planned Receipts, Scheduled Receipts and Projected Balance in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyMultiplePurchaseReceipts(SalesLine, Item."Reorder Quantity", CarryOutActionMessage);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityAfterSalesPostAndCalcPlanReqWkhstReorderPolicyFRQ()
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityAfterSalesPostReqWkshtReorderPolicyFRQ(false);  // Carry Out Action Message - False.
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityAfterSalesPostReqWkhstCarryOutActionMsgReorderPolicyFRQ()
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityAfterSalesPostReqWkshtReorderPolicyFRQ(true);  // Carry Out Action Message - True.
    end;

    local procedure PlanningAvailabilityAfterSalesPostReqWkshtReorderPolicyFRQ(CarryOutActionMessage: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Item and Sales Order.
        CreateItem(Item, '', '', Item."Reordering Policy"::"Fixed Reorder Qty.", Item."Replenishment System"::Purchase);
        UpdateItemReorderQty(Item);
        CreateAndPostSalesOrder(SalesLine, Item."No.");

        // Create Requisition Worksheet.
        CalcPlanForRequisitionWorksheet(RequisitionWkshName, Item);

        if CarryOutActionMessage then begin
            SelectRequisitionLineForReqWksht(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
            repeat
                RequisitionLine.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
                UpdateActionMessageRequisitionLine(RequisitionLine);
            until RequisitionLine.Next() = 0;
            LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
        end;

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Planned Receipts, Scheduled Receipts and Projected Balance in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyMultiplePurchaseReceipts(SalesLine, Item."Reorder Quantity", CarryOutActionMessage);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForSalesWithProdOrderAndCalcPlanReqWkhstReorderPolicyFRQ()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForSalesWithProdOrder(Item."Reordering Policy"::"Fixed Reorder Qty.");
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForSalesWithProdOrderAndCalcPlanReqWkhstReorderPolicyMQ()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityForSalesWithProdOrder(Item."Reordering Policy"::"Maximum Qty.");
    end;

    local procedure PlanningAvailabilityForSalesWithProdOrder(ReorderingPolicy: Enum "Reordering Policy")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        // Create Fixed Reorder Qty or Maximum Qty Item with Sales and Production Order.
        CreateItem(Item, '', '', ReorderingPolicy, Item."Replenishment System"::Purchase);
        CreateSalesOrder(SalesLine, Item."No.");
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.");

        // Create Requisition Worksheet.
        CalcPlanForRequisitionWorksheet(RequisitionWkshName, Item);

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(Item."No.", 0D);

        // Verify: Check values - Sales Requirement and Production Scheduled Receipts, and Planned Receipts in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        VerifySalesGrossRequirement(SalesLine);
        Assert.AreEqual(ProductionOrder.Quantity, SelectScheduledReceipts(ProductionOrder."No."), ScheduledReceiptsErr);
        Assert.AreEqual(SalesLine.Quantity - ProductionOrder.Quantity, SelectPlannedReceipts(), PlannedReceiptsErr);
    end;

    [Test]
    [HandlerFunctions('PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForFirmPlannedToReleasedProdOrderReorderPolicyLotForLot()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityReportForProdOrderStatusUpdate(ProductionOrder.Status::"Firm Planned");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PlanningAvailabilityRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityForReleasedToFinishedProdOrderReorderPolicyLotForLot()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        PlanningAvailabilityReportForProdOrderStatusUpdate(ProductionOrder.Status::Released);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure PlanningAvailabilityReportForProdOrderStatusUpdate(ProductionOrderStatus: Enum "Production Order Status")
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        NewReleasedProdOrderNo: Code[20];
    begin
        // Create Firm Planned or Released Production Order as required with planning flexibility - None.
        CreateProductionOrderSetup(ProductionOrder, ProductionOrderStatus, Item."Reordering Policy"::"Lot-for-Lot");

        // Change status of the Production Order, Firm Planned -> Released, or Released -> Finished.
        if ProductionOrderStatus = ProductionOrder.Status::"Firm Planned" then
            NewReleasedProdOrderNo :=
              LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProductionOrder."No.")
        else begin
            LibraryVariableStorage.Enqueue(OutputConfirmMessage);
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        end;

        // Create Sales Order.
        CreateSalesOrder(SalesLine, ProductionOrder."Source No.");

        // Planning Worksheet -> Calculate Regenerative plan
        Item.Get(ProductionOrder."Source No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, WorkDate(), CalcDate('<' + Format(LibraryRandom.RandInt(5) + 30) + 'D>', WorkDate()));

        // Exercise: Generate the Planning Availability report.
        RunPlanningAvailabilityReport(ProductionOrder."Source No.", 0D);

        // Verify: Check values - Gross Requirement, Prod. Scheduled Receipts, and Planned Receipts in the Planning Availability report.
        LibraryReportDataset.LoadDataSetFile();
        if ProductionOrderStatus = ProductionOrder.Status::"Firm Planned" then begin
            VerifySalesGrossRequirement(SalesLine);
            ProductionOrder.Get(ProductionOrder.Status::Released, NewReleasedProdOrderNo);
            Assert.AreEqual(ProductionOrder.Quantity, SelectScheduledReceipts(ProductionOrder."No."), ScheduledReceiptsErr);
            Assert.AreEqual(SalesLine.Quantity - ProductionOrder.Quantity, SelectPlannedReceipts(), PlannedReceiptsErr);
        end else begin
            VerifySalesGrossRequirement(SalesLine);
            Assert.AreEqual(SalesLine.Quantity, SelectPlannedReceipts(), PlannedReceiptsErr);
        end;
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure ReplanCycleDoesNotDuplicateSupply()
    var
        Item: Record Item;
    begin
        // [FEATURE] [Planning] [Calculate Plan - Plan Wksh] [Reservation]
        // [SCENARIO] No planning worksheet infinite cycle appears if reservation on supply deleted manually.

        // [GIVEN] Demand from Production order component on an Item with SKU having Order reordering policy.
        Initialize();
        CreateItemAndSKU(Item);
        CreateProductionOrderWithComponent(Item."No.", Item.GetFilter("Location Filter"));
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        // [GIVEN] Calc supply, carry out.
        CarryOutActionMessageForRegenPlan(Item."No.");
        // [GIVEN] Partly post supply, then cancel reservation.
        PurchReceiptAndCancelReservation(Item."No.");
        // [GIVEN] Calc supply, carry out, but not post.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        CarryOutActionMessageForRegenPlan(Item."No.");

        // [WHEN] Calculating regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] No requisition worksheet suggested.
        VerifyActionLinesExists(Item."No.", RecordShould::"Not Exist");
    end;

    local procedure Initialize()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Planning Reports");
        RequisitionWkshName.DeleteAll();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        LibraryApplicationArea.EnableEssentialSetup();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Planning Reports");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        ItemJournalSetup();
        LibrarySetupStorage.SaveInventorySetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Planning Reports");
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; ReorderPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::FIFO, 0, ReorderPolicy, Item."Flushing Method", RoutingNo, ProductionBOMNo);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateItemAndSKU(var Item: Record Item)
    var
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
    begin
        CreateItem(Item, '', '', Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, Location.Code, Item."No.", '');
        SKU.Validate("Reordering Policy", SKU."Reordering Policy"::Order);
        SKU.Modify(true);
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", Location.Code);
    end;
#if not CLEAN27
    [Normal]
    local procedure CreateItemWithProductionBOM(var Item: Record Item)
    var
        ItemComponent: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);

        LibraryInventory.CreateItem(ItemComponent);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Modify(true);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemComponent."No.", LibraryRandom.RandInt(20));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2) + 10);  // Take Random Quantity.
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesLine, ItemNo);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;
#endif

    local procedure CreateProductionOrderWithComponent(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        Item: Record Item;
    begin
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ItemNo, 1); // Quantity per = 1.
        CreateItem(Item, '', ProductionBOMHeader."No.", Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::"Prod. Order");
        CreateAndRefreshProdOrderWithLocation(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LocationCode);
    end;
#if not CLEAN27
    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, LibraryRandom.RandDec(5, 2), '', 0D);
        UpdatePurchasePlanningFlexibility(PurchaseLine);
    end;

    local procedure UpdatePurchasePlanningFlexibility(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Planning Flexibility", PurchaseLine."Planning Flexibility"::None);
        PurchaseLine.Modify(true);
    end;

    local procedure RunPlanningAvailabilityReport(ItemNo: Code[20]; Date: Date)
    var
        PlanningBuffer: Record "Planning Buffer";
    begin
        PlanningBuffer.SetRange("Item No.", ItemNo);
        if Date <> 0D then
            PlanningBuffer.SetRange(Date, Date);
        Commit();
        REPORT.Run(REPORT::"Planning Availability", true, false, PlanningBuffer);
    end;

    local procedure CreateProductionOrderSetup(var ProductionOrder: Record "Production Order"; ProductionOrderStatus: Enum "Production Order Status"; ItemReorderingPolicy: Enum "Reordering Policy")
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Parent and Child Items.
        CreateProdOrderItemsSetup(Item, ProductionBOMHeader, ItemReorderingPolicy);

        // Create and Refresh Production Order.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrderStatus, Item."No.");

        // Update Production Order - Planning Flexibility to None.
        UpdateProductionPlanningFlexibility(ProductionOrder."No.");
    end;

    local procedure CreateProdOrderItemsSetup(var Item: Record Item; var ProductionBOMHeader: Record "Production BOM Header"; ReorderingPolicy: Enum "Reordering Policy")
    var
        RoutingHeader: Record "Routing Header";
    begin
        // Create Child Items.
        CreateCertifiedProductionBOM(ProductionBOMHeader);

        // Create Parent Item and attach Routing and Production BOM.
        CreateRoutingSetup(RoutingHeader);
        CreateItem(Item, RoutingHeader."No.", ProductionBOMHeader."No.", ReorderingPolicy, Item."Replenishment System"::"Prod. Order");
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header")
    var
        ChildItemNo: Code[20];
        ChildItemNo2: Code[20];
    begin
        ChildItemNo := CreateChildItemWithInventory();
        ChildItemNo2 := CreateChildItemWithInventory();

        // Create Production BOM.
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo2, 100);  // Quantity per Value important.
    end;

    local procedure CreateProductionBOMWithVersion(ItemBaseUnitOfMeasure: Code[10]; ChildItemNo: Code[20]; Status: Enum "BOM Status")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBomVersion: Record "Production BOM Version";
    begin
        // Create Production BOM.
        CreateCertifiedProductionBOM(ProductionBOMHeader);
        CreateProductionBOMVersion(ProductionBomVersion, ProductionBOMHeader, ItemBaseUnitOfMeasure, ChildItemNo);
        UpdateProductionBOMVersionStatus(ProductionBomVersion, Status);
    end;

    local procedure CreateProductionBOMVersion(var ProductionBOMVersion: Record "Production BOM Version"; ProductionBOMHeader: Record "Production BOM Header"; ItemBaseUnitOfMeasure: Code[10]; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBOMVersion, ProductionBOMHeader."No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(ProductionBOMVersion.FieldNo("Version Code"), DATABASE::"Production BOM Version"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Production BOM Version", ProductionBOMVersion.FieldNo("Version Code"))),
          ItemBaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, ProductionBOMVersion."Version Code", ProductionBOMLine.Type::Item, ItemNo,
          LibraryRandom.RandInt(10) + 10);  // Random Quantity.
    end;

    local procedure UpdateProductionBOMVersionStatus(ProductionBomVersion: Record "Production BOM Version"; Status: Enum "BOM Status")
    begin
        ProductionBomVersion.Validate(Status, Status);
        ProductionBomVersion.Modify(true);
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        // Random value important for test.
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(105, 1));
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    local procedure CreateChildItemWithInventory(): Code[20]
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItem(Item, '', '', Item."Reordering Policy"::" ", Item."Replenishment System"::Purchase);

        // Create Item Journal to populate Item Quantity.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(5, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(Item."No.");
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; ProductionOrderStatus: Enum "Production Order Status"; ItemNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrderStatus, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(5, 2));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;
#endif

    local procedure CreateAndRefreshProdOrderWithLocation(var ProductionOrder: Record "Production Order"; ProductionOrderStatus: Enum "Production Order Status"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrderStatus, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(5, 2));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;
#if not CLEAN27
    local procedure UpdateProductionPlanningFlexibility(ProductionOrderNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Planning Flexibility", ProdOrderLine."Planning Flexibility"::None);
        ProdOrderLine.Modify(true);
    end;
#endif

    local procedure CarryOutActionMessageForRegenPlan(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(ItemNo);
        SelectRequisitionLineForItem(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure AcceptActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLineForItem(RequisitionLine, ItemNo);
        repeat
            if RequisitionLine."Ref. Order Type" = RequisitionLine."Ref. Order Type"::Purchase then
                RequisitionLine.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
            UpdateActionMessageRequisitionLine(RequisitionLine);
        until RequisitionLine.Next() = 0;
    end;

    local procedure SelectRequisitionLineForItem(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindSet();
    end;

    local procedure SelectPurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.FindSet();
    end;
#if not CLEAN27
    local procedure SelectProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        ProductionOrder.SetRange("Source No.", ItemNo);
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.FindSet();
    end;

    local procedure DeleteOrder(Item: Record Item)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
    begin
        // If Item Replenishment System = Purchase, then delete Purchase Order. If Item Replenishment System = Prod. Order, then delete Production Order.
        if Item."Replenishment System" = Item."Replenishment System"::Purchase then begin
            SelectPurchaseLine(PurchaseLine, Item."No.");
            PurchaseHeader.SetRange("No.", PurchaseLine."Document No.");
            PurchaseHeader.FindFirst();
            PurchaseHeader.Delete(true);
        end else begin
            SelectProductionOrder(ProductionOrder, Item."No.");
            ProductionOrder.Delete(true);
        end;
    end;

    local procedure SelectScheduledReceipts(DocumentNo: Code[20]): Decimal
    begin
        LibraryReportDataset.SetRange('PlanningBuffDocNo', DocumentNo);
        exit(LibraryReportDataset.Sum('PlngBuffScheduledReceipts'));
    end;

    local procedure SelectPlannedReceipts(): Decimal
    var
        PlanningBuffer: Record "Planning Buffer";
    begin
        LibraryReportDataset.SetRange('PlanningBuffDocType', Format(PlanningBuffer."Document Type"::"Requisition Line"));
        exit(LibraryReportDataset.Sum('PlngBuffPlannedReceipts'));
    end;

    local procedure UpdateItemReorderPointParameters(var Item: Record Item)
    begin
        UpdateItemMinMaxOrderQty(Item, LibraryRandom.RandDec(5, 2), 0);  // Value required.
        Item.Validate("Order Multiple", Item."Minimum Order Quantity");
        UpdateItemReorderQty(Item);
    end;

    local procedure UpdateItemReorderQty(var Item: Record Item)
    begin
        Item.Validate("Reorder Quantity", 100 + LibraryRandom.RandDec(5, 2));  // Large value required.
        Item.Modify(true);
    end;

    local procedure CreateSalesOrdersWithFirmPlannedProd(var Item: Record Item; var ProductionOrder: Record "Production Order"; var SalesLine: Record "Sales Line"; var SalesLine2: Record "Sales Line"; ReorderingPolicy: Enum "Reordering Policy")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Item and two Sales Order. Create Firm Planned Production Order.
        CreateProdOrderItemsSetup(Item, ProductionBOMHeader, ReorderingPolicy);
        CreateSalesOrder(SalesLine, Item."No.");
        CreateSalesOrder(SalesLine2, Item."No.");
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.");
    end;

    local procedure CreateSalesOrderWithFirmPlannedProdAndBOMHierarchy(var Item: Record Item; var SalesLine: Record "Sales Line"; var ProductionOrder: Record "Production Order")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMHeader2: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Create Item with Order attributes and New BOM Version, Update Item Order Policy. Create two Production BOM Lines Of Item and Production BOM Type.
        CreateProdOrderItemsSetup(Item, ProductionBOMHeader, Item."Reordering Policy"::"Lot-for-Lot");
        UpdateItemMinMaxOrderQty(Item, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2) + 100);
        CreateCertifiedProductionBOM(ProductionBOMHeader2);
        CreateProductionBOMVersion(ProductionBOMVersion, ProductionBOMHeader, Item."Base Unit of Measure", Item."No.");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, ProductionBOMVersion."Version Code", ProductionBOMLine.Type::"Production BOM",
          ProductionBOMHeader2."No.", LibraryRandom.RandInt(10) + 10);
        UpdateProductionBOMVersionStatus(ProductionBOMVersion, ProductionBOMVersion.Status::"Under Development");
        CreateSalesOrder(SalesLine, Item."No.");
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.");
    end;

    local procedure CreateSalesOrderWtihProdOrderWithoutRouting(var Item: Record Item; var SalesLine: Record "Sales Line"; var ProductionOrder: Record "Production Order")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Item with Production BOM No. with deleted Routing No., Update item Order Policy. Create Sales Order and Firm Planned Production Order.
        CreateProdOrderItemsSetup(Item, ProductionBOMHeader, Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Routing No.", '');
        UpdateItemMinMaxOrderQty(Item, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2) + 100);
        CreateSalesOrder(SalesLine, Item."No.");
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.");
    end;

    local procedure UpdateItemMinMaxOrderQty(var Item: Record Item; MinimumOrderQuantity: Decimal; MaximumOrderQuantity: Decimal)
    begin
        Item.Validate("Minimum Order Quantity", MinimumOrderQuantity);
        Item.Validate("Maximum Order Quantity", MaximumOrderQuantity);
        Item.Modify(true);
    end;

    local procedure CreateRequisitionWorksheetName(var ReqWkshTemplate: Record "Req. Wksh. Template"; var RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        RequisitionWkshName.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure SelectRequisitionLineForReqWksht(var RequisitionLine: Record "Requisition Line"; WorksheetTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        RequisitionLine.SetRange("Worksheet Template Name", WorksheetTemplateName);
        RequisitionLine.SetRange("Journal Batch Name", JournalBatchName);
        RequisitionLine.FindSet();
    end;
#endif

    local procedure UpdateActionMessageRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;
#if not CLEAN27
    local procedure CalcPlanForRequisitionWorksheet(var RequisitionWkshName: Record "Requisition Wksh. Name"; Item: Record Item)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        CreateRequisitionWorksheetName(ReqWkshTemplate, RequisitionWkshName);
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, WorkDate(), WorkDate());
    end;

    [Normal]
    local procedure CalcItemReorderQty(Item: Record Item; GrossRequirement: Decimal; InitialScheduledReceipts: Decimal) PlannedReceipts: Decimal
    begin
        PlannedReceipts := 0;
        if GrossRequirement < InitialScheduledReceipts then
            exit(PlannedReceipts);

        if GrossRequirement - InitialScheduledReceipts < Item."Minimum Order Quantity" then
            PlannedReceipts := Item."Minimum Order Quantity"
        else
            PlannedReceipts := GrossRequirement - InitialScheduledReceipts;

        if (PlannedReceipts > Item."Maximum Order Quantity") and (Item."Maximum Order Quantity" > 0) then
            PlannedReceipts := Item."Maximum Order Quantity";

        if Item."Reorder Quantity" > 0 then
            PlannedReceipts := Item."Reorder Quantity";

        if Item."Order Multiple" <> 0 then
            PlannedReceipts := Item."Order Multiple" * (Round(PlannedReceipts / Item."Order Multiple", 1, '<') + 1);

        exit(PlannedReceipts);
    end;
#endif

    local procedure PurchReceiptAndCancelReservation(ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
    begin
        SelectPurchaseLine(PurchaseLine, ItemNo);
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);
        PurchaseLine.Modify();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        FindReservEntry(ReservationEntry, PurchaseLine);
        ReservationEngineMgt.CancelReservation(ReservationEntry);
    end;

    local procedure FindReservEntry(var ReservationEntry: Record "Reservation Entry"; PurchaseLine: Record "Purchase Line")
    begin
        ReservationEngineMgt.InitFilterAndSortingLookupFor(ReservationEntry, true);
        PurchaseLine.SetReservationFilters(ReservationEntry);
        ReservationEntry.FindFirst();
    end;
#if not CLEAN27
    local procedure VerifySalesGrossRequirement(SalesLine: Record "Sales Line")
    begin
        LibraryReportDataset.SetRange('PlanningBuffDocNo', SalesLine."Document No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('PlngBuffGrossRequirement', SalesLine.Quantity);
    end;

    local procedure VerifyRefOrder(Item: Record Item)
    var
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
    begin
        // Verify Purchase Order if Item Replenishment System = Purchase, or verify Production Order if Item Replenishment System = Prod. Order.
        if Item."Replenishment System" = Item."Replenishment System"::Purchase then begin
            SelectPurchaseLine(PurchaseLine, Item."No.");
            Assert.AreEqual(PurchaseLine.Quantity, SelectScheduledReceipts(PurchaseLine."Document No."),
              ScheduledReceiptsErr);
        end else begin
            SelectProductionOrder(ProductionOrder, Item."No.");
            Assert.AreEqual(ProductionOrder.Quantity, SelectScheduledReceipts(ProductionOrder."No."),
              ScheduledReceiptsErr);
        end;
    end;

    local procedure VerifyScheduledReceiptsForPolicyOrder(Item: Record Item)
    begin
        // Verify Purchase Order or Production Order details based on replenishment.
        if Item."Replenishment System" = Item."Replenishment System"::Purchase then
            VerifyPurchaseSchedReceiptsPolicyOrder(Item."No.")
        else
            VerifyProductionSchedReceiptsPolicyOrder(Item."No.");
    end;

    local procedure VerifyPurchaseSchedReceiptsPolicyOrder(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        // Verify values of multiple Purchase Lines from a single Purchase Order for multiple Sales Order.
        Item.Get(ItemNo);
        Item.CalcFields("Qty. on Purch. Order");
        LibraryReportDataset.SetRange('PlanningBuffItemNo', Item."No.");
        Assert.AreEqual(Item."Qty. on Purch. Order", LibraryReportDataset.Sum('PlngBuffScheduledReceipts'), ScheduledReceiptsErr);
    end;

    local procedure VerifyProductionSchedReceiptsPolicyOrder(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        // Verify values from multiple Production Order for multiple Sales Order.
        Item.Get(ItemNo);
        Item.CalcFields("Qty. on Prod. Order");
        LibraryReportDataset.SetRange('PlanningBuffItemNo', Item."No.");
        Assert.AreEqual(Item."Qty. on Prod. Order", LibraryReportDataset.Sum('PlngBuffScheduledReceipts'), ScheduledReceiptsErr);
    end;

    local procedure VerifyPurchaseAndFirmPlannedValues(PurchaseLine: Record "Purchase Line"; PurchaseLine2: Record "Purchase Line"; ProductionOrder: Record "Production Order"; CalculateRegenerativePlan: Boolean)
    begin
        if CalculateRegenerativePlan then begin
            LibraryReportDataset.AssertElementWithValueExists('ProjectedBalance', PurchaseLine.Quantity);
            LibraryReportDataset.AssertElementWithValueExists('ProjectedBalance', PurchaseLine.Quantity + PurchaseLine2.Quantity);
        end else begin
            Assert.AreEqual(ProductionOrder.Quantity, SelectScheduledReceipts(ProductionOrder."No."), ScheduledReceiptsErr);
            LibraryReportDataset.Reset();
            VerifyMultipleProjectedBalances(PurchaseLine, PurchaseLine2, ProductionOrder);
        end;
        VerifyMultipleSchedReceipts(PurchaseLine, PurchaseLine2);
    end;

    local procedure VerifyPurchaseAndFirmPlannedValuesForFRQItem(PurchaseLine: Record "Purchase Line"; PurchaseLine2: Record "Purchase Line"; ProductionOrder: Record "Production Order")
    begin
        VerifyMultipleProjectedBalances(PurchaseLine, PurchaseLine2, ProductionOrder);
        VerifyMultipleSchedReceipts(PurchaseLine, PurchaseLine2);
        Assert.AreEqual(ProductionOrder.Quantity, SelectScheduledReceipts(ProductionOrder."No."), ScheduledReceiptsErr);
    end;

    local procedure VerifyMultipleProjectedBalances(PurchaseLine: Record "Purchase Line"; PurchaseLine2: Record "Purchase Line"; ProductionOrder: Record "Production Order")
    begin
        LibraryReportDataset.AssertElementWithValueExists('ProjectedBalance', ProductionOrder.Quantity);
        LibraryReportDataset.AssertElementWithValueExists('ProjectedBalance', ProductionOrder.Quantity + PurchaseLine.Quantity);
        LibraryReportDataset.AssertElementWithValueExists('ProjectedBalance', ProductionOrder.Quantity + PurchaseLine.Quantity +
          PurchaseLine2.Quantity);
    end;

    local procedure VerifyMultipleSchedReceipts(PurchaseLine: Record "Purchase Line"; PurchaseLine2: Record "Purchase Line")
    begin
        LibraryReportDataset.AssertElementWithValueExists('PlngBuffScheduledReceipts', PurchaseLine.Quantity);
        Assert.AreEqual(PurchaseLine.Quantity + PurchaseLine2.Quantity,
          SelectScheduledReceipts(PurchaseLine."Document No."), ScheduledReceiptsErr);
    end;

    local procedure VerifyGrossReqAndProjectedBalanceForMultipleSales(SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line"; ProductionOrder: Record "Production Order")
    var
        SchedReceipts: Decimal;
    begin
        SchedReceipts := SelectScheduledReceipts(ProductionOrder."No.");
        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists('ProjectedBalance',
          SchedReceipts - SalesLine.Quantity - SalesLine2.Quantity);
        VerifySalesGrossRequirement(SalesLine);
        VerifySalesGrossRequirement(SalesLine2);
    end;

    local procedure VerifyMultiplePurchaseReceipts(SalesLine: Record "Sales Line"; ItemReorderQuantity: Decimal; CarryOutActionMessage: Boolean)
    begin
        if CarryOutActionMessage then begin
            LibraryReportDataset.AssertElementWithValueExists('PlngBuffScheduledReceipts', SalesLine.Quantity);
            LibraryReportDataset.AssertElementWithValueExists('PlngBuffScheduledReceipts', ItemReorderQuantity);
        end else begin
            LibraryReportDataset.AssertElementWithValueExists('ProjectedBalance', ItemReorderQuantity);
            Assert.AreEqual(SalesLine.Quantity + ItemReorderQuantity, SelectPlannedReceipts(), PlannedReceiptsErr);
        end;
    end;
#endif

    local procedure VerifyActionLinesExists(ItemNo: Code[20]; RecordShould: Option Exist,"Not Exist")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        Assert.AreEqual(RequisitionLine.IsEmpty, RecordShould = RecordShould::"Not Exist",
          StrSubstNo(RecordExistenceErr, RequisitionLine.TableCaption(), RecordShould));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), ConfirmMessage);
        Reply := true;
    end;
#if not CLEAN27
    local procedure CreateForecastEntry(var ProductionForecastEntry: Record "Production Forecast Entry"; var ProductionForecastName: Record "Production Forecast Name"; Item: Record Item; var EventDate: Date)
    begin
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        LibraryPlanning.SetDemandForecast(ProductionForecastName.Name);
        EventDate := GenerateRandomDateNextYear();
        LibraryManufacturing.CreateProductionForecastEntry(
          ProductionForecastEntry, ProductionForecastName.Name, Item."No.", '', EventDate, false);
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", LibraryRandom.RandInt(50));
        ProductionForecastEntry.Modify(true);
    end;

    local procedure GenerateRandomDateNextYear(): Date
    begin
        exit(CalcDate('<-CY + 1Y>', WorkDate()) + LibraryRandom.RandInt(365) - 1);
    end;

    [Normal]
    local procedure VerifyProductionForecastGrossRequirement(ProductionForecastEntry: Record "Production Forecast Entry")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('PlanningBuffDocNo', ProductionForecastEntry."Production Forecast Name");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('PlngBuffGrossRequirement', ProductionForecastEntry."Forecast Quantity (Base)");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PlanningAvailabilityRequestPageHandler(var PlanningAvailability: TestRequestPage "Planning Availability")
    begin
        PlanningAvailability.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
#endif
}

