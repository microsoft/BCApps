// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Journal;
using System.TestLibraries.Utilities;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Costing;
#if not CLEAN27
using Microsoft.Manufacturing.Forecast;
#endif
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Family;
using Microsoft.Sales.Document;
using Microsoft.Inventory.BOM;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Inventory.Reports;
using Microsoft.Assembly.Reports;

codeunit 137304 "SCM Manufacturing Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Reports] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        ProductionOrderErr: Label 'Production Order No. must exist.';
        RecordErr: Label 'Record must not be empty.';
        ElementNotFoundErr: Label 'Element not found for %1';
        MissingQst: Label '\\  * Some output is still missing.\  * Some consumption is still missing.\\ Do you still want to finish the order?';

    [Test]
    [HandlerFunctions('ProdOrderCompAndRoutingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlannedProdOrderCompRouting()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Planned);  // Create Planned Production Order.
        ProdOrderCompAndRoutingReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderCompAndRoutingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlanProdOrderCompRouting()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::"Firm Planned");  // Create Firm Planned Production Order.
        ProdOrderCompAndRoutingReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderCompAndRoutingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderCompRouting()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Released Production Order.
        ProdOrderCompAndRoutingReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ProdOrderCompAndRoutingRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinishedProdOrderCompRouting()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Production Order and Refresh.
        FinishProductionOrder(ProductionOrder."No.");
        ProdOrderCompAndRoutingReport(ProductionOrder.Status::Finished, ProductionOrder."No.");  // Finish Production Order.

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure ProdOrderCompAndRoutingReport(ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        // Exercise: Generate the Production Order Component And Routing report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        REPORT.Run(REPORT::"Prod. Order Comp. and Routing", true, false, ProductionOrder);

        // Verify: Check the value of Production Order No, Production Item, Components, Work Center, Machine Center in the report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        ProductionOrder.FindFirst();
        VerifyProductionOrder(ProductionOrder, 'No_ProductionOrder', 'ItemNo_ProdOrderLine');
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status, 'ItemNo_PrdOrdrComp');
        VerifyRoutingLine(ProductionOrder."Routing No.", 'No_ProdOrderRoutingLine');
    end;

    [Test]
    [HandlerFunctions('ProdOrderJobCardRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlannedProdOrderJobCard()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Planned);  // Create Planned Production Order.
        ProdOrderJobCardReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderJobCardRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlanProdOrderJobCard()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::"Firm Planned");  // Create Firm Planned Production Order.
        ProdOrderJobCardReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderJobCardRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderJobCard()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Released Production Order.
        ProdOrderJobCardReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ProdOrderJobCardRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinishedProdOrderJobCard()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Production Order and Refresh.
        FinishProductionOrder(ProductionOrder."No.");
        ProdOrderJobCardReport(ProductionOrder.Status::Finished, ProductionOrder."No.");  // Finish Production Order.

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure ProdOrderJobCardReport(ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        // Exercise: Generate the Production Order Job card report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        REPORT.Run(REPORT::"Prod. Order - Job Card", true, false, ProductionOrder);

        // Verify: Check the value of Production Order, Production Item and Production Components.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        ProductionOrder.FindFirst();
        VerifyProductionOrder(ProductionOrder, 'No_ProdOrder', 'SourceNo_ProdOrder');
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status, 'ItemNo_ProdOrderComp');
        VerifyRoutingLine(ProductionOrder."Routing No.", 'No_ProdOrderRtngLine');
    end;

    [Test]
    [HandlerFunctions('ProdOrderPrecalcTimeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlannedProdOrderPrecalcTime()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Planned);  // Create Planned Production Order.
        ProdOrderPrecalcTimeReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderPrecalcTimeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlanProdOrderPreCalcTime()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::"Firm Planned");  // Create Firm Planned Production Order.
        ProdOrderPrecalcTimeReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderPrecalcTimeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderPrecalcTime()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Released Production Order.
        ProdOrderPrecalcTimeReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ProdOrderPrecalcTimeRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinishedProdOrderPrecalcTime()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Production Order and Refresh.
        FinishProductionOrder(ProductionOrder."No.");
        ProdOrderPrecalcTimeReport(ProductionOrder.Status::Finished, ProductionOrder."No.");  // Finish Production Order.

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure ProdOrderPrecalcTimeReport(ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        // Exercise: Generate the Production Order PreCalc. Time report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        REPORT.Run(REPORT::"Prod. Order - Precalc. Time", true, false, ProductionOrder);

        // Verify: Check the value of Production Order No, Production Item, Work Center, Machine Center in the report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        ProductionOrder.FindFirst();
        VerifyProductionOrder(ProductionOrder, 'Production_Order__No__', 'Production_Order__Source_No__');
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status, 'Prod__Order_Component__Item_No__');
        VerifyRoutingLine(ProductionOrder."Routing No.", 'Prod__Order_Routing_Line__No__');
    end;

    [Test]
    [HandlerFunctions('ProdOrderMatRequisitionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlannedProdOrderMatRequisition()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Planned);  // Create Planned Production Order.
        ProdOrderMatRequisitionReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderMatRequisitionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlanProdOrdMatRequisition()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::"Firm Planned");  // Create Firm Planned Production Order.
        ProdOrderMatRequisitionReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderMatRequisitionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReleasedProdOrdMatRequisition()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Released Production Order.
        ProdOrderMatRequisitionReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ProdOrderMatRequisitionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinishedProdOrdMatRequisition()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Production Order and Refresh.
        FinishProductionOrder(ProductionOrder."No.");
        ProdOrderMatRequisitionReport(ProductionOrder.Status::Finished, ProductionOrder."No.");  // Finish Production Order.

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure ProdOrderMatRequisitionReport(ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        // Exercise: Generate the Production Order Material requisition report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        REPORT.Run(REPORT::"Prod. Order - Mat. Requisition", true, false, ProductionOrder);

        // Verify: Check the value of Production Order No, Production Item, Components in the report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        ProductionOrder.FindFirst();
        VerifyProductionOrder(ProductionOrder, 'No_ProdOrder', 'SourceNo_ProdOrder');
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status, 'ItemNo_ProdOrderComp');
    end;

    [Test]
    [HandlerFunctions('ProdOrderPickingListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlannedProdOrderPickingList()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Planned);  // Create Planned Production Order.
        ProdOrderPickingListReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderPickingListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlanProdOrderPickingList()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::"Firm Planned");  // Create Firm Planned Production Order.
        ProdOrderPickingListReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderPickingListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderPickingList()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Released Production Order.
        ProdOrderPickingListReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    local procedure ProdOrderPickingListReport(ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
    begin
        // Exercise: Generate the Production Order Picking List report.
        SelectProdOrderComponent(ProdOrderComponent, ProductionOrderNo, ProductionOrderStatus);
        Item.SetRange("No.", ProdOrderComponent."Item No.");
        REPORT.Run(REPORT::"Prod. Order - Picking List", true, false, Item);

        // Verify: Check the value of Production Order No, Production Item and Component in the report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        ProductionOrder.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', ProdOrderComponent."Item No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('RmngQty_ProdOrderComp', ProdOrderComponent."Remaining Quantity");
        LibraryReportDataset.AssertCurrentRowValueEquals('ProdOrdNo_ProdOrderComp', ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderDetailedCalcRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlannedProdOrderDetailedCalc()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Planned);  // Create Planned Production Order.
        ProdOrderDetailedCalcReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderDetailedCalcRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlanProdOrderDetailedCalc()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::"Firm Planned");  // Create Firm Planned Production Order.
        ProdOrderDetailedCalcReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderDetailedCalcRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderDetailedCalc()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Released Production Order.
        ProdOrderDetailedCalcReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ProdOrderDetailedCalcRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinishedProdOrderDetailedCalc()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Production Order and Refresh.
        FinishProductionOrder(ProductionOrder."No.");
        ProdOrderDetailedCalcReport(ProductionOrder.Status::Finished, ProductionOrder."No.");  // Finish Production Order.

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure ProdOrderDetailedCalcReport(ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        // Exercise: Generate the Production Order Detailed Calc. report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        REPORT.Run(REPORT::"Prod. Order - Detailed Calc.", true, false, ProductionOrder);

        // Verify: Check the value of Production Order No, Production Item, Component, and Routing in the report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        ProductionOrder.FindFirst();
        VerifyProductionOrder(ProductionOrder, 'No_ProdOrder', 'SourceNo_ProdOrder');
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status, 'ItemNo_ProdOrderComp');
        VerifyRoutingLine(ProductionOrder."Routing No.", 'No_ProdOrderRtngLine');
    end;

    [Test]
    [HandlerFunctions('ProdOrderShortageListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlannedProdOrderShortageList()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Planned);  // Create Planned Production Order.
        ProdOrderShortageListReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderShortageListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlanProdOrderShortageList()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::"Firm Planned");  // Create Firm Planned Production Order.
        ProdOrderShortageListReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderShortageListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderShortageList()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Released Production Order.
        ProdOrderShortageListReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ProdOrderShortageListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinishedProdOrderShortageList()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Production Order and Refresh.
        FinishProductionOrder(ProductionOrder."No.");
        ProdOrderShortageListReport(ProductionOrder.Status::Finished, ProductionOrder."No.");  // Finish Production Order.

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure ProdOrderShortageListReport(ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        // Exercise: Generate the Production Order Shortage List report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        REPORT.Run(REPORT::"Prod. Order - Shortage List", true, false, ProductionOrder);

        // Verify: Check the value of Production Order No, Production Item and Component in the report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        ProductionOrder.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_ProdOrder', ProductionOrder."No.");
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status, 'ItemNo_ProdOrderComp');
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PlannedProdOrderStatistics()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Planned);  // Create Planned Production Order.
        ProdOrderStatisticsReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlanProdOrderStatistics()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::"Firm Planned");  // Create Firm Planned Production Order.
        ProdOrderStatisticsReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderStatistics()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Released Production Order.
        ProdOrderStatisticsReport(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ProdOrderStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinishedProdOrderStatistics()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Production Order and Refresh.
        FinishProductionOrder(ProductionOrder."No.");
        ProdOrderStatisticsReport(ProductionOrder.Status::Finished, ProductionOrder."No.");  // Finish Production Order.

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure ProdOrderStatisticsReport(ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        ShareOfTotalCapCost: Decimal;
        ExpMatCost: Decimal;
        ExpCapDirCost: Decimal;
        ExpSubDirCost: Decimal;
        ExpCapOvhdCost: Decimal;
        ExpMfgOvhdCost: Decimal;
    begin
        // Exercise: Generate the Production Order Statistics report.
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, ProductionOrderNo);
        REPORT.Run(REPORT::"Production Order Statistics", true, false, ProductionOrder);

        // Verify: Check the value of Production Order No, Production Item in the report.
        ProductionOrder.FindFirst();
        SelectProdOrderLine(ProdOrderLine, ProductionOrder."No.", ProductionOrder.Status);
        MfgCostCalculationMgt.CalcShareOfTotalCapCost(ProdOrderLine, ShareOfTotalCapCost);
        Assert.AreEqual(1, ShareOfTotalCapCost, '');
        MfgCostCalculationMgt.CalcProdOrderLineExpCost(ProdOrderLine, ShareOfTotalCapCost, ExpMatCost,
          ExpCapDirCost, ExpSubDirCost, ExpCapOvhdCost, ExpMfgOvhdCost);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ProdOrder', ProductionOrder."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ExpCost1', ExpMatCost);
        LibraryReportDataset.AssertCurrentRowValueEquals('ExpCost6', ExpMatCost + ExpCapDirCost + ExpSubDirCost +
          ExpCapOvhdCost + ExpMfgOvhdCost);
    end;
#if not CLEAN27
    [Test]
    [HandlerFunctions('ProductionForecastRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderForecastReport()
    var
        Item: Record Item;
        ProductionForecastName: Record "Production Forecast Name";
        ProductionForecastEntry: Record "Production Forecast Entry";
    begin
        // Setup: Create Production Forecast Setup.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        LibraryManufacturing.CreateProductionForecastEntry(
          ProductionForecastEntry, ProductionForecastName.Name, Item."No.", '', WorkDate(), false);
        UpdateProductionForecastQty(ProductionForecastEntry);

        // Exercise: Generate the Production Forecast report.
        Commit();
        ProductionForecastEntry.SetRange("Item No.", Item."No.");
        REPORT.Run(REPORT::"Demand Forecast", true, false, ProductionForecastEntry);

        // Verify: Check that Item No exists in the Production Forecast report and verify Forecast Quantity.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo_ForecastEntry', ProductionForecastEntry."Item No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ForecastQty_ForecastEntry', ProductionForecastEntry."Forecast Quantity");
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure ItemProdOrderRefresh()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Parent and Child Items.
        Initialize();
        CreateProdOrderItemsSetup(Item);
        ProdOrderRefreshReport(ProductionOrder."Source Type"::Item, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FamilyProdOrderRefresh()
    var
        Item: Record Item;
        Item2: Record Item;
        RoutingHeader: Record "Routing Header";
        Family: Record Family;
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Parent Items, Routing and Family.
        Initialize();
        CreateProdOrderItemsSetup(Item);
        ClearRouting(Item);
        CreateProdOrderItemsSetup(Item2);
        ClearRouting(Item2);
        CreateRoutingSetup(RoutingHeader);
        CreateFamily(Family, RoutingHeader."No.", Item."No.", Item2."No.");
        ProdOrderRefreshReport(ProductionOrder."Source Type"::Family, Family."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesProdOrderRefresh()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Parent and Child Items, Sales Order.
        Initialize();
        CreateProdOrderItemsSetup(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        ProdOrderRefreshReport(ProductionOrder."Source Type"::"Sales Header", SalesHeader."No.");
    end;

    local procedure ProdOrderRefreshReport(SourceType: Enum "Production Order Status"; SourceNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Create Production Order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, SourceType, SourceNo, LibraryRandom.RandInt(5));

        // Exercise: Refresh Released Production Order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Check that corresponding Production Order Line and Production Order Components list has been populated.
        SelectProdOrderLine(ProdOrderLine, ProductionOrder."No.", ProductionOrder.Status::Released);
        Assert.IsTrue(ProdOrderLine.Count > 0, RecordErr);
        SelectProdOrderComponent(ProdOrderComponent, ProductionOrder."No.", ProductionOrder.Status::Released);
        Assert.IsTrue(ProdOrderComponent.Count > 0, RecordErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcConsumptionReport()
    var
        ProductionOrder: Record "Production Order";
        ItemJournalBatch2: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);

        // Exercise: Run Calculate Consumption report.
        ConsumptionJournalSetup(ItemJournalBatch2);
        ClearJournal(ItemJournalBatch2);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrder."No.", ItemJournalBatch2."Journal Template Name", ItemJournalBatch2.Name);

        // Verify: Check Consumption Journal Lines have been populated after execution of Calc. Consumption report.
        SelectConsumptionLines(ItemJournalLine, ItemJournalBatch2);
        Assert.IsTrue(ItemJournalLine.Count > 0, RecordErr);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        Assert.IsTrue(ItemJournalLine.Count > 0, ProductionOrderErr);
        VerifyConsumptionJrnlItems(ItemJournalLine, ProductionOrder."No.", ProductionOrder.Status);
    end;

    [Test]
    [HandlerFunctions('CapacityTaskListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterCapacityTaskList()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        ProdCapacityTaskListReport(ProductionOrder, ProdOrderRoutingLine.Type::"Work Center");

        // Verify: Check Production Order No, Routing No and Work Center No exist in the report.
        VerifyCapacityTaskList(ProductionOrder, ProdOrderRoutingLine.Type::"Work Center");
    end;

    [Test]
    [HandlerFunctions('CapacityTaskListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MachineCenterCapacityTaskList()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
    begin
        // Setup.
        Initialize();
        ProdCapacityTaskListReport(ProductionOrder, ProdOrderRoutingLine.Type::"Machine Center");

        // Verify: Check Production Order No, Routing No exist in the report.
        VerifyCapacityTaskList(ProductionOrder, ProdOrderRoutingLine.Type::"Machine Center");
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BOMsReport()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        // Setup: Create BOM Component Setup.
        Initialize();
        CreateBOMComponentSetup(BOMComponent);

        // Exercise: Generate the BOMs report.
        Item.SetRange("No.", BOMComponent."Parent Item No.");
        REPORT.Run(REPORT::"Assembly BOMs", true, false, Item);

        // Verify: Check parent Item and child Item in the report.
        VerifyBOMItems(BOMComponent, 'No_BOMComp', 'No_Item');
    end;

    [Test]
    [HandlerFunctions('WhereUsedListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WhereUsedListReport()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        // Setup: Create BOM Component Setup.
        Initialize();
        CreateBOMComponentSetup(BOMComponent);

        // Exercise: Generate the Where-Used List report.
        Item.SetRange("No.", BOMComponent."No.");
        REPORT.Run(REPORT::"Where-Used List", true, false, Item);

        // Verify: Check parent Item and child Item in the report.
        VerifyBOMItems(BOMComponent, 'No_Item', 'ParentItemNo_BOMComponent');
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMRawMaterialsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BOMRawMaterialsReport()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        // Setup: Create BOM Component Setup.
        Initialize();
        CreateBOMComponentSetup(BOMComponent);

        // Exercise: Generate the BOM Raw Materials report.
        Item.SetRange("No.", BOMComponent."No.");
        REPORT.Run(REPORT::"Assembly BOM - Raw Materials", true, false, Item);

        // Verify: Check child Item on BOM exists in the report.
        Item.FindFirst();
        Item.CalcFields(Inventory);
        VerifyBOMItem(Item."No.", 'No_Item');
        LibraryReportDataset.AssertCurrentRowValueEquals('Inventory_Item', Item.Inventory);
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMEndItemsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BOMFinishedGoodsReport()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        // Setup: Create BOM Component Setup.
        Initialize();
        CreateBOMComponentSetup(BOMComponent);

        // Exercise: Generate the BOM Finished Goods report.
        Item.SetRange("No.", BOMComponent."Parent Item No.");
        REPORT.Run(REPORT::"Assembly BOM - End Items", true, false, Item);

        // Verify: Check parent Item on BOM exists in the report.
        Item.FindFirst();
        Item.CalcFields(Inventory);
        VerifyBOMItem(BOMComponent."Parent Item No.", 'No_Item');
        LibraryReportDataset.AssertCurrentRowValueEquals('Inventory_Item', Item.Inventory);
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMSubassembliesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BOMSubAssembliesReport()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        BOMComponent2: Record "BOM Component";
    begin
        // Setup: Create BOM Component Setup.
        Initialize();
        CreateBOMComponentSetup(BOMComponent);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateBOMComponent(BOMComponent2, BOMComponent."No.", BOMComponent2.Type::Item, Item."No.", 1, '');

        // Exercise: Generate the BOM - Sub Assemblies report.
        Commit();
        Item.SetRange("No.", BOMComponent2."Parent Item No.");
        REPORT.Run(REPORT::"Assembly BOM - Subassemblies", true, false, Item);

        // Verify: Check parent Item on BOM exists in the report.
        Item.FindFirst();
        Item.CalcFields(Inventory);
        VerifyBOMItem(BOMComponent2."Parent Item No.", 'No_Item');
        LibraryReportDataset.AssertCurrentRowValueEquals('Inventory_Item', Item.Inventory);
    end;

    [Test]
    [HandlerFunctions('QuantityExplosionOfBOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityExplosionOfBOMReport()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Setup: Create Production Order Items Setup.
        Initialize();
        CreateProdOrderItemsSetup(Item);

        // Exercise: Generate the Quantity Explosion Of BOM report.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Quantity Explosion of BOM", true, false, Item);

        // Verify: Check Production BOM component details.
        SelectProdBOMComponents(ProductionBOMLine, Item."Production BOM No.");
        VerifyProdBOMComponents(ProductionBOMLine, ProductionBOMLine."Quantity per");
    end;

    [Test]
    [HandlerFunctions('RoutingSheetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RoutingSheetReport()
    var
        Item: Record Item;
    begin
        // Setup: Create Production Order Items Setup.
        Initialize();
        CreateProdOrderItemsSetup(Item);

        // Exercise: Generate the Routing Sheet report.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Routing Sheet", true, false, Item);

        // Verify: Check Routing details.
        LibraryReportDataset.LoadDataSetFile();
        VerifyRoutingLine(Item."Routing No.", 'No_RtngLine');
    end;

    [Test]
    [HandlerFunctions('WorkMachineCenterLoadRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WorkMachineCenterLoadReport()
    var
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        WorkCenterGroup: Record "Work Center Group";
        PeriodLength: DateFormula;
    begin
        // Setup: Create Production Order Setup.
        Initialize();
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);

        // Exercise: Generate the Work/Machine Center Load report.
        Commit();
        RoutingLine.SetRange("Routing No.", ProductionOrder."Routing No.");
        RoutingLine.FindFirst();
        WorkCenter.SetRange("No.", RoutingLine."Work Center No.");
        WorkCenter.FindFirst();
        WorkCenterGroup.SetRange(Code, WorkCenter."Work Center Group Code");
        Evaluate(PeriodLength, StrSubstNo('<%1D>', LibraryRandom.RandInt(5)));
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(LibraryRandom.RandInt(5));
        LibraryVariableStorage.Enqueue(PeriodLength);
        LibraryVariableStorage.Enqueue(0);
        Report.Run(Report::"Work/Machine Center Load", true, false, WorkCenterGroup);

        // Verify: Check Work Center details.
        LibraryReportDataset.LoadDataSetFile();
        VerifyLoadReport(ProductionOrder."Routing No.", 'WorkCenterNo', RoutingLine.Type::"Work Center");

        // Verify: Check Machine Center details.
        VerifyLoadReport(ProductionOrder."Routing No.", 'MachineCenterNo', RoutingLine.Type::"Machine Center");
    end;

    [Test]
    [HandlerFunctions('QuantityExplosionOfBOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ComponentsOnQuantityExplosionOfBomReport()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ParentItem: Record Item;
        SecondChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProdBomNoWithLineTypeProductionBom: Code[20];
    begin
        // Run the Quantity Explosion of BOM Report. Verify Components.

        // Setup: Create Certified Production Bom for another Production Bom and Assign Second Production Bom to ParentItem.
        Initialize();
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, LibraryInventory.CreateItem(ChildItem),
          LibraryRandom.RandInt(10));
        ProdBomNoWithLineTypeProductionBom := CreateCertifiedProductionBomWithType(ProductionBOMHeader."No.", '',
            ChildItem."Base Unit of Measure");
        CreateItem(
          ParentItem, ParentItem."Costing Method"::FIFO, '',
          CreateCertifiedProductionBomWithType(ProdBomNoWithLineTypeProductionBom, LibraryInventory.CreateItem(SecondChildItem),
            SecondChildItem."Base Unit of Measure"), ParentItem."Manufacturing Policy"::"Make-to-Stock");

        // Exercise: Run and Save Quantity Explosion Of Bom Report.
        Commit();
        Item.SetRange("No.", ParentItem."No.");
        REPORT.Run(REPORT::"Quantity Explosion of BOM", true, false, Item);

        // Verify: Verify Child Item No. and Production Bom No. on Generated report.
        VerifyComponentsOnGeneratedReport(ParentItem."No.", SecondChildItem."No.");
    end;

    [Test]
    [HandlerFunctions('QuantityExplosionOfBOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityExplosionOfBOMReportWithUnCertifiedBOMVersion()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMNo: Code[20];
    begin
        // Setup: Create Production Order Items Setup. Create two BOM Versions without Certification and update Quantity Per.
        // Exercise: Run Quantity Explosion Of BOM report.
        ProductionBOMNo :=
          InitSetupForQuantityExplosionOfBOMReport(ProductionBOMHeader.Status::New, LibraryRandom.RandInt(10));

        // Verify: Verify Production BOM component details of Quantity Explosion Of BOM report.
        // Quantity Per should be ProductionBOMLine."Quantity per" when no BOM version certified.
        SelectProdBOMComponents(ProductionBOMLine, ProductionBOMNo);
        VerifyProdBOMComponents(ProductionBOMLine, ProductionBOMLine."Quantity per");
    end;

    [Test]
    [HandlerFunctions('QuantityExplosionOfBOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityExplosionOfBOMReportWithCertifiedBOMVersion()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMNo: Code[20];
        QtyPer: Decimal;
    begin
        // Setup: Create Production Order Items Setup. Create two BOM Versions and Certified one of them. Update Quantity Per.
        // Exercise: Run Quantity Explosion Of BOM report.
        QtyPer := LibraryRandom.RandInt(10);
        ProductionBOMNo := InitSetupForQuantityExplosionOfBOMReport(ProductionBOMHeader.Status::Certified, QtyPer);

        // Verify: Verify Production BOM component details of Quantity Explosion Of BOM report.
        // Quantity Per should be certified BOM Version's Quantity Per.
        SelectProdBOMComponents(ProductionBOMLine, ProductionBOMNo);
        VerifyProdBOMComponents(ProductionBOMLine, QtyPer);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ProdOrderShortageListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderShortageListWithMaketoOrderChilditem()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        ChildItem: Record Item;
    begin
        // Verify Make-to-Order child item is not shown on Shortage List report
        Initialize();

        CreateProdOrderItemsSetup(Item);
        FindChildItem(ChildItem, Item."Production BOM No.");
        SetItemMakeToOrder(ChildItem);
        CreateSalesOrder(ChildItem);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.");

        asserterror ProdOrderShortageListReport(ProductionOrder.Status, ProductionOrder."No.");
        Assert.ExpectedError(StrSubstNo(ElementNotFoundErr, ChildItem."No."));
    end;

    [Test]
    [HandlerFunctions('ProdOrderShortageListRequestPageHandler')]
    procedure NonInventoryItemsNotShownInProdOrderShortageListReport()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        NonInvtCompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Non-Inventory Item] [Prod. Order - Shortage List]
        // [SCENARIO 398308] Non-inventory items are not shown in Prod. Order - Shortage List report.
        Initialize();

        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvtCompItem);

        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, CompItem."No.", NonInvtCompItem."No.", 1);

        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, ProdItem."No.");

        ProductionOrder.SetRecFilter();
        REPORT.Run(REPORT::"Prod. Order - Shortage List", true, false, ProductionOrder);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ItemNo_ProdOrderComp', CompItem."No.");
        LibraryReportDataset.AssertElementTagWithValueNotExist('ItemNo_ProdOrderComp', NonInvtCompItem."No.");
    end;

    [Test]
    [HandlerFunctions('CapacityTaskListEmptyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CapacityTaskListStartEndTimeFormattedValue()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        RequestPageXML: Text;
    begin
        // [SCENARIO 434203] Report 'Capacity Task List' should display Starting Time/Ending Time correctly
        Initialize();

        // [GIVEN] Production Order and related Prod. Order Routing Line
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);

        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Work Center");
        ProdOrderRoutingLine.FindFirst();

        // [WHEN] Run Report 'Capacity Task List' 
        RequestPageXML := Report.RunRequestPage(Report::"Capacity Task List", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Capacity Task List", ProdOrderRoutingLine, RequestPageXML);

        // [THEN] 'Starting Time'/'Ending Time' = formatted value of Prod. Order Routing Line."Starting Time"/"Ending Time"
        LibraryReportDataset.AssertElementWithValueExists('StrtTm_ProdOrderRtngLine', Format(ProdOrderRoutingLine."Starting Time"));
        LibraryReportDataset.AssertElementWithValueExists('EndTime_ProdOrderRtngLine', Format(ProdOrderRoutingLine."Ending Time"));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Manufacturing Reports");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Manufacturing Reports");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        ItemJournalSetup();

        LibrarySetupStorage.SaveGeneralLedgerSetup();

        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Manufacturing Reports");
    end;

    local procedure InitSetupForQuantityExplosionOfBOMReport(Status: Enum "BOM Status"; QtyPer: Decimal): Code[20]
    var
        Item: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Production Order Items Setup. Create two BOM Versions and update Quantity Per.
        Initialize();
        CreateProdOrderItemsSetup(Item);
        CreateProdBOMVersion(ProductionBOMVersion, Item, Status, QtyPer);
        CreateProdBOMVersion(ProductionBOMVersion, Item, ProductionBOMHeader.Status::New, LibraryRandom.RandInt(5));

        // Run Quantity Explosion Of BOM report.
        Commit();
        REPORT.Run(REPORT::"Quantity Explosion of BOM", true, false, Item);

        exit(Item."Production BOM No.");
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure ClearJournal(ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
    end;

    local procedure ConsumptionJournalSetup(var ItemJournalBatch2: Record "Item Journal Batch")
    var
        ItemJournalTemplate2: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate2, ItemJournalTemplate2.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch2, ItemJournalTemplate2.Type, ItemJournalTemplate2.Name);
    end;

    local procedure CreateProductionOrderSetup(var ProductionOrder: Record "Production Order"; ProductionOrderStatus: Enum "Production Order Status")
    var
        Item: Record Item;
    begin
        // Create Parent and Child Items.
        CreateProdOrderItemsSetup(Item);

        // Create and Refresh Production Order.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrderStatus, Item."No.");
    end;

    local procedure CreateProdOrderItemsSetup(var Item: Record Item)
    var
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItemNo: Code[20];
        ChildItemNo2: Code[20];
    begin
        // Create Child Items.
        ClearJournal(ItemJournalBatch);
        ChildItemNo := CreateChildItemWithInventory();
        ChildItemNo2 := CreateChildItemWithInventory();

        // Create Production BOM.
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ChildItemNo, ChildItemNo2, 100);  // Quantity per Value important.

        // Create Parent Item and attach Routing and Production BOM.
        CreateRoutingSetup(RoutingHeader);
        CreateItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", ProductionBOMHeader."No.", Item."Manufacturing Policy"::"Make-to-Order");
    end;

    local procedure CreateProdBOMVersion(var ProductionBOMVersion: Record "Production BOM Version"; Item: Record Item; Status: enum "BOM Status"; QtyPer: Decimal)
    begin
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, Item."Production BOM No.", LibraryUtility.GenerateGUID(), Item."Base Unit of Measure");
        UpdateProdBOMVersionLine(Item."Production BOM No.", ProductionBOMVersion."Version Code", QtyPer);
        ProductionBOMVersion.Validate(Status, Status);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; ItemManufacturingPolicy: Enum "Manufacturing Policy")
    begin
        // Random value unimportant for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, CostingMethod, LibraryRandom.RandDec(50, 2), Item."Reordering Policy",
          Item."Flushing Method", RoutingNo, ProductionBOMNo);
        Item.Validate("Manufacturing Policy", ItemManufacturingPolicy);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
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
        WorkCenter.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        WorkCenter.Modify(true);
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

    local procedure CreateCertifiedProductionBomWithType(ProductionBomHeaderNo: Code[20]; ItemNo: Code[20]; UnitOfMeasure: Code[10]): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '',
          ProductionBOMLine.Type::"Production BOM", ProductionBomHeaderNo, LibraryRandom.RandInt(10));
        if ItemNo <> '' then
            LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '',
              ProductionBOMLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure FinishProductionOrder(ProdOrderNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(MissingQst);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrderNo);
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
        CreateItem(Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Stock");

        // Create Item Journal to populate Item Quantity.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(Item."No.");
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; ProductionOrderStatus: Enum "Production Order Status"; ItemNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrderStatus, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandInt(5));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateSalesOrder(Item: Record Item)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesOrder(
          SalesHeader, SalesLine, Item, '', '', LibraryRandom.RandDec(1000, 2),
          WorkDate(), LibraryRandom.RandDec(1000, 2));
        SalesLine.Validate("Shipment Date", CalcDate('<-1D>', WorkDate()));
        SalesLine.Modify();
    end;

    local procedure SelectProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; No: Code[20])
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("No.", No);
    end;

    local procedure SelectProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20]; ProductionOrderStatus: Enum "Production Order Status")
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrderStatus);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindSet();
    end;

    local procedure SelectRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20])
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindSet();
    end;

    local procedure SelectProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderNo: Code[20]; Status: Enum "Production Order Status")
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindSet();
    end;

#if not CLEAN27
    local procedure UpdateProductionForecastQty(var ProductionForecastEntry: Record "Production Forecast Entry")
    begin
        ProductionForecastEntry.Validate("Forecast Quantity", LibraryRandom.RandDec(10, 2));
        ProductionForecastEntry.Modify(true);
    end;
#endif

    local procedure SelectConsumptionLines(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch2: Record "Item Journal Batch")
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch2."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch2.Name);
        ItemJournalLine.FindSet();
    end;

    local procedure ProdCapacityTaskListReport(var ProductionOrder: Record "Production Order"; ProdOrderRoutingLineType: Enum "Capacity Type")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Create Production Order Setup.
        CreateProductionOrderSetup(ProductionOrder, ProductionOrder.Status::Released);  // Create Production Order.

        // Exercise: Generate the Capacity Task List report.
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLineType);
        REPORT.Run(REPORT::"Capacity Task List", true, false, ProdOrderRoutingLine);
    end;

    local procedure CreateBOMComponentSetup(var BOMComponent: Record "BOM Component")
    var
        Item: Record Item;
        Item2: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item, Item2."No.", 1, '');
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', LibraryRandom.RandDec(100, 2), WorkDate(),
          LibraryRandom.RandDec(100, 2));
        LibraryInventory.PostPositiveAdjustment(Item2, '', '', '', LibraryRandom.RandDec(100, 2), WorkDate(),
          LibraryRandom.RandDec(100, 2));
    end;

    local procedure ClearRouting(var Item: Record Item)
    begin
        Item.Validate("Routing No.", '');
        Item.Modify(true);
    end;

    local procedure CreateFamily(var Family: Record Family; RoutingNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        FamilyLine: Record "Family Line";
    begin
        // Random values not important for test.
        LibraryManufacturing.CreateFamily(Family);
        Family.Validate("Routing No.", RoutingNo);
        Family.Modify(true);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo, LibraryRandom.RandDec(5, 2));
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo2, LibraryRandom.RandDec(5, 2));
    end;

    local procedure SelectProdBOMComponents(var ProductionBOMLine: Record "Production BOM Line"; ProdBOMNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProdBOMNo);
        ProductionBOMLine.FindSet();
    end;

    local procedure UpdateProdBOMVersionLine(ProductionBOMNo: Code[20]; VersionCode: Code[20]; QtyPer: Decimal)
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        ProdBOMHeader.Get(ProductionBOMNo);
        ProductionBOMCopy.CopyBOM(ProductionBOMNo, '', ProdBOMHeader, VersionCode);
        ProductionBOMVersion.Get(ProductionBOMNo, VersionCode);
        ProductionBOMVersion.Validate("Unit of Measure Code", ProdBOMHeader."Unit of Measure Code");
        ProductionBOMVersion.Modify(true);
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        ProductionBOMLine.FindSet();
        repeat
            ProductionBOMLine.Validate("Quantity per", QtyPer);
            ProductionBOMLine.Modify(true);
        until ProductionBOMLine.Next() = 0;
    end;

    local procedure FindChildItem(var ChildItem: Record Item; ProductionBOMNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindFirst();
        ChildItem.Get(ProductionBOMLine."No.");
    end;

    local procedure SetItemMakeToOrder(var Item: Record Item)
    begin
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Modify();
    end;

    local procedure VerifyComponentsOnGeneratedReport(ParentItemNo: Code[20]; ChildItemNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('BomCompLevelNo', ChildItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('No_Item', ParentItemNo);
    end;

    local procedure VerifyProductionOrder(ProductionOrder: Record "Production Order"; ProdOrderNoElementName: Text; ProdOrderSourceNoElementName: Text)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ProdOrderNoElementName, ProductionOrder."No.");
        LibraryReportDataset.AssertElementWithValueExists(ProdOrderSourceNoElementName, ProductionOrder."Source No.");
    end;

    local procedure VerifyProdOrderComponent(ProductionOrderNo: Code[20]; ProductionOrderStatus: Enum "Production Order Status"; ElementName: Text)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        SelectProdOrderComponent(ProdOrderComponent, ProductionOrderNo, ProductionOrderStatus);
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange(ElementName, ProdOrderComponent."Item No.");
            Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'Element not found for ' + ProdOrderComponent."Item No.");
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure VerifyRoutingLine(ProductionOrderRoutingNo: Code[20]; ElementName: Text)
    var
        RoutingLine: Record "Routing Line";
    begin
        SelectRoutingLine(RoutingLine, ProductionOrderRoutingNo);
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange(ElementName, RoutingLine."No.");
            Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'Element not found for ' + RoutingLine."No.");
        until RoutingLine.Next() = 0;
    end;

    local procedure VerifyLoadReport(ProductionOrderRoutingNo: Code[20]; ElementName: Text; RoutingLineType: Enum "Capacity Type Routing")
    var
        RoutingLine: Record "Routing Line";
    begin
        SelectRoutingLine(RoutingLine, ProductionOrderRoutingNo);
        RoutingLine.SetRange(Type, RoutingLineType);
        RoutingLine.FindSet();
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange(ElementName, RoutingLine."No.");
            Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'Element not found for ' + RoutingLine."No.");
        until RoutingLine.Next() = 0;

        RoutingLine.SetFilter(Type, '<>%1', RoutingLineType);
        RoutingLine.FindSet();
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange(ElementName, RoutingLine."No.");
            Assert.IsFalse(LibraryReportDataset.GetNextRow(), 'Element found for ' + RoutingLine."No.");
        until RoutingLine.Next() = 0;
    end;

    local procedure VerifyConsumptionJrnlItems(ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20]; ProductionOrderStatus: Enum "Production Order Status")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        SelectProdOrderComponent(ProdOrderComponent, ProductionOrderNo, ProductionOrderStatus);
        repeat
            ItemJournalLine.SetRange("Item No.", ProdOrderComponent."Item No.");
            Assert.IsTrue(ItemJournalLine.Count > 0, RecordErr);
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure VerifyBOMItems(BOMComponent: Record "BOM Component"; BOMComponentElementNo: Text; ParentItemElementNo: Text)
    begin
        VerifyBOMItem(BOMComponent."Parent Item No.", ParentItemElementNo);
        LibraryReportDataset.AssertCurrentRowValueEquals(BOMComponentElementNo, BOMComponent."No.");
    end;

    local procedure VerifyBOMItem(ItemNo: Code[20]; ItemElementNo: Text)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(ItemElementNo, ItemNo);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'Item not found in report.');
    end;

    local procedure VerifyProdBOMComponents(var ProductionBOMLine: Record "Production BOM Line"; QtyPer: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        repeat
            LibraryReportDataset.SetRange('BomCompLevelNo', ProductionBOMLine."No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('BomCompLevelQty', QtyPer);
        until ProductionBOMLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyCapacityTaskList(ProductionOrder: Record "Production Order"; RoutingLineType: Enum "Capacity Type")
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        RoutingLine.SetRange("Routing No.", ProductionOrder."Routing No.");
        RoutingLine.SetRange(Type, RoutingLineType);
        RoutingLine.FindSet();
        repeat
            LibraryReportDataset.Reset();
            LibraryReportDataset.SetRange('OPNo_ProdOrderRtngLine', RoutingLine."Operation No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('PONo_ProdOrderRtngLine', ProductionOrder."No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('RtngNo_ProdOrderRtngLine', ProductionOrder."Routing No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('No_ProdOrderRtngLine', RoutingLine."No.");
        until RoutingLine.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure QuantityExplosionOfBOMRequestPageHandler(var QuantityExplosionOfBOM: TestRequestPage "Quantity Explosion of BOM")
    begin
        QuantityExplosionOfBOM.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderCompAndRoutingRequestPageHandler(var ProdOrderCompAndRouting: TestRequestPage "Prod. Order Comp. and Routing")
    begin
        ProdOrderCompAndRouting.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderJobCardRequestPageHandler(var ProdOrderJobCard: TestRequestPage "Prod. Order - Job Card")
    begin
        ProdOrderJobCard.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderPrecalcTimeRequestPageHandler(var ProdOrderPrecalcTime: TestRequestPage "Prod. Order - Precalc. Time")
    begin
        ProdOrderPrecalcTime.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListRequestPageHandler(var ProdOrderShortageList: TestRequestPage "Prod. Order - Shortage List")
    begin
        ProdOrderShortageList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderMatRequisitionRequestPageHandler(var ProdOrderMatRequisition: TestRequestPage "Prod. Order - Mat. Requisition")
    begin
        ProdOrderMatRequisition.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderPickingListRequestPageHandler(var ProdOrderPickingList: TestRequestPage "Prod. Order - Picking List")
    begin
        ProdOrderPickingList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderDetailedCalcRequestPageHandler(var ProdOrderDetailedCalc: TestRequestPage "Prod. Order - Detailed Calc.")
    begin
        ProdOrderDetailedCalc.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderStatisticsRequestPageHandler(var ProdOrderStatistics: TestRequestPage "Production Order Statistics")
    begin
        ProdOrderStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
#if not CLEAN27
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProductionForecastRequestPageHandler(var ProductionForecast: TestRequestPage "Demand Forecast")
    begin
        ProductionForecast.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
#endif

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyBOMsRequestPageHandler(var AssemblyBOMs: TestRequestPage "Assembly BOMs")
    begin
        AssemblyBOMs.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedListRequestPageHandler(var WhereUsedList: TestRequestPage "Where-Used List")
    begin
        WhereUsedList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyBOMRawMaterialsRequestPageHandler(var AssemblyBOMRawMaterials: TestRequestPage "Assembly BOM - Raw Materials")
    begin
        AssemblyBOMRawMaterials.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyBOMEndItemsRequestPageHandler(var AssemblyBOMEndItems: TestRequestPage "Assembly BOM - End Items")
    begin
        AssemblyBOMEndItems.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyBOMSubassembliesRequestPageHandler(var AssemblyBOMSubassemblies: TestRequestPage "Assembly BOM - Subassemblies")
    begin
        AssemblyBOMSubassemblies.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RoutingSheetRequestPageHandler(var RoutingSheet: TestRequestPage "Routing Sheet")
    begin
        RoutingSheet.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WorkMachineCenterLoadRequestPageHandler(var WorkMachineCenterLoad: TestRequestPage "Work/Machine Center Load")
    var
        StartingDate: Variant;
        NoOfPeriods: Variant;
        PeriodLength: Variant;
        MinCapEfficToPrint: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(NoOfPeriods);
        LibraryVariableStorage.Dequeue(PeriodLength);
        LibraryVariableStorage.Dequeue(MinCapEfficToPrint);

        WorkMachineCenterLoad.StartingDate.SetValue(StartingDate);
        WorkMachineCenterLoad.NoOfPeriods.SetValue(NoOfPeriods);
        WorkMachineCenterLoad.PeriodLength.SetValue(PeriodLength);
        WorkMachineCenterLoad.MinCapEfficToPrint.SetValue(MinCapEfficToPrint);
        WorkMachineCenterLoad.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CapacityTaskListRequestPageHandler(var CapacityTaskList: TestRequestPage "Capacity Task List")
    begin
        CapacityTaskList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CapacityTaskListEmptyRequestPageHandler(var CapacityTaskList: TestRequestPage "Capacity Task List")
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}