// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Manufacturing.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Purchases.Document;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Journal;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Foundation.NoSeries;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Inventory.Costing;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Vendor;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.History;

codeunit 137004 "SCM WIP Costing Production-II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Post Inventory to G/L] [SCM]
        isInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        NotFoundZeroAmtErr: Label 'The sum of amounts must be zero.';
        AmountDoNotMatchErr: Label 'The WIP amount totals must be equal.';
        DummyFlushingMethod: Enum "Flushing Method";

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdSubconMan()
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Test Standard Costing of Subcontracting Order with Flushing method - Manual.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Manual, "Flushing Method"::Manual, "Costing Method"::Standard,
            "Production Order Status"::Released, true, false, false, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdManualCostDiff()
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Test Standard Costing of Flushing method - Manual Cost different from Expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Units, "Flushing Method"::Manual, DummyFlushingMethod, "Costing Method"::Standard,
            "Production Order Status"::Released, false, false, false, false, true, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdSubconManCostDiff()
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Test Standard Costing of Subcontracting Order with Flushing method - Manual. Subcontract and Output Cost different from Expected.
        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Units, "Flushing Method"::Manual, "Flushing Method"::Manual, "Costing Method"::Standard,
            "Production Order Status"::Released, true, false, false, true, true, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdSubconBackward()
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Test Standard Costing of Subcontracting Order with Flushing method - Backward and of Subcontract Work center as Manual.
        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Backward, "Flushing Method"::Manual, "Costing Method"::Standard,
            "Production Order Status"::Released, true, false, false, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdForwardProdOrderComp()
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Test Standard Costing with Flushing method Forward for Planned Production Order.Replace Production Component.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Units, "Flushing Method"::Forward, DummyFlushingMethod, "Costing Method"::Standard,
            "Production Order Status"::Planned, false, true, false, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgSubconBackward()
    begin
        // [FEATURE] [Cost Average]
        // [SCENARIO] Test Average Costing of Subcontracting Order with Flushing method - Backward and of Subcontract Work center as Manual.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Backward, "Flushing Method"::Manual, "Costing Method"::Average,
            "Production Order Status"::Released, true, false, false, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgSubconManCostDiff()
    begin
        // [FEATURE] [Cost Average]
        // [SCENARIO] Test Average Costing of Subcontracting Order with Flushing method - Manual. Subcontract and Output Cost different from Expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Units, "Flushing Method"::Manual, "Flushing Method"::Backward, "Costing Method"::Average,
            "Production Order Status"::Released, false, false, false, true, true, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdSubconManCostDiffAddCurr()
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Test Standard Costing for Additional Currency of Subcontracting Order with Flushing method - Manual. Subcontract and Output Cost different from Expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Units, "Flushing Method"::Manual, "Flushing Method"::Manual, "Costing Method"::Standard,
            "Production Order Status"::Released, true, false, true, true, true, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StdSubconBackwardAddCurr()
    begin
        // [FEATURE] [Cost Standard]
        // [SCENARIO] Test Standard Costing for Additional Currency of Subcontracting Order with Flushing method - Backward and of Subcontract Work center as Manual.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Backward, "Flushing Method"::Manual, "Costing Method"::Standard,
            "Production Order Status"::Released, true, false, true, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOForward()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing of Flushing method - Forward.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Forward, DummyFlushingMethod, "Costing Method"::FIFO,
            "Production Order Status"::Planned, false, false, false, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOManCapCostDiff()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing of Flushing method - Manual, Cost, consumption Run Time and Setup Time is  different from Expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Manual, DummyFlushingMethod, "Costing Method"::FIFO,
            "Production Order Status"::Released, false, false, false, false, true, true, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOForwardProductionComponent()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing with Flushing method Forward, replacing production order component.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Forward, DummyFlushingMethod, "Costing Method"::FIFO,
            "Production Order Status"::Planned, false, true, false, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOSubconBackward()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing of Subcontracting Order with Flushing method - Backward and of Subcontract Work center as Manual.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Backward, "Flushing Method"::Manual, "Costing Method"::FIFO,
            "Production Order Status"::Released, true, false, false, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOSubconManCostDiff()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing of Subcontracting Order with Flushing method - Manual. Output Cost and Subcontract Cost are different from expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Manual, "Flushing Method"::Manual, "Costing Method"::FIFO,
            "Production Order Status"::Released, true, false, false, true, true, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgForwardAddCurr()
    begin
        // [FEATURE] [Cost Average]
        // [SCENARIO] Test Average Costing for Additional Currency of Flushing method - Forward.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Forward, DummyFlushingMethod, "Costing Method"::Average,
            "Production Order Status"::Planned, false, false, true, false, false, false, false, false, false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManCapCostDiffAddCurr()
    begin
        // [FEATURE] [Cost Average]
        // [SCENARIO] Test Average Costing for Additional Currency of Flushing method - Manual. Output cost, consumption Cost, Run Time and Setup Time is  different from Expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Manual, DummyFlushingMethod, "Costing Method"::Average,
            "Production Order Status"::Released, false, false, true, false, true, true, false, true, false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgForwardProdOrderCompAddCurr()
    begin
        // [FEATURE] [Cost Average]
        // [SCENARIO] Test Average Costing for Additional Currency Of Flushing method Forward for Planned Production Order. Delete one Production Component.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Units, "Flushing Method"::Forward, DummyFlushingMethod, "Costing Method"::Average,
            "Production Order Status"::Planned, false, true, true, false, false, false, false, false, false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgManualRoutingDiffAddCurr()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test Average Costing for Additional Currency of Flushing method - Manual. Update Production order routing.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Manual, DummyFlushingMethod, "Costing Method"::FIFO,
            "Production Order Status"::Released, false, false, true, false, false, false, false, false, true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgSubconBackwardAddCurr()
    begin
        // [FEATURE] [Cost Average]
        // [SCENARIO] Test Average Costing for Additional Currency of Subcontracting Order with Flushing method - Backward. Subcontract Work center as Manual.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Backward, "Flushing Method"::Manual, "Costing Method"::Average,
            "Production Order Status"::Released, true, false, true, false, false, false, false, false, false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AvgSubconManCostDiffAddCurr()
    begin
        // [FEATURE] [Cost Average]
        // [SCENARIO] Test Average Costing for Additional Currency of Subcontracting Order with Flushing method - Manual. Subcontract Work center as Backward.Subcontract and Output Cost different from Expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Units, "Flushing Method"::Manual, "Flushing Method"::Backward, "Costing Method"::Average,
            "Production Order Status"::Released, false, false, true, true, true, false, false, false, false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOManCapConsCostDiffAddCurr()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test Average Costing for Additional Currency of Flushing method - Manual. Output cost, consumption Cost, Run Time and Setup Time is  different from Expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Manual, DummyFlushingMethod, "Costing Method"::FIFO,
            "Production Order Status"::Released, false, false, true, false, true, true, false, true, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOSubconBackCostDiffAddCurr()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test Average Costing for Additional Currency of Subcontracting Order with Flushing method - Manual. Subcontract Work center as Backward.Subcontract and Output Cost different from Expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Units, "Flushing Method"::Manual, "Flushing Method"::Backward, "Costing Method"::FIFO,
            "Production Order Status"::Released, false, false, true, true, true, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOForwardAddCurr()
    begin
        // [FEATURE] [FIFO] [ACY]
        // [SCENARIO] Test FIFO Costing of Flushing method - Forward.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Forward, DummyFlushingMethod, "Costing Method"::FIFO,
            "Production Order Status"::Planned, false, false, true, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOManCapCostDiffAddCurr()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing Flushing method - Manual, Cost, consumption Run Time and Setup Time different from Expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Manual, DummyFlushingMethod, "Costing Method"::FIFO,
            "Production Order Status"::Released, false, false, true, false, true, true, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOForwardNewComponentAddCurr()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing Flushing method - Forward, replace old Production component with a new one.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Forward, DummyFlushingMethod, "Costing Method"::FIFO,
            "Production Order Status"::Planned, false, true, true, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOSubconBackwardAddCurr()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing : Subcontracting Order with Flushing method - Backward and Subcontract Work center - Manual.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Backward, "Flushing Method"::Manual, "Costing Method"::FIFO,
            "Production Order Status"::Released, true, false, true, false, false, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FIFOSubconManCostDiffAddCurr()
    begin
        // [FEATURE] [FIFO]
        // [SCENARIO] Test FIFO Costing : Subcontracting Order with Flushing method - Manual. Output Cost and Subcontract Cost are different from expected.

        SCMWIPCostingProductionII(
            Enum::"Unit Cost Calculation Type"::Time, "Flushing Method"::Manual, "Flushing Method"::Manual, "Costing Method"::FIFO,
            "Production Order Status"::Released, true, false, true, true, true, false, false, false, false, false);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure StandardCostItemRoundingCost()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Rounding]
        // [SCENARIO 377973] Rounding error should be added to total output cost for an item with Standard costing method

        Initialize();

        // [GIVEN] Component item "I1" with FIFO costing method
        CreateItemNoIndirectCost(ChildItem, ChildItem."Costing Method"::FIFO, 1, '', '', ChildItem."Replenishment System"::Purchase);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", 0.138);
        // [GIVEN] Work center "W", unit cost = 1.49967
        CreateWorkCenterWithCalendar(WorkCenter, 1.49967);
        CreateCertifiedRouting(RoutingHeader, WorkCenter."No.", 1);

        // [GIVEN] Manufactured item "I2" with standard costing method, "I1" as a component and a routing including work center "W"
        CreateItemNoIndirectCost(
          ParentItem, ParentItem."Costing Method"::Standard, 0.01, RoutingHeader."No.",
          ProductionBOMHeader."No.", ParentItem."Replenishment System"::"Prod. Order");
        CalcItemStandardCost(ParentItem."No.");

        // [GIVEN] Create purchase order: Item = "I1", Quantity = 69.24441, Unit cost = 5.66933
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ChildItem."No.", 69.24441);
        UpdateUnitCostInPurchaseLine(PurchaseLine, 5.66933);

        // [GIVEN] Post purchase receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Released production order for item "I2", quantity = 500
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItem."No.", 500);

        // [GIVEN] Post production order output, output quantity = 250, run time = 15.17
        PostProdOrderOutput(ProductionOrder, 250, 15.17);
        // [GIVEN] Post production order output, output quantity = 250, run time = 106.22
        PostProdOrderOutput(ProductionOrder, 250, 106.22);
        // [GIVEN] Post consumption from production order: consume full stock of item "I1" of 69.24441 pcs
        PostConsumptionFromProdOrder(ChildItem."No.", ProductionOrder."No.", 69.24441);

        // [GIVEN] Finish production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        // [GIVEN] Run Adjust Cost - Item Entries
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ChildItem."No.", ParentItem."No."), '');

        // [GIVEN] Update unit cost in production order line. New cost = 22.67760
        PurchaseLine.Find();
        UpdateUnitCostInPurchaseLine(PurchaseLine, 22.6776);

        // [GIVEN] Post purchase invoice
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Run Adjust Cost - Item Entries
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', ChildItem."No.", ParentItem."No."), '');

        // [THEN] Cost of work in process is 0
        Assert.AreEqual(0, CalcProdOrderWIPAmount(ProductionOrder."No."), NotFoundZeroAmtErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostItemProducedAndConsumedInDifferentProdOrderLines()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        ValueEntry: Record "Value Entry";
        Qty: Integer;
    begin
        // [FEATURE] [Production] [Valuation Date]
        // [SCENARIO 235270] Cost adjustment should not change valuation date for production output entries when output precedes consumption for another line of the same order

        Initialize();

        // [GIVEN] Item "I" with "Average" costing method
        CreateItemWithCostingMethod(Item, Item."Costing Method"::Average);

        Qty := PostRandomItemStock(Item."No.", 0);

        // [GIVEN] Post stock of item "I" and consume it in a production order "P" on 10.10.2020
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine[1], ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', '', Qty);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine[2], ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', '', Qty);

        // [GIVEN] Post output of the same item "I" in the production order "I" on 05.01.2020
        PostOutput(ProductionOrder."No.", ProdOrderLine[1]."Line No.", WorkDate(), Item."No.", Qty);
        PostConsumption(ProductionOrder."No.", ProdOrderLine[2]."Line No.", WorkDate() + 1, Item."No.", Qty);
        PostOutput(ProductionOrder."No.", ProdOrderLine[2]."Line No.", WorkDate() + 1, Item."No.", Qty);

        // [GIVEN] Change status of the production order to "Finished"
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [WHEN] Run "Adjust Cost - Item Entries"
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Valuation date of the consumption entry is 10.10.2020
        VerifyValueEntryValuationDate(
          ProdOrderLine[2], Item."No.", ValueEntry."Item Ledger Entry Type"::Consumption, WorkDate() + 1, WorkDate() + 1);

        // [THEN] Valuation date of the output entry is 05.10.2020
        VerifyValueEntryValuationDate(ProdOrderLine[1], Item."No.", ValueEntry."Item Ledger Entry Type"::Output, WorkDate(), WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostConusmptionAfterOutputUpdatesValuationDate()
    var
        Item: array[2] of Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ValueEntry: Record "Value Entry";
        Qty: Integer;
    begin
        // [FEATURE] [Production] [Valuation Date]
        // [SCENARIO 235270] Posting a consumption entry with valuation date later than the date of an existing output for the same production order should update valuation date of the output

        Initialize();

        // [GIVEN] Produced item "PI" and a component "CI"
        CreateItemWithCostingMethod(Item[1], Item[1]."Costing Method"::Average);
        CreateItemWithCostingMethod(Item[2], Item[2]."Costing Method"::Average);

        // [GIVEN] Production order with the item "PI" as a source
        Qty := PostRandomItemStock(Item[1]."No.", 0);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item[2]."No.", Qty);
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Post output of the item "PI" on 05.01.2020
        PostOutput(ProductionOrder."No.", ProdOrderLine."Line No.", WorkDate(), Item[2]."No.", Qty);

        // [WHEN] Post consumption of the component "CI" on 10.01.2020
        PostConsumption(ProductionOrder."No.", ProdOrderLine."Line No.", WorkDate() + 1, Item[1]."No.", Qty);

        // [THEN] Valuation date of the output is updated to match the date of the consumption. Both entries have valuation date = 10.01.2020
        VerifyValueEntryValuationDate(
          ProdOrderLine, Item[1]."No.", ValueEntry."Item Ledger Entry Type"::Consumption, WorkDate() + 1, WorkDate() + 1);
        VerifyValueEntryValuationDate(ProdOrderLine, Item[2]."No.", ValueEntry."Item Ledger Entry Type"::Output, WorkDate(), WorkDate() + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputEarlierThanConsumptionValuationDateUpdated()
    var
        Item: array[2] of Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ValueEntry: Record "Value Entry";
        Qty: Integer;
    begin
        // [FEATURE] [Production] [Valuation Date]
        // [SCENARIO 235270] Output entry with valuation date preceding the date of an existing consumption for the same production order should be valued on the date of the consumption

        Initialize();

        // [GIVEN] Produced item "PI" and a component "CI"
        CreateItemWithCostingMethod(Item[1], Item[1]."Costing Method"::Average);
        CreateItemWithCostingMethod(Item[2], Item[2]."Costing Method"::Average);

        Qty := PostRandomItemStock(Item[1]."No.", 0);

        // [GIVEN] Production order with the item "PI" as a source
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item[2]."No.", Qty);
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Post consumption of the component "CI" on 10.01.2020
        PostConsumption(ProductionOrder."No.", ProdOrderLine."Line No.", WorkDate() + 1, Item[1]."No.", Qty);

        // [WHEN] Post output of the item "PI" on 05.01.2020
        PostOutput(ProductionOrder."No.", ProdOrderLine."Line No.", WorkDate(), Item[2]."No.", Qty);

        // [THEN] Output is posted with valuation date 10.01.2020
        VerifyValueEntryValuationDate(
          ProdOrderLine, Item[1]."No.", ValueEntry."Item Ledger Entry Type"::Consumption, WorkDate() + 1, WorkDate() + 1);
        VerifyValueEntryValuationDate(ProdOrderLine, Item[2]."No.", ValueEntry."Item Ledger Entry Type"::Output, WorkDate(), WorkDate() + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostConsumptionAfterOutputLaterOutputNotAffected()
    var
        Item: array[2] of Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ValueEntry: Record "Value Entry";
        Qty: Integer;
    begin
        // [FEATURE] [Production] [Valuation Date]
        // [SCENARIO 235270] Only output entries of a production order preceeding the latest consumption should be updated on posting

        Initialize();

        // [GIVEN] Produced item "PI" and a component "CI"
        CreateItemWithCostingMethod(Item[1], Item[1]."Costing Method"::Average);
        CreateItemWithCostingMethod(Item[2], Item[2]."Costing Method"::Average);

        Qty := PostRandomItemStock(Item[1]."No.", 0);

        // [GIVEN] Production order with the item "PI" as a source
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item[2]."No.", Qty);
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Post consumption of item "CI" on 01.01.2020
        PostConsumption(ProductionOrder."No.", ProdOrderLine."Line No.", WorkDate(), Item[1]."No.", Qty mod 2);
        // [GIVEN] Post output of item "CI" on 01.01.2020
        PostOutput(ProductionOrder."No.", ProdOrderLine."Line No.", WorkDate(), Item[2]."No.", 1);
        // [GIVEN] Post output of item "CI" on 02.01.2020
        PostOutput(ProductionOrder."No.", ProdOrderLine."Line No.", WorkDate() + 1, Item[2]."No.", 1);
        // [GIVEN] Post output of item "CI" on 04.01.2020
        PostOutput(ProductionOrder."No.", ProdOrderLine."Line No.", WorkDate() + 3, Item[2]."No.", 1);

        // [WHEN] Post consumption of item "CI" on 03.01.2020
        PostConsumption(ProductionOrder."No.", ProdOrderLine."Line No.", WorkDate() + 2, Item[1]."No.", Qty mod 2);

        // [THEN] Consumption entries are valued on the dates they were posted (01.01.2020 and 03.01.2020)
        VerifyValueEntryValuationDate(ProdOrderLine, Item[1]."No.", ValueEntry."Item Ledger Entry Type"::Consumption, WorkDate(), WorkDate());
        VerifyValueEntryValuationDate(
          ProdOrderLine, Item[1]."No.", ValueEntry."Item Ledger Entry Type"::Consumption, WorkDate() + 2, WorkDate() + 2);

        // [THEN] Output entries posted before the latest consumption (03.01.2020) are moved to match the consumption valuation date
        VerifyValueEntryValuationDate(ProdOrderLine, Item[2]."No.", ValueEntry."Item Ledger Entry Type"::Output, WorkDate(), WorkDate() + 2);
        VerifyValueEntryValuationDate(ProdOrderLine, Item[2]."No.", ValueEntry."Item Ledger Entry Type"::Output, WorkDate() + 1, WorkDate() + 2);

        // [THEN] Output entry posted after consumption (04.01.2020) has not changed
        VerifyValueEntryValuationDate(ProdOrderLine, Item[2]."No.", ValueEntry."Item Ledger Entry Type"::Output, WorkDate() + 3, WorkDate() + 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostProdOrderWithOutputPrecedingConsumptionForSameItem()
    var
        Item: array[3] of Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Production] [Valuation Date]
        // [SCENARIO 235270] Cost adjustment should adjust value entries for an item that is consumed and produced in the same prod. order, output preceding consumption

        Initialize();

        // [GIVEN] Component item "I1" with "FIFO" costing method, and two manufactured items "I2" and "I3" having "Average" costing method
        CreateItemWithCostingMethod(Item[1], Item[1]."Costing Method"::FIFO);
        CreateItemWithCostingMethod(Item[2], Item[2]."Costing Method"::Average);
        CreateItemWithCostingMethod(Item[3], Item[3]."Costing Method"::Average);

        // [GIVEN] Post stock of 10 pcs of item "I1" on 01.01.2020, unit cost = 2
        // [GIVEN] Post stock of 1 pc of item "I2" on 01.01.2020, unit cost = 15
        PostItemStock(Item[1]."No.", 10, 2);
        PostItemStock(Item[2]."No.", 1, 15);

        // [GIVEN] Production order "P" with two lines. First line produces item "I3", the second line - "I2"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item[2]."No.", 1);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine[1], ProductionOrder.Status, ProductionOrder."No.", Item[3]."No.", '', '', 1);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine[2], ProductionOrder.Status, ProductionOrder."No.", Item[2]."No.", '', '', 1);

        // [GIVEN] Post consumption: Prod. order line 1, Item "I2", quantity = 1, posting date 02.01.2020
        PostConsumption(ProductionOrder."No.", ProdOrderLine[1]."Line No.", WorkDate() + 1, Item[2]."No.", 1);

        // [GIVEN] Post output: Prod. order line 1, Item "I3", quantity = 1, posting date 03.01.2020
        PostOutput(ProductionOrder."No.", ProdOrderLine[1]."Line No.", WorkDate() + 2, Item[3]."No.", 1);

        // [GIVEN] Post consumption: Prod. order line 2, Item "I3", quantity = 1, posting date 04.01.2020
        PostConsumption(ProductionOrder."No.", ProdOrderLine[2]."Line No.", WorkDate() + 3, Item[3]."No.", 1);

        // [GIVEN] Post consumption: Prod. order line 2, Item "I1", quantity = 10, posting date 02.01.2020. This entry brings additional cost into production cycle.
        PostConsumption(ProductionOrder."No.", ProdOrderLine[2]."Line No.", WorkDate() + 1, Item[1]."No.", 10);

        // [GIVEN] Post output: Prod. order line 2, Item "I2", quantity = 1, posting date 01.01.2020
        PostOutput(ProductionOrder."No.", ProdOrderLine[2]."Line No.", WorkDate(), Item[2]."No.", 1);

        // [GIVEN] Change status of the production order to "Finished"
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [WHEN] Run "Adjust Cost - Item Entries"
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', Item[2]."No.", Item[3]."No."), '');

        // [THEN] Cost amount of the consumption of item "I2" on 02.01.2020 is -15
        VerifyItemLedgerEntry(Item[2]."No.", ItemLedgerEntry."Entry Type"::Consumption, WorkDate() + 1, -15);
        // [THEN] Cost amount of the output of item "I3" on 03.01.2020 is 15
        VerifyItemLedgerEntry(Item[3]."No.", ItemLedgerEntry."Entry Type"::Output, WorkDate() + 2, 15);
        // [THEN] Cost amount of the consumption of item "I3" on 04.01.2020 is -15
        VerifyItemLedgerEntry(Item[3]."No.", ItemLedgerEntry."Entry Type"::Consumption, WorkDate() + 3, -15);
        // [THEN] Cost amount of the output of item "I2" on 01.01.2020 is 35
        VerifyItemLedgerEntry(Item[2]."No.", ItemLedgerEntry."Entry Type"::Output, WorkDate(), 35);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM WIP Costing Production-II");
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM WIP Costing Production-II");

        SetUnitAmountRoundingPrecision();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM WIP Costing Production-II");
    end;

    local procedure SetUnitAmountRoundingPrecision()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Unit-Amount Rounding Precision" := 0.00001;
        GLSetup.Modify();
    end;

    [Normal]
    local procedure SCMWIPCostingProductionII(UnitCostCalcType: Enum "Unit Cost Calculation Type"; FlushingMethod: Enum "Flushing Method"; SubcontractFlushingMethod: Enum "Flushing Method"; CostingMethod: Enum "Costing Method"; ProductionOrderStatus: Enum "Production Order Status"; Subcontract: Boolean; UpdateProductionComponent: Boolean; AdditionalCurrencyExist: Boolean; SubcontractCostDiff: Boolean; OutputCostDiff: Boolean; RunSetupTimeCostDiff: Boolean; DeleteConsumptionJrnl: Boolean; ConsumptionCostDiff: Boolean; UpdateProdOrderRouting: Boolean; AdjustExchangeRatesGLSetup: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        InventorySetup: Record "Inventory Setup";
        ItemJournalBatch: Record "Item Journal Batch";
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        TempPurchaseLine: Record "Purchase Line" temporary;
        NoSeries: Codeunit "No. Series";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ShopCalendarCode: Code[10];
        ProductionBOMNo: Code[20];
        MachineCenterNo: Code[20];
        MachineCenterNo2: Code[20];
        MachineCenterNo3: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
        RoutingNo: Code[20];
        ParentItemNo: Code[20];
        ComponentItemNos: array[3] of Code[20];
        CurrencyCode: Code[10];
        ProductionOrderNo: Code[20];
        AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type";
        SetupTime: Decimal;
        RunTime: Decimal;
    begin
        // Steps describing the sequence of actions for Test Case.

        // 1. Create required WIP setups with Flushing method as Manual with Subcontract.
        // Update Manufacturing Setup, Inventory Setup and Update Shop Calendar Working Days based on Work Shift code.
        Initialize();
        RaiseConfirmHandler();
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, false, AutomaticCostAdjustment::Never, "Average Cost Calculation Type"::Item, "Average Cost Period Type"::Day);
        LibraryManufacturing.UpdateManufacturingSetup(ManufacturingSetup, '', '', true, true, true);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();
        if AdditionalCurrencyExist then
            CurrencyCode := UpdateAddnlReportingCurrency()
        else
            LibraryERM.SetAddReportingCurrency('');

        // Create Work Center and Machine Center with Flushing method -Manual.
        // Create Work Center for Subcontractor with Flushing method -Manual.
        // Create Routing.
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, FlushingMethod, false, UnitCostCalcType, '');
        CreateMachineCenter(MachineCenterNo, WorkCenterNo, FlushingMethod);
        CreateMachineCenter(MachineCenterNo2, WorkCenterNo, FlushingMethod);
        if UpdateProdOrderRouting then
            CreateMachineCenter(MachineCenterNo3, WorkCenterNo, FlushingMethod);
        if Subcontract then
            CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, SubcontractFlushingMethod, true, UnitCostCalcType, CurrencyCode)
        else
            CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, FlushingMethod, false, UnitCostCalcType, CurrencyCode);
        RoutingNo := NoSeries.GetNextNo(ManufacturingSetup."Routing Nos.");
        CreateRouting(RoutingNo, MachineCenterNo, MachineCenterNo2, WorkCenterNo, WorkCenterNo2);

        // Create Items with Flushing method - Manual with the Parent Item containing Routing No. and Production BOM No.
        ComponentItemNos[1] := CreateItem(CostingMethod, Enum::"Reordering Policy"::"Lot-for-Lot", FlushingMethod, '', '');
        ComponentItemNos[2] := CreateItem(CostingMethod, Enum::"Reordering Policy"::"Lot-for-Lot", FlushingMethod, '', '');

        if UpdateProductionComponent then
            ComponentItemNos[3] := CreateItem(Enum::"Costing Method"::Standard, Enum::"Reordering Policy"::"Lot-for-Lot", FlushingMethod, '', '');

        ProductionBOMNo :=
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ComponentItemNos[1], ComponentItemNos[2], 1); // value important.
        ParentItemNo := CreateItem(CostingMethod, Enum::"Reordering Policy"::"Lot-for-Lot", FlushingMethod, RoutingNo, ProductionBOMNo);

        // Calculate Standard Cost for Parent Item, if Costing Method is Standard.
        // Calculate Calendar for Work Center with dates having a difference of 5 weeks.
        // Create and Post Purchase Order as Receive and Invoice.
        if CostingMethod = Enum::"Costing Method"::Standard then
            CalculateStandardCost.CalcItem(ParentItemNo, false);
        CalculateCalendar(MachineCenterNo, MachineCenterNo2, WorkCenterNo, WorkCenterNo2);
        if not AdditionalCurrencyExist then
            CreatePurchaseOrder(
              PurchaseHeader, ComponentItemNos[1], ComponentItemNos[2], ComponentItemNos[3], LibraryRandom.RandIntInRange(10, 100) + 10,
              LibraryRandom.RandIntInRange(10, 100) + 10, LibraryRandom.RandIntInRange(10, 100) + 50, UpdateProductionComponent)
        else
            CreatePurchaseOrderAddnlCurr(PurchaseHeader, CurrencyCode, ComponentItemNos[1], ComponentItemNos[2], ComponentItemNos[3],
              LibraryRandom.RandIntInRange(10, 100) + 10, UpdateProductionComponent);

        if AdjustExchangeRatesGLSetup then begin
            UpdateExchangeRate(CurrencyCode);
            LibraryERM.RunExchRateAdjustment(
              CurrencyCode, WorkDate(), WorkDate(), PurchaseHeader."No.", WorkDate(), LibraryUtility.GenerateGUID(), true);
        end;

        // Create and Refresh Production Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrderStatus, ProductionOrder."Source Type"::Item, ParentItemNo, LibraryRandom.RandInt(10) + 5);
        if UpdateProdOrderRouting then begin
            MachineCenter.Get(MachineCenterNo3);
            LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1W>', WorkDate()), WorkDate());
            AddProdOrderRoutingLine(ProductionOrder, "Capacity Type"::"Machine Center", MachineCenterNo3);
            LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, false, true, false);
        end;

        // Create Subcontracting Worksheet, Make order and Post Subcontracting Purchase Order.
        if Subcontract then begin
            LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);
            MakeSubconPurchOrder(ProductionOrder."No.", WorkCenterNo2);
            PostSubconPurchOrder(TempPurchaseLine, ProductionOrder."No.", SubcontractCostDiff);
        end;

        // Remove one component from Production Order and Replace it with a New Component.
        if UpdateProductionComponent then
            ReplaceProdOrderComponent(ProductionOrder."No.", ComponentItemNos[2], ParentItemNo, ComponentItemNos[3]);

        // Create, Calculate and Post Consumption Journal, Explode Routing and Post Output Journal.
        if FlushingMethod = Enum::"Flushing Method"::Manual then begin
            LibraryManufacturing.CreateProdItemJournal(
              ItemJournalBatch, ComponentItemNos[1], ItemJournalBatch."Template Type"::Consumption, ProductionOrder."No.");
            if DeleteConsumptionJrnl then
                RemoveProdOrderComponent(ProductionOrder."No.", ComponentItemNos[1]);
            if ConsumptionCostDiff then
                UpdateQtyConsumptionJournal(ProductionOrder."No.", ComponentItemNos[2]);
            LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
            LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ComponentItemNos[3], ItemJournalBatch."Template Type"::Output, ProductionOrder."No.");
            if OutputCostDiff then
                UpdateLessQtyOutputJournal(ProductionOrder."No.", ProductionOrder.Quantity);
            if RunSetupTimeCostDiff then begin
                SetupTime := 1;
                RunTime := 1;
                UpdateSetupRunTime(ProductionOrder."No.", SetupTime, RunTime);
            end;
            LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        end;

        // Change Production Order Status.
        if ProductionOrder.Status = ProductionOrder.Status::Planned then
            ProductionOrderNo :=
              LibraryManufacturing.ChangeStatusPlannedToFinished(ProductionOrder."No.") // Change Status from Planned to Finished.
        else
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        // Change Status of Production Order from Released to Finished.

        // 2. Execute Adjust Cost Item Entries report and Post Inventory Cost to G/L report.
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Finished);
        if ProductionOrderNo <> '' then
            ProductionOrder.SetRange("No.", ProductionOrderNo)
        else
            ProductionOrder.SetRange("No.", ProductionOrder."No.");
        ProductionOrder.FindFirst();
        AdjustCostPostInventoryCostGL(ComponentItemNos[1] + '..' + ComponentItemNos[3]);

        // 3. Verify GL Entry : Total amount and Positive amount entries for WIP Account.
        VerifyGLEntryForWIPAccounts(
          TempPurchaseLine, ComponentItemNos[1], ProductionOrder."No.", CurrencyCode, SetupTime, RunTime, AdditionalCurrencyExist);
    end;

    local procedure CalcItemStandardCost(ItemNo: Code[20])
    var
        CalculateStdCost: Codeunit "Calculate Standard Cost";
    begin
        CalculateStdCost.SetProperties(WorkDate(), true, false, false, '', false);
        CalculateStdCost.CalcItem(ItemNo, false);
    end;

    local procedure CalcProdOrderWIPAmount(ProdOrderNo: Code[20]) WIPAmount: Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ProdOrderNo);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost");

        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Consumption);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        WIPAmount += ValueEntry."Cost Amount (Actual)";

        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::" ");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        WIPAmount -= ValueEntry."Cost Amount (Actual)";

        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        WIPAmount += ValueEntry."Cost Amount (Actual)";
    end;

    [Normal]
    local procedure CreateWorkCenter(
        var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10]; FlushingMethod: Enum "Flushing Method"; Subcontract: Boolean;
        UnitCostCalcType: Enum "Unit Cost Calculation Type"; CurrencyCode: Code[10])
    var
        WorkCenter: Record "Work Center";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Create Work Center with required fields where random is used, values not important for test.
        CreateWorkCenterWithFixedCost(WorkCenter, ShopCalendarCode, 0);

        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Overhead Rate", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalcType);

        if Subcontract then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GenProductPostingGroup.FindFirst();
            GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            GenProductPostingGroup.Modify(true);
            WorkCenter.Validate("Subcontractor No.", CreateSubcontractorWithCurrency(CurrencyCode));
        end;
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure CreateWorkCenterWithFixedCost(var WorkCenter: Record "Work Center"; ShopCalendarCode: Code[10]; DirectUnitCost: Decimal)
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Direct Unit Cost", DirectUnitCost);
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Modify(true);
    end;

    local procedure CreateWorkCenterWithCalendar(var WorkCenter: Record "Work Center"; DirectUnitCost: Decimal)
    var
        ShopCalendarCode: Code[10];
    begin
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarFullWorkingWeekCustomTime(080000T, 160000T);
        CreateWorkCenterWithFixedCost(WorkCenter, ShopCalendarCode, DirectUnitCost);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1W>', WorkDate()), WorkDate());
    end;

    [Normal]
    local procedure CreateMachineCenter(var MachineCenterNo: Code[20]; WorkCenterNo: Code[20]; FlushingMethod: Enum "Flushing Method")
    var
        MachineCenter: Record "Machine Center";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        // Create Machine Center with required fields where random is used, values not important for test.
        GenProductPostingGroup.FindFirst();
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(10, 1));
        MachineCenter.Validate(Name, MachineCenter."No.");
        MachineCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(5, 1));
        MachineCenter.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 1));
        MachineCenter.Validate("Overhead Rate", 1);
        MachineCenter.Validate("Flushing Method", FlushingMethod);
        MachineCenter.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        MachineCenter.Validate(Efficiency, 100);
        MachineCenter.Modify(true);
        MachineCenterNo := MachineCenter."No.";
    end;

    [Normal]
    local procedure CreateRouting(var RoutingNo: Code[20]; MachineCenterNo: Code[20]; MachineCenterNo2: Code[20]; WorkCenterNo: Code[20]; WorkCenterNo2: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo2);
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenterNo);
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenterNo2);

        // Certify Routing after Routing lines creation.
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        RoutingNo := RoutingHeader."No.";
    end;

    [Normal]
    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        OperationNo: Code[10];
    begin
        // Create Routing Lines with required fields.
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Minutes);
        CapacityUnitOfMeasure.FindFirst();

        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random is used, values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));

        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);
    end;

    local procedure CreateCertifiedRouting(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; RunTime: Decimal)
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    [Normal]
    local procedure CreateItem(
        ItemCostingMethod: Enum "Costing Method"; ItemReorderPolicy: Enum "Reordering Policy"; FlushingMethod: Enum "Flushing Method";
        RoutingNo: Code[20]; ProductionBOMNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        // Create Item with required fields where random values not important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, ItemCostingMethod, LibraryRandom.RandInt(10), ItemReorderPolicy, FlushingMethod, RoutingNo, ProductionBOMNo);
        Item.Validate("Overhead Rate", LibraryRandom.RandDec(5, 2));
        Item.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 2));
        Item.Modify(true);

        exit(Item."No.");
    end;

    local procedure CreateItemNoIndirectCost(var Item: Record Item; CostingMethod: Enum "Costing Method"; RoundingPrecision: Decimal; RoutingNo: Code[20]; ProdBOMNo: Code[20]; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Rounding Precision", RoundingPrecision);
        Item.Validate("Routing No.", RoutingNo);
        Item.Validate("Production BOM No.", ProdBOMNo);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateItemWithCostingMethod(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
    end;

    [Normal]
    local procedure CreatePurchaseOrderAddnlCurr(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20]; Qty: Decimal; UpdateProductionComponent: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeaderAddnlCurr(PurchaseHeader, CurrencyCode);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, "Purchase Line Type"::Item, ItemNo, Qty);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, "Purchase Line Type"::Item, ItemNo2, Qty);
        if UpdateProductionComponent then
            CreatePurchaseLine(PurchaseHeader, PurchaseLine, "Purchase Line Type"::Item, ItemNo3, Qty);
    end;

    [Normal]
    local procedure CreatePurchaseHeaderAddnlCurr(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateSubcontractorWithCurrency(CurrencyCode));
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; ItemNo: Code[20]; Qty: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, ItemNo, Qty);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
    begin
        // Create new currency and validate the required GL Accounts.
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.FindDirectPostingGLAccount(GLAccount);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Validate("Realized G/L Gains Account", GLAccount."No.");
        Currency.Validate("Realized G/L Losses Account", GLAccount."No.");
        Currency.Modify(true);
        Commit();  // Required to run the Test Case on RTC.

        // Create Currency Exchange Rate.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());

        // Using RANDOM Exchange Rate Amount and Adjustment Exchange Rate, between 100 and 400 (Standard Value).
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100 * LibraryRandom.RandInt(4));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Relational Exch. Rate Amount and Relational Adjmt Exch Rate Amt always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 2 * CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
        exit(Currency.Code);
    end;

    local procedure UpdateExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        NewExchangeRateAmount: Decimal;
    begin
        SelectCurrencyExchangeRate(CurrencyExchangeRate, CurrencyCode);
        NewExchangeRateAmount := CurrencyExchangeRate."Exchange Rate Amount" * LibraryRandom.RandInt(5);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", NewExchangeRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    [Normal]
    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    [Normal]
    local procedure CalculateCalendar(MachineCenterNo: Code[20]; MachineCenterNo2: Code[20]; WorkCenterNo: Code[20]; WorkCenterNo2: Code[20])
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        MachineCenter.Get(MachineCenterNo);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1W>', WorkDate()), WorkDate());
        MachineCenter.Get(MachineCenterNo2);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1W>', WorkDate()), WorkDate());
        WorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1W>', WorkDate()), WorkDate());
        WorkCenter.Get(WorkCenterNo2);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1W>', WorkDate()), WorkDate());
    end;

    [Normal]
    local procedure UpdateAddnlReportingCurrency() CurrencyCode: Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Create new Currency code and set Residual Gains Account and Residual Losses Account for Currency.
        CurrencyCode := CreateCurrency();
        Commit();

        // Update Additional Reporting Currency on G/L setup to execute Adjust Additional Reporting Currency report.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CurrencyCode;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; ItemNo2: Code[20]; ItemNo3: Code[20]; Quantity: Decimal; Quantity2: Decimal; Quantity3: Decimal; UpdateProductionComponent: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo, Quantity);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo2, Quantity2);
        if UpdateProductionComponent then
            CreatePurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::Item, ItemNo3, Quantity3);
    end;

    [Normal]
    local procedure AddProdOrderRoutingLine(ProductionOrder: Record "Production Order"; CapacityType: Enum "Capacity Type"; MachineCenterNo: Code[20])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Validate(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.Validate("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.Validate("Routing No.", ProductionOrder."Routing No.");
        ProdOrderRoutingLine.Validate("Routing Reference No.", SelectRoutingRefNo(ProductionOrder."No.", ProductionOrder."Routing No."));
        ProdOrderRoutingLine.Validate(
          "Operation No.",
          CopyStr(
            LibraryUtility.GenerateRandomCode(ProdOrderRoutingLine.FieldNo("Operation No."), DATABASE::"Prod. Order Routing Line"), 1,
            MaxStrLen(ProdOrderRoutingLine."Operation No.") - 1));
        ProdOrderRoutingLine.Insert(true);
        ProdOrderRoutingLine.Validate(Type, CapacityType);
        ProdOrderRoutingLine.Validate("No.", MachineCenterNo);
        ProdOrderRoutingLine.Validate("Setup Time", LibraryRandom.RandInt(5));
        ProdOrderRoutingLine.Validate("Run Time", LibraryRandom.RandInt(5));
        ProdOrderRoutingLine.Modify(true);
    end;

    [Normal]
    local procedure ReplaceProdOrderComponent(ProductionOrderNo: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]; NewItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Planned);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Delete(true);
        Commit();

        ProdOrderLine.SetRange(Status, ProdOrderComponent.Status::Planned);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.SetRange("Item No.", ItemNo2);
        ProdOrderLine.FindFirst();
        CreateProdOrderComponent(ProdOrderLine, ProdOrderComponent, NewItemNo, 1); // value important for test.
    end;

    local procedure CreateProdOrderComponent(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComponent: Record "Prod. Order Component"; ItemNo: Code[20]; QuantityPer: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", QuantityPer);
        ProdOrderComponent.Modify(true);
    end;

    [Normal]
    local procedure MakeSubconPurchOrder(ProductionOrderNo: Code[20]; WorkCenterNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // Update Direct unit Cost and Make Order,random is used values not important for test.
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrderNo);
        RequisitionLine.SetRange("Work Center No.", WorkCenterNo);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    local procedure PostConsumption(ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; PostingDate: Date; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJnlTemplate, ItemJnlTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(ItemJnlBatch, ItemJnlTemplate.Type, ItemJnlTemplate.Name);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJnlLine."Entry Type"::Consumption, ItemNo, Qty);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderNo);
        ItemJnlLine.Validate("Order Line No.", ProdOrderLineNo);
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure PostOutput(ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; PostingDate: Date; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJnlTemplate, ItemJnlTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJnlBatch, ItemJnlTemplate.Type, ItemJnlTemplate.Name);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJnlLine."Entry Type"::Output, ItemNo, Qty);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderNo);
        ItemJnlLine.Validate("Order Line No.", ProdOrderLineNo);
        ItemJnlLine.Validate("Output Quantity", Qty);
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure PostConsumptionFromProdOrder(ItemNo: Code[20]; ProdOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryManufacturing.CreateProdItemJournal(
          ItemJournalBatch, ItemNo, ItemJournalBatch."Template Type"::Consumption, ProdOrderNo);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure PostItemStock(ItemNo: Code[20]; Qty: Integer; UnitAmount: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostRandomItemStock(ItemNo: Code[20]; UnitAmount: Decimal) Qty: Integer
    begin
        Qty := LibraryRandom.RandIntInRange(100, 200);
        PostItemStock(ItemNo, Qty, UnitAmount);
    end;

    local procedure PostProdOrderOutput(ProductionOrder: Record "Production Order"; OutputQty: Decimal; RunTime: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryManufacturing.CreateProdItemJournal(
          ItemJournalBatch, ProductionOrder."Source No.", ItemJournalBatch."Template Type"::Output, ProductionOrder."No.");
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Output Quantity", OutputQty);
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    [Normal]
    local procedure PostSubconPurchOrder(var TempPurchaseLine: Record "Purchase Line" temporary; ProductionOrder: Code[20]; SubconCostDiff: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Find Subcontracting Purchase Order and Post.
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder);
        PurchaseLine.FindFirst();

        // If Expected Cost is different.
        if SubconCostDiff then begin
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(5) + 5);
            PurchaseLine.Modify(true);
        end;
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();

        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.Validate(
          "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."),
            DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    [Normal]
    local procedure RemoveProdOrderComponent(ProductionOrderNo: Code[20]; ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Delete(true);
    end;

    [Normal]
    local procedure UpdateQtyConsumptionJournal(ProductionOrderNo: Code[20]; ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate(Quantity, ItemJournalLine.Quantity + 1);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateLessQtyOutputJournal(ProductionOrderNo: Code[20]; ProductionOrderQuantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate("Output Quantity", ProductionOrderQuantity - 1);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateSetupRunTime(ProductionOrderNo: Code[20]; SetupTime: Decimal; RunTime: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindSet();

        repeat
            ItemJournalLine.Validate("Run Time", RunTime);
            ItemJournalLine.Validate("Setup Time", SetupTime);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    [Normal]
    local procedure AdjustCostPostInventoryCostGL(ItemNoFilter: Text[250])
    begin
        LibraryCosting.AdjustCostItemEntries(ItemNoFilter, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');
    end;

    local procedure CreateSubcontractorWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        // Create a Subcontractor Vendor.
        LibraryPurchase.CreateSubcontractor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    [Normal]
    local procedure SelectRoutingRefNo(ProductionOrderNo: Code[20]; ProdOrderRoutingNo: Code[20]): Integer
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderRoutingNo);
        ProdOrderRoutingLine.FindFirst();
        exit(ProdOrderRoutingLine."Routing Reference No.");
    end;

    [Normal]
    local procedure SelectGLEntry(var GLEntry: Record "G/L Entry"; InventoryPostingSetupAccount: Code[20]; ProductionOrderNo: Code[20]; PurchaseInvoiceNo: Code[20])
    begin
        // Select set of G/L Entries for the specified Account.
        if PurchaseInvoiceNo <> '' then
            GLEntry.SetFilter("Document No.", '%1|%2', ProductionOrderNo, PurchaseInvoiceNo)
        else
            GLEntry.SetFilter("Document No.", ProductionOrderNo);
        GLEntry.SetRange("G/L Account No.", InventoryPostingSetupAccount);
        GLEntry.FindSet();
    end;

    local procedure SelectCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
    end;

    [Normal]
    local procedure CalculateGLAmount(var GLEntry: Record "G/L Entry"; AdditionalCurrencyExist: Boolean): Decimal
    var
        CalculatedAmount: Decimal;
    begin
        if not AdditionalCurrencyExist then begin
            GLEntry.SetFilter(Amount, '>0');
            if GLEntry.FindSet() then
                repeat
                    CalculatedAmount += GLEntry.Amount;
                until GLEntry.Next() = 0;
            exit(CalculatedAmount);
        end;

        GLEntry.SetFilter("Additional-Currency Amount", '>0');
        if GLEntry.FindSet() then
            repeat
                CalculatedAmount += GLEntry."Additional-Currency Amount";
            until GLEntry.Next() = 0;

        exit(CalculatedAmount);
    end;

    [Normal]
    local procedure CheckSubconWorkCenter(ProductionOrderNo: Code[20]): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // Check Flushing Method On WorkCenter.
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Finished);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Work Center");
        ProdOrderRoutingLine.FindSet();
        repeat
            WorkCenter.Get(ProdOrderRoutingLine."No.");
            if WorkCenter."Subcontractor No." <> '' then
                exit(true);
        until ProdOrderRoutingLine.Next() = 0;
    end;

    [Normal]
    local procedure TimeSubTotalWorkCenter(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Quantity: Decimal; SetupTime: Decimal; RunTime: Decimal): Decimal
    var
        WorkCenter: Record "Work Center";
    begin
        if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Machine Center" then
            exit;

        if SetupTime = 0 then
            SetupTime := ProdOrderRoutingLine."Setup Time";
        if RunTime = 0 then
            RunTime := ProdOrderRoutingLine."Run Time";

        WorkCenter.Get(ProdOrderRoutingLine."No.");
        if (WorkCenter."Subcontractor No." <> '') and (WorkCenter."Flushing Method" <> WorkCenter."Flushing Method"::Backward) then
            exit;
        if WorkCenter."Unit Cost Calculation" = WorkCenter."Unit Cost Calculation"::Time then begin
            if WorkCenter."Flushing Method" = WorkCenter."Flushing Method"::Manual then
                exit(SetupTime + RunTime);
            if (WorkCenter."Flushing Method" = WorkCenter."Flushing Method"::Backward) and (WorkCenter."Subcontractor No." <> '') then
                exit(Quantity);
            exit(SetupTime + Quantity * RunTime);
        end;

        exit(Quantity);
    end;

    [Normal]
    local procedure TimeSubTotalMachineCenter(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Quantity: Decimal; SetupTime: Decimal; RunTime: Decimal): Decimal
    var
        MachineCenter: Record "Machine Center";
    begin
        if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center" then
            exit;

        if SetupTime = 0 then
            SetupTime := ProdOrderRoutingLine."Setup Time";
        if RunTime = 0 then
            RunTime := ProdOrderRoutingLine."Run Time";

        MachineCenter.Get(ProdOrderRoutingLine."No.");
        if MachineCenter."Flushing Method" = MachineCenter."Flushing Method"::Manual then
            exit(SetupTime + RunTime);
        exit(SetupTime + Quantity * RunTime);
    end;

    local procedure CalculateDirectSubcontractingCost(TempPurchaseLine: Record "Purchase Line" temporary; CurrencyCode: Code[10]): Decimal
    begin
        exit(Round(TempPurchaseLine.Quantity * TempPurchaseLine."Direct Unit Cost", LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode)));
    end;

    local procedure CalculateIndirectSubcontractingCost(TempPurchaseLine: Record "Purchase Line" temporary; CurrencyCode: Code[10]): Decimal
    var
        OverheadRate: Decimal;
    begin
        // Overhead in purchase line is copied from the item card and is always an LCY amount
        OverheadRate := ExchangeAmtLCYToFCY(TempPurchaseLine."Overhead Rate", CurrencyCode);
        exit(
            Round(
                TempPurchaseLine.Quantity * ((TempPurchaseLine."Indirect Cost %" / 100) * TempPurchaseLine."Direct Unit Cost" + OverheadRate),
                LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode)));
    end;

    [Normal]
    local procedure DirectIndirectMachineCntrCost(RoutingNo: Code[20]; Quantity: Decimal; SetupTime: Decimal; RunTime: Decimal; CurrencyCode: Code[10]): Decimal
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MachineCenter: Record "Machine Center";
        TimeSubtotal: Decimal;
        MachineCenterAmount: Decimal;
    begin
        // Calculate Cost Amount for Machine Center.
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Machine Center");
        if ProdOrderRoutingLine.FindSet() then
            repeat
                MachineCenter.Get(ProdOrderRoutingLine."No.");
                TimeSubtotal := TimeSubTotalMachineCenter(ProdOrderRoutingLine, Quantity, SetupTime, RunTime);
                MachineCenterAmount += ExchangeAmtLCYToFCYWithRounding(TimeSubtotal * MachineCenter."Direct Unit Cost", CurrencyCode);
                MachineCenterAmount +=
                    ExchangeAmtLCYToFCYWithRounding(
                        TimeSubtotal * ((MachineCenter."Indirect Cost %" / 100) * MachineCenter."Direct Unit Cost" + MachineCenter."Overhead Rate"),
                        CurrencyCode);
            until ProdOrderRoutingLine.Next() = 0;
        exit(MachineCenterAmount);
    end;

    [Normal]
    local procedure DirectIndirectWorkCntrCost(RoutingNo: Code[20]; Quantity: Decimal; SetupTime: Decimal; RunTime: Decimal; CurrencyCode: Code[10]): Decimal
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        TimeSubtotal: Decimal;
        WorkCenterAmount: Decimal;
    begin
        // Calculate Cost Amount for Work Center.
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Work Center");
        if ProdOrderRoutingLine.FindSet() then
            repeat
                WorkCenter.Get(ProdOrderRoutingLine."No.");
                TimeSubtotal := TimeSubTotalWorkCenter(ProdOrderRoutingLine, Quantity, SetupTime, RunTime);
                WorkCenterAmount += ExchangeAmtLCYToFCYWithRounding(TimeSubtotal * WorkCenter."Direct Unit Cost", CurrencyCode);
                WorkCenterAmount +=
                    ExchangeAmtLCYToFCYWithRounding(
                        TimeSubtotal * ((WorkCenter."Indirect Cost %" / 100) * WorkCenter."Direct Unit Cost" + WorkCenter."Overhead Rate"), CurrencyCode);
            until ProdOrderRoutingLine.Next() = 0;
        exit(WorkCenterAmount);
    end;

    local procedure UpdateUnitCostInPurchaseLine(var PurchaseLine: Record "Purchase Line"; UnitCost: Decimal)
    begin
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
    end;

    [Normal]
    local procedure VerifyGLEntryForWIPAccounts(TempPurchaseLine: Record "Purchase Line" temporary; ItemNo: Code[20]; ProductionOrderNo: Code[20]; CurrencyCode: Code[10]; SetupTime: Decimal; RunTime: Decimal; AdditionalCurrencyExist: Boolean)
    var
        Item: Record Item;
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLEntry: Record "G/L Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        Item.Get(ItemNo);
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", Item."Inventory Posting Group");
        InventoryPostingSetup.FindFirst();

        // Verify positive WIP Account amount is equal to calculated amount.
        PurchInvHeader.SetRange("Order No.", TempPurchaseLine."Document No.");
        PurchInvHeader.FindFirst();
        SelectGLEntry(GLEntry, InventoryPostingSetup."WIP Account", ProductionOrderNo, PurchInvHeader."No.");

        // True if Flushing is backward in a subcontract Work center.
        VerifyWIPAmounts(
          GLEntry, TempPurchaseLine, ProductionOrderNo, CurrencyCode, SetupTime, RunTime, CheckSubconWorkCenter(ProductionOrderNo),
          AdditionalCurrencyExist);
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; PostingDate: Date; CostAmount: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Posting Date", PostingDate);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", CostAmount);
    end;

    local procedure VerifyValueEntryValuationDate(ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; PostingDate: Date; ExpectedValuationDate: Date)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ProdOrderLine."Prod. Order No.");
        ValueEntry.SetRange("Order Line No.", ProdOrderLine."Line No.");
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Type", EntryType);
        ValueEntry.SetRange("Posting Date", PostingDate);
        ValueEntry.FindFirst();

        ValueEntry.TestField("Valuation Date", ExpectedValuationDate);
    end;

    [Normal]
    local procedure VerifyWIPAmounts(var GLEntry: Record "G/L Entry"; TempPurchaseLine: Record "Purchase Line" temporary; ProductionOrderNo: Code[20]; CurrencyCode: Code[10]; SetupTime: Decimal; RunTime: Decimal; CheckSubcontractWorkCenter: Boolean; AdditionalCurrencyExist: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CalculatedWIPAmount: Decimal;
        TotalConsumptionValue: Decimal;
        TotalAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        TotalAmount := CalculateGLAmount(GLEntry, AdditionalCurrencyExist);

        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrderNo);

        TotalConsumptionValue := CalcTotalComponentConsumptionValue(ProductionOrderNo, CurrencyCode);

        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Finished, ProductionOrderNo);

        CalculatedWIPAmount :=
            TotalConsumptionValue +
            DirectIndirectMachineCntrCost(ProductionOrder."Routing No.", ProdOrderLine."Finished Quantity", SetupTime, RunTime, CurrencyCode) +
            DirectIndirectWorkCntrCost(ProductionOrder."Routing No.", ProdOrderLine."Finished Quantity", SetupTime, RunTime, CurrencyCode);

        if CheckSubcontractWorkCenter then
            CalculatedWIPAmount += CalculateDirectSubcontractingCost(TempPurchaseLine, CurrencyCode) + CalculateIndirectSubcontractingCost(TempPurchaseLine, CurrencyCode);

        // Verify WIP Account amounts and calculated WIP amounts are equal.
        Assert.AreNearlyEqual(TotalAmount, CalculatedWIPAmount, 2 * GeneralLedgerSetup."Amount Rounding Precision", AmountDoNotMatchErr);
    end;

    local procedure CalcTotalComponentConsumptionValue(ProdOrderNo: Code[20]; CurrencyCode: Code[10]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Item: Record Item;
        ItemCost: Decimal;
        TotalCost: Decimal;
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProdOrderNo);
        ItemLedgerEntry.SetLoadFields("Item No.", Quantity);
        if ItemLedgerEntry.FindSet() then
            repeat
                Item.SetLoadFields("Costing Method", "Standard Cost", "Unit Cost");
                Item.Get(ItemLedgerEntry."Item No.");
                if Item."Costing Method" = Item."Costing Method"::Standard then
                    ItemCost := Item."Standard Cost"
                else
                    ItemCost := Item."Unit Cost";

                TotalCost += ExchangeAmtLCYToFCYWithRounding(-ItemLedgerEntry.Quantity * ItemCost, CurrencyCode);
            until ItemLedgerEntry.Next() = 0;

        exit(TotalCost);
    end;

    local procedure ExchangeAmtLCYToFCY(Amount: Decimal; CurrencyCode: Code[10]): Decimal
    var
        CurrencyExchRate: Record "Currency Exchange Rate";
    begin
        exit(CurrencyExchRate.ExchangeAmtLCYToFCY(WorkDate(), CurrencyCode, Amount, CurrencyExchRate.ExchangeRate(WorkDate(), CurrencyCode)));
    end;

    local procedure ExchangeAmtLCYToFCYWithRounding(Amount: Decimal; CurrencyCode: Code[10]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        RoundedLCYAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        RoundedLCYAmount := Round(Amount, GeneralLedgerSetup."Amount Rounding Precision");
        exit(Round(ExchangeAmtLCYToFCY(RoundedLCYAmount, CurrencyCode), LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode)));
    end;

    [Normal]
    local procedure RaiseConfirmHandler()
    begin
        if Confirm('') then;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalcStdCostMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Calculate Standard Cost for All Level.
        Choice := 2;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmText: Text[1024]; var Confirm: Boolean)
    begin
        Confirm := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}

