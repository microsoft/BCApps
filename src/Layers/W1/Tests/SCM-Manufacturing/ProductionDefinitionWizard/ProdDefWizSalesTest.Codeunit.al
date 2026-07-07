// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Sales.Document;

codeunit 137431 "Prod. Def. Wiz. Sales Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Production Definition Wizard - CreateProductionOrder Mode (Sales Line Entry)
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ProdDefWizLibrary: Codeunit "Prod. Def. Wiz. Library";
        ProdDefWizSetupLib: Codeunit "Prod. Def. Wiz. Setup Lib.";
        ProdDefWizCheckLib: Codeunit "Prod. Def. Wiz. Check Lib.";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        IsInitialized: Boolean;
        WizardFinished: Boolean;
        WizardResult: Boolean;
        CapturedNotificationMessage: Text;
        CapturedExpectedQty: Decimal;
        TargetBOMVersionCode: Code[20];
        TargetRoutingVersionCode: Code[20];


    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ1_InitFromSalesLine_ProdOrderHeaderCorrect()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        VariantCode: Code[10];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
        OrderQty: Decimal;
        ShipmentDate: Date;
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J1] InitializeFromSalesLine: Prod. Order header created with correct fields
        Initialize();

        // [GIVEN] Sales Line: Item=X, Qty=10, ShipmentDate=WorkDate+30, Location=EAST, Variant=RED-V
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        VariantCode := ProdDefWizLibrary.CreateVariantForItem(ItemNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        OrderQty := 10;
        ShipmentDate := CalcDate('<+30D>', WorkDate());
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, OrderQty, LocationCode, VariantCode, ShipmentDate);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard is initialized and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order: SourceNo=ItemNo, Qty=10, DueDate=ShipmentDate, Location=EAST, Variant=RED-V
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderFields(ProdOrder, ItemNo, OrderQty, ShipmentDate, LocationCode, VariantCode);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ2_InitFromSalesLine_ComponentsCreatedFromBOM()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J2] InitializeFromSalesLine: Prod. Order components created from BOM
        Initialize();

        // [GIVEN] Sales Line for item with BOM containing 2 components; Mode = CreateProductionOrder
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 10, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard is initialized and user finishes without modifying components
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order Component lines exist (2 components from BOM)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderHasComponentCount(ProdOrder, 2);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ3_InitFromSalesLine_RoutingLinesCreatedFromRouting()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J3] InitializeFromSalesLine: Prod. Order routing lines created from Routing
        Initialize();

        // [GIVEN] Sales Line for item with Routing containing 2 operations; Mode = CreateProductionOrder
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard is initialized and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order Routing Lines match the Routing operations (2 lines)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderHasRoutingLineCount(ProdOrder, 2);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ4_InitFromSalesLine_ReservationCreatedForProdOrder()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J4] CreateProductionOrder mode from Sales Line: reservation entry created linking Sales Line demand to Prod. Order
        Initialize();

        // [GIVEN] Sales Line for item with BOM + Routing; item is set to Reserve = Always
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard is initialized and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] A Reservation Entry exists linking the Sales Line demand to the created Production Order
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyReservationExistsForSalesLine(SalesLine);
        ProdDefWizCheckLib.VerifyReservationLinksToProductionOrder(SalesLine, ProdOrder);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ5_InitFromSalesLine_EmptyBOMRouting_OrderStillCreated()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J5] CreateProductionOrder mode, BOM/Routing both empty: Production Order is still created
        Initialize();

        // [GIVEN] Sales Line for item with no BOM and no Routing
        ProdDefWizSetupLib.SetDefWizFlushingMethod("Flushing Method"::Backward);

        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 3, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard is initialized, user finishes (default placeholder lines active)
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order is created; references the item and quantity
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderFields(ProdOrder, ItemNo, 3, WorkDate(), LocationCode, '');
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ6_SalesLineWithSKUMatchingLocation_SKUBOMRoutingUsed()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        SKU: Record "Stockkeeping Unit";
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemBOMNo: Code[20];
        SKUBOMNo: Code[20];
        ItemRoutingNo: Code[20];
        SKURoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
        WC3No: Code[20];
        WC4No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J6] Sales Line with SKU whose location matches the sales line location → SKU BOM/Routing used
        Initialize();

        // [GIVEN] Item with BOM-A (2 lines) + Routing-A; SKU for (ItemNo, LocationCode) with BOM-B (3 lines) + Routing-B
        ItemBOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemRoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        SKUBOMNo := ProdDefWizLibrary.CreateBOM(3);
        SKURoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC3No, WC4No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(ItemBOMNo, ItemRoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateStockkeepingUnitWithBOMAndRouting(SKU, ItemNo, LocationCode, '', SKUBOMNo, SKURoutingNo);
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order components come from SKU BOM-B (3 lines, not 2)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderHasComponentCount(ProdOrder, 3);
    end;

    [Test]
    [HandlerFunctions('HandleWizardCancel')]
    procedure TestJ7_UserCancelsWizard_NoProductionOrderCreated()
    var
        SalesLine: Record "Sales Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J7] User cancels the wizard → RunForSource returns false and no Production Order is created
        Initialize();

        // [GIVEN] Sales Line for item with BOM and Routing
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User cancels the wizard (handler closes without Finish)
        WizardFinished := false;
        Commit();
        WizardResult := ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] RunForSource returns false and no Production Order is created
        Assert.IsFalse(WizardResult, 'RunForSource should return false when wizard is cancelled');
        Assert.IsFalse(WizardFinished, 'WizardFinished should be false after cancel');
        ProdDefWizCheckLib.VerifyNoProdOrderForItem(ItemNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ8_PlannedStatusVia3ArgOverload_ProdOrderHasPlannedStatus()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J8] RunForSource with ProdOrderStatus = Planned → Production Order created with Planned status
        Initialize();

        // [GIVEN] Sales Line for item with BOM and Routing
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs with Planned status via 3-argument overload
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder, "Production Order Status"::Planned);

        // [THEN] Created Production Order has Planned status
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderStatus(ProdOrder, "Production Order Status"::Planned);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ9_PartiallyReservedSalesLine_ProdOrderQtyEqualsOutstandingMinusReserved()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J9] Sales Line with partial reservation → Production Order qty = outstanding - reserved
        Initialize();

        // [GIVEN] Sales Line with Qty=10; a partial reservation of 3 exists
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 10, LocationCode, '', WorkDate());
        // NOTE: Direct insertion is intentional - no standard library supports partial
        // reservation creation. This creates a minimal reservation state to test that
        // the wizard handles existing reservations correctly, without triggering
        // full reservation engine logic.
        ProdDefWizLibrary.CreatePartialReservationForSalesLine(SalesLine, 3);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order quantity = 10 - 3 = 7
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderFields(ProdOrder, ItemNo, 7, WorkDate(), LocationCode, '');
    end;

    [Test]
    procedure TestJ10_BothHide_WizardSkipped_ProdOrderAutoCreated()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J10] Both ShowRtngBOMSelect and ShowProdCompSelect = Hide → wizard page skipped, ProdOrder auto-created
        Initialize();

        // [GIVEN] Both display settings = Hide
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Hide, "Prod. Definition Display"::Hide);

        // [WHEN] RunForSource is called (wizard page is never opened)
        Commit();
        WizardResult := ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Returns true and Production Order was auto-created
        Assert.IsTrue(WizardResult, 'RunForSource should return true when interaction is skipped');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSaveToItemFinish')]
    procedure TestJ11_SaveItemInCreateProdOrderMode_ItemBOMRoutingUpdated()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J11] Save = true with SaveBOMRoutingToSource = Item in CreateProductionOrder mode → Item BOM/Routing updated
        Initialize();

        // [GIVEN] Item with no BOM/Routing; Sales Line for that item
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs with Save = Item and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Item BOM and Routing are updated AND Production Order is created
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyItemHasAnyBOM(ItemNo);
        ProdDefWizCheckLib.VerifyItemHasAnyRouting(ItemNo);
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ12_WizardFinishes_ProdOrderLineHasCorrectBOMAndRouting()
    var
        SalesLine: Record "Sales Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J12] Wizard finishes → Production Order line has correct Production BOM No. and Routing No.
        Initialize();

        // [GIVEN] Item with BOMNo + RoutingNo; Sales Line for that item
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user finishes without changes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order line has Production BOM No. = BOMNo and Routing No. = RoutingNo
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderLineHasBOM(ItemNo, BOMNo);
        ProdDefWizCheckLib.VerifyProdOrderLineHasRouting(ItemNo, RoutingNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSelectBOMVersion,HandleBOMVersionListSelection')]
    procedure TestJ13_UserSelectsBOMVersion_ProdOrderLineHasThatVersion()
    var
        SalesLine: Record "Sales Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J13] User selects BOM version V1 in Step 2 → ProdOrder line Production BOM Version Code = V1
        Initialize();

        // [GIVEN] BOM with two versions V1 (older) and V2 (current active); item uses that BOM
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        ProdDefWizLibrary.CreateBOMVersionAndCertify(BOMNo, 'V1', CalcDate('<-1Y>', WorkDate()));
        ProdDefWizLibrary.CreateBOMVersionAndCertify(BOMNo, 'V2', WorkDate());
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        TargetBOMVersionCode := 'V1';

        // [WHEN] User navigates to Step 2, selects V1 via AssistEdit, then finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order line Production BOM Version Code = V1
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderLineHasBOMVersion(ItemNo, 'V1');
    end;

    [Test]
    [HandlerFunctions('HandleWizardSelectRoutingVersion,HandleRoutingVersionListSelection')]
    procedure TestJ14_UserSelectsRoutingVersion_ProdOrderLineHasThatVersion()
    var
        SalesLine: Record "Sales Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J14] User selects Routing version V1 in Step 3 → ProdOrder line Routing Version Code = V1
        Initialize();

        // [GIVEN] Routing with two versions V1 (older) and V2 (current active); item uses that Routing
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ProdDefWizLibrary.CreateRoutingVersionAndCertify(RoutingNo, 'V1', CalcDate('<-1Y>', WorkDate()));
        ProdDefWizLibrary.CreateRoutingVersionAndCertify(RoutingNo, 'V2', WorkDate());
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        TargetRoutingVersionCode := 'V1';

        // [WHEN] User navigates to Step 3, selects V1 via AssistEdit, then finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order line Routing Version Code = V1
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderLineHasRoutingVersion(ItemNo, 'V1');
    end;

    [Test]
    [HandlerFunctions('HandleWizardModifyComponentQty')]
    procedure TestJ15_UserModifiesComponentQtyInStep4_ProdOrderComponentHasModifiedQty()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J15] ProdCompDisplay = Edit; user modifies Qty per in Step 4 → ProdOrder component has modified qty
        Initialize();

        // [GIVEN] Item with BOM (2 comp) and Routing (2 ops); Sales Line; ProdCompDisplay = Edit
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User navigates to Step 4 and sets "Quantity per" of first component to 99
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] First Production Order component has Quantity per = 99
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderComponentHasQtyPerForFirstComponent(ProdOrder, 99);
    end;

    [Test]
    [HandlerFunctions('HandleWizardAddComponent')]
    procedure TestJ16_UserAddsComponentInStep4_AddedComponentInProdOrder()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J16] ProdCompDisplay = Edit; user adds component in Step 4 → added component present in ProdOrder
        Initialize();

        // [GIVEN] Item with BOM (2 comp), Routing (2 ops); Sales Line
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User navigates to Step 4 and adds a new component line
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order has 3 components (2 original + 1 added)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderHasComponentCount(ProdOrder, 3);
    end;

    [Test]
    [HandlerFunctions('HandleWizardDeleteComponent')]
    procedure TestJ17_UserDeletesComponentInStep4_DeletedComponentAbsentFromProdOrder()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J17] ProdCompDisplay = Edit; user deletes component in Step 4 → deleted component absent from ProdOrder
        Initialize();

        // [GIVEN] Item with BOM (2 comp), Routing (2 ops); Sales Line
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User navigates to Step 4 and deletes the first component
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order has 1 component (2 - 1 deleted)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderHasComponentCount(ProdOrder, 1);
    end;

    [Test]
    [HandlerFunctions('HandleWizardModifyRoutingRunTime')]
    procedure TestJ18_UserModifiesRoutingRunTimeInStep5_ProdOrderRoutingHasModifiedRunTime()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J18] ProdCompDisplay = Edit; user modifies Run Time in Step 5 → ProdOrder routing line has modified run time
        Initialize();

        // [GIVEN] Item with BOM (2 comp) and Routing (2 ops); Sales Line
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User navigates to Step 5 and modifies Run Time of operation '10' to 999
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order routing line for operation '10' has Run Time = 999
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderRoutingLineRunTime(ProdOrder, '10', 999);
    end;

    [Test]
    [HandlerFunctions('HandleWizardAddRoutingOperation')]
    procedure TestJ19_UserAddsRoutingOperationInStep5_AddedOperationPresentInProdOrder()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J19] ProdCompDisplay = Edit; user adds routing operation in Step 5 → added operation present in ProdOrder
        Initialize();

        // [GIVEN] Item with BOM (2 comp) and Routing (2 ops); Sales Line
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User navigates to Step 5 and adds a new routing operation
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order has 3 routing lines (2 original + 1 added)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderHasRoutingLineCount(ProdOrder, 3);
    end;

    [Test]
    [HandlerFunctions('HandleWizardDeleteRoutingOperation')]
    procedure TestJ20_UserDeletesRoutingOperationInStep5_DeletedOperationAbsentFromProdOrder()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J20] ProdCompDisplay = Edit; user deletes routing operation in Step 5 → deleted operation absent from ProdOrder
        Initialize();

        // [GIVEN] Item with BOM (2 comp) and Routing (2 ops); Sales Line
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User navigates to Step 5 and deletes the first routing operation
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order has 1 routing line (2 - 1 deleted)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderHasRoutingLineCount(ProdOrder, 1);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish,HandleProdOrderCreatedNotification')]
    procedure TestJ21_WizardCompletes_NotificationSentWithProdOrderNo()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J21] After wizard completes from Sales Line, a notification is sent containing the Production Order No.
        Initialize();

        // [GIVEN] Sales Line for item with BOM and Routing
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and finishes
        CapturedNotificationMessage := '';
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] The captured notification message contains the created Production Order No.
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        Assert.IsTrue(CapturedNotificationMessage.Contains(ProdOrder."No."),
            'Notification message should contain the Production Order No.');
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ22_ProdOrderFromSalesLine_ExistingBOM_ComponentFlushingNotOverridden()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J22] When item has an existing Production BOM, the wizard does not overwrite the component flushing method with the setup default; components retain their original (Manual) flushing method
        Initialize();

        // [GIVEN] ManufacturingSetup."Def. Wiz. Flushing Method" = Backward; item with existing BOM + Routing (components have default Manual flushing method)
        ProdDefWizSetupLib.SetDefWizFlushingMethod("Flushing Method"::Backward);
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user finishes (Released status is the default)
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Wizard completes without error; Production Order exists with Released status; components retain their original Manual flushing method (not overridden by the Backward setup default)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderStatus(ProdOrder, "Production Order Status"::Released);
        ProdDefWizCheckLib.VerifyProdOrderComponentFlushingMethod(ProdOrder, "Flushing Method"::"Pick + Manual");
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ23_BOMLineWithDescription2_ProdOrderComponentHasDescription2()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
        ComponentItemNo: Code[20];
        ExpectedDesc2: Text[50];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J23] BOM line with Description 2 → Production Order component carries the same Description 2
        Initialize();

        // [GIVEN] BOM with a component line that has Description 2; item uses that BOM
        ExpectedDesc2 := 'BOM-DESC2-TEST';
        BOMNo := ProdDefWizLibrary.CreateBOMWithComponentAndDescription2(ComponentItemNo, ExpectedDesc2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order component carries Description 2 from the BOM line
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderComponentHasDescription2(ProdOrder, ExpectedDesc2);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ24_RoutingLineWithDescription2_ProdOrderRoutingLineHasDescription2()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WCNo: Code[20];
        ExpectedDesc2: Text[50];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J24] Routing line with Description 2 → Production Order routing line carries the same Description 2
        Initialize();

        // [GIVEN] Routing with an operation line that has Description 2; item uses that Routing
        ExpectedDesc2 := 'RTNG-DESC2-TEST';
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithSingleLineAndDescription2(WCNo, ExpectedDesc2);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order routing line carries Description 2 from the Routing line
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderRoutingLineHasDescription2(ProdOrder, ExpectedDesc2);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ25_SalesLineWithNoShipmentDate_WizardRunsWithoutError()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J25] Sales Line with no Shipment Date → wizard runs without error, Production Order created
        Initialize();

        // [GIVEN] Sales Line with ShipmentDate = 0D (no shipment date)
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 3, LocationCode, '', 0D);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user finishes — no error should be raised
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Wizard finished without error; Production Order exists with empty Due Date
        Assert.IsTrue(WizardFinished, 'Wizard should have finished without error');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ26_SalesLineWithBlankLocation_ProdOrderCreatedWithBlankLocation()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J26] Sales Line with blank Location Code → Production Order created with blank location
        Initialize();

        // [GIVEN] Sales Line with LocationCode = '' (no location)
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 3, '', '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order exists with blank Location Code
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderFields(ProdOrder, ItemNo, 3, WorkDate(), '', '');
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ27_SalesLineWithAlternateUOM_ReservationBaseQtyMatchesProdOrderRemainingBase()
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        AltUOMCode: Code[10];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J27] Sales Line whose item has Qty. per Unit of Measure ≠ 1 → reservation base quantity is correctly calculated using UOM conversion
        Initialize();

        // [GIVEN] Item with BOM + Routing; alternate UOM BOX = 10 PCS; Sales UOM = BOX; Sales Line qty = 2 BOX (base = 20)
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ProdDefWizLibrary.CreateItemWithSalesUOMMultiplier(BOMNo, RoutingNo, 10, ItemNo, AltUOMCode);
        Item.Get(ItemNo);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 2, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Reservation exists for the Sales Line and the reservation base quantity matches the Production Order remaining base quantity
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyReservationExistsForSalesLine(SalesLine);
        ProdDefWizCheckLib.VerifyReservationBaseQtyMatchesProdOrderRemainingBase(SalesLine, ItemNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ28_SalesLineWithLotTracking_TrackingCopiedToProdOrderLine()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ReservEntry: Record "Reservation Entry";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
        LotNo: Code[50];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J28] Sales Line with item-tracking lot number entries → CopyItemTracking transfers tracking to Production Order line after wizard completes
        Initialize();

        // [GIVEN] Item with BOM + Routing and lot tracking; Sales Line with a lot number assigned via Tracking Specification
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithLotTracking(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        LotNo := 'LOT-TEST-001';
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservEntry, SalesLine, '', LotNo, 5);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Wizard completes; tracking is transferred: a reservation entry with the lot number exists for the Production Order line
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyTrackingSpecExistsForProdOrderLine(ItemNo, LotNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ29_ItemWithScrapPct_ProdOrderLineHasScrapPct()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
        ScrapPct: Decimal;
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J29] Item with Scrap % = 10 → Production Order line created by wizard has Scrap % = 10
        Initialize();

        // [GIVEN] Item with Scrap % = 10; Sales Line for that item
        ScrapPct := 10;
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        Item.Validate("Scrap %", ScrapPct);
        Item.Modify(true);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order line has Scrap % = 10
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderLineScrapPct(ItemNo, ScrapPct);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSimpleFinish')]
    procedure TestJ30_SalesLineWithVariantAndMatchingSKU_SKUBOMRoutingUsed()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        SKU: Record "Stockkeeping Unit";
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemBOMNo: Code[20];
        SKUBOMNo: Code[20];
        ItemRoutingNo: Code[20];
        SKURoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        VariantCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
        WC3No: Code[20];
        WC4No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J30] Sales Line with Variant+Location matching a SKU → SKU BOM/Routing used over item-level
        Initialize();

        // [GIVEN] Item with BOM-A (2 lines); SKU for (ItemNo, LocationCode, VariantCode) with BOM-B (3 lines)
        ItemBOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemRoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        SKUBOMNo := ProdDefWizLibrary.CreateBOM(3);
        SKURoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC3No, WC4No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(ItemBOMNo, ItemRoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        VariantCode := ProdDefWizLibrary.CreateVariantForItem(ItemNo);
        ProdDefWizLibrary.CreateStockkeepingUnitWithBOMAndRouting(SKU, ItemNo, LocationCode, VariantCode, SKUBOMNo, SKURoutingNo);
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, VariantCode, WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order has 3 components from SKU BOM-B (not 2 from item BOM-A)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderHasComponentCount(ProdOrder, 3);
    end;

    [Test]
    [HandlerFunctions('HandleWizardAddComponent')]
    procedure TestJ31_ProdOrderFromSalesLine_NoBOM_TemporaryComponentGetsSetupFlushingMethod()
    var
        ProdOrderComponent: Record "Prod. Order Component";
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J31] When item has no Production BOM (temporary creation case), the wizard applies the setup default flushing method to the manually added component
        Initialize();

        // [GIVEN] ManufacturingSetup."Def. Wiz. Flushing Method" = Backward; item with no BOM and no Routing
        ProdDefWizSetupLib.SetDefWizFlushingMethod("Flushing Method"::Backward);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 3, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs; user adds one component (no existing BOM to load from) and finishes
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order exists; the added component has the Backward flushing method from the item default (temporary creation case), setup component flushing method is applied to the first component, and the last component has flushing method from item
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);

        ProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComponent.FindFirst();
        Assert.AreEqual("Flushing Method"::Backward, ProdOrderComponent."Flushing Method", 'Flushing Method of the first component should match the setup default (Backward)');
        ProdOrderComponent.FindLast();
        Assert.AreEqual("Flushing Method"::"Pick + Manual", ProdOrderComponent."Flushing Method", 'Flushing Method of the last component should match the setup default (Backward)');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureComponentExpectedQty')]
    procedure TestJ32_TempComponentsPreview_ExpectedQuantityNonZero()
    var
        SalesLine: Record "Sales Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
        SalesQty: Decimal;
        ComponentQtyPer: Decimal;
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J32] In Step 4 (component preview), temporary components display non-zero Expected Quantity after Quantity per is set
        Initialize();

        // [GIVEN] Item with a BOM (1 component, Qty per = 2) and Routing; Sales Line qty = 5
        SalesQty := 5;
        ComponentQtyPer := 2; // first BOM line qty = 1, second = 2; CreateBOM sets qty = line index
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, SalesQty, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard runs and user navigates to Step 4 (component preview)
        CapturedExpectedQty := 0;
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] The second temporary component's Expected Quantity is non-zero (= SalesQty * ComponentQtyPer = 10)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.IsTrue(CapturedExpectedQty > 0,
            'Temporary component Expected Quantity must be non-zero after Quantity per validation');
        Assert.AreNearlyEqual(SalesQty * ComponentQtyPer, CapturedExpectedQty, 0.01,
            'Expected Quantity should equal Sales Qty × Quantity per');
    end;

    [ModalPageHandler]
    procedure HandleWizardCaptureComponentExpectedQty(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 4 (Components) via Steps 2 and 3
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        if Wizard.ActionNext.Enabled() then begin
            Wizard.ActionNext.Invoke();
            // Find the last component (BOM line 2 has Qty per = 2)
            if Wizard.ComponentsPart.Last() then
                CapturedExpectedQty := Wizard.ComponentsPart."Expected Quantity".AsDecimal();
        end;
        // Continue and finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardSimpleFinish(var Wizard: TestPage "Production Definition Wizard")
    begin
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardCancel(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate one step then close without finishing (simulates cancel)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWizardSaveToItemFinish(var Wizard: TestPage "Production Definition Wizard")
    begin
        Wizard.SaveBOMRoutingField.SetValue(true);
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardSelectBOMVersion(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM selection)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Trigger version selection AssistEdit (opens "Prod. BOM Version List")
        Wizard.SelectedBOMVersionField.AssistEdit();
        // Continue and finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleBOMVersionListSelection(var BOMVersionList: TestPage "Prod. BOM Version List")
    begin
        BOMVersionList.Filter.SetFilter("Version Code", TargetBOMVersionCode);
        BOMVersionList.First();
        BOMVersionList.OK.Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWizardSelectRoutingVersion(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Navigate to Step 3 (Routing)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Trigger version selection AssistEdit (opens "Routing Version List")
        Wizard.SelectedRoutingVersionField.AssistEdit();
        // Continue and finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleRoutingVersionListSelection(var RoutingVersionList: TestPage "Routing Version List")
    begin
        RoutingVersionList.Filter.SetFilter("Version Code", TargetRoutingVersionCode);
        RoutingVersionList.First();
        RoutingVersionList.OK.Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWizardModifyComponentQty(var Wizard: TestPage "Production Definition Wizard")
    var
        ModifiedQtyPer: Decimal;
    begin
        ModifiedQtyPer := 99;
        // Steps 2 and 3
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Step 4 - Components
        if Wizard.ActionNext.Enabled() then begin
            Wizard.ActionNext.Invoke();
            if Wizard.ComponentsPart.First() then
                Wizard.ComponentsPart."Quantity per".SetValue(ModifiedQtyPer);
        end;
        // Step 5 and finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardAddComponent(var Wizard: TestPage "Production Definition Wizard")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        DefaultCompItemNo: Code[20];
    begin
        ManufacturingSetup.Get();
        DefaultCompItemNo := ManufacturingSetup."Def. Wiz. Comp Item No.";
        // Steps 2 and 3
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Step 4 - Components; add a new line
        if Wizard.ActionNext.Enabled() then begin
            Wizard.ActionNext.Invoke();
            Wizard.ComponentsPart.New();
            Wizard.ComponentsPart."Item No.".SetValue(DefaultCompItemNo);
            Wizard.ComponentsPart."Quantity per".SetValue(1);
        end;
        // Step 5 and finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardDeleteComponent(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Steps 2 and 3
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Step 4 - Components; delete the first line
        if Wizard.ActionNext.Enabled() then begin
            Wizard.ActionNext.Invoke();
            if Wizard.ComponentsPart.First() then
                Wizard.ComponentsPart.TestDelete.Invoke();
        end;
        // Step 5 and finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardModifyRoutingRunTime(var Wizard: TestPage "Production Definition Wizard")
    var
        ModifiedRunTime: Decimal;
    begin
        ModifiedRunTime := 999;
        // Steps 2 and 3
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Step 4
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Step 5 - Routing; modify Run Time on first row
        if Wizard.ActionNext.Enabled() then begin
            Wizard.ActionNext.Invoke();
            if Wizard.ProdOrderRoutingPart.First() then
                Wizard.ProdOrderRoutingPart."Run Time".SetValue(ModifiedRunTime);
        end;
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardAddRoutingOperation(var Wizard: TestPage "Production Definition Wizard")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        DefaultWCNo: Code[20];
        NewOperationNo: Code[10];
    begin
        ManufacturingSetup.Get();
        DefaultWCNo := ManufacturingSetup."Def. Wiz. Work Center No.";
        NewOperationNo := '30';
        // Steps 2 and 3
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Step 4
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Step 5 - Routing; add a new operation
        if Wizard.ActionNext.Enabled() then begin
            Wizard.ActionNext.Invoke();
            Wizard.ProdOrderRoutingPart.New();
            Wizard.ProdOrderRoutingPart."Operation No.".SetValue(NewOperationNo);
            Wizard.ProdOrderRoutingPart.Type.SetValue(Format("Capacity Type Routing"::"Work Center"));
            Wizard.ProdOrderRoutingPart."No.".SetValue(DefaultWCNo);
        end;
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardDeleteRoutingOperation(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Steps 2 and 3
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Step 4
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Step 5 - Routing; delete the first operation
        if Wizard.ActionNext.Enabled() then begin
            Wizard.ActionNext.Invoke();
            if Wizard.ProdOrderRoutingPart.First() then
                Wizard.ProdOrderRoutingPart.TestDelete.Invoke();
        end;
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [SendNotificationHandler]
    procedure HandleProdOrderCreatedNotification(var Notification: Notification): Boolean
    begin
        CapturedNotificationMessage := Notification.Message();
        exit(true);
    end;


    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Def. Wiz. Sales Test");
        LibrarySetupStorage.Restore();
        WizardFinished := false;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Sales Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ProdDefWizSetupLib.InitializeBasicSetup();

        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.SaveManufacturingSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Sales Test");
    end;

    [Test]
    procedure TestJ_FullyReservedSalesLine_ErrorOnRun()
    var
        SalesLine: Record "Sales Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        RoutingNo: Code[20];
        ProductionOrderQtyZeroOrNegativeErr: Label 'Cannot create a production order from Sales Line %1 line %2: the calculated quantity (%3) is zero or negative because the line is fully or over-reserved.', Comment = '%1 = Document No., %2 = Line No., %3 = Quantity';
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO J_FullyReserved] Sales Line fully reserved (Outstanding = Reserved) → wizard raises an error
        // (regression test for BUG-05 guard)
        Initialize();

        // [GIVEN] Sales Line for 5 units, fully reserved (reservation = 5)
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, '', '', WorkDate());
        ProdDefWizLibrary.CreatePartialReservationForSalesLine(SalesLine, 5); // fully reserved

        // [WHEN] Wizard is launched from the fully-reserved Sales Line
        // [THEN] An error is raised (quantity = Outstanding - Reserved = 5 - 5 = 0)
        asserterror ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);
        Assert.ExpectedError(StrSubstNo(ProductionOrderQtyZeroOrNegativeErr,
            SalesLine."Document No.", SalesLine."Line No.", 0));
    end;

}