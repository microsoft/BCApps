// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Subcontracting.Test;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Warehouse.Setup;
using System.TestLibraries.Utilities;

codeunit 149916 "Subc SCM Prod. Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Production Order] [SCM] [Subcontracting]
        IsInitialized := false;
    end;

    var
        LocationRed: Record Location;
        LocationBlue: Record Location;
        LocationWhite: Record Location;
        LocationSilver: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCosting: Codeunit "Library - Costing";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ShopCalendarMgt: Codeunit "Shop Calendar Management";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        SubcManagementLibrary: Codeunit "Subc. Management Library";
        IsInitialized: Boolean;
        ItemTrackingErr: Label 'You cannot define item tracking on this line because it is linked to production order';
        RecreatePurchaseLineConfirmHandlerQst: Label 'If you change %1, the existing purchase lines will be deleted and new purchase lines based on the new information in the header will be created.\\Do you want to continue?', Comment = '%1 - field caption';
        ValueEntrySourceTypeErr: Label 'Value Entry Source Type must be equal to %1', Comment = '%1 - source type';
        ValueEntrySourceNoErr: Label 'Value Entry Source No must be equal to %1', Comment = '%1 - source no';
        ILEQtyEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 - field caption, %2 - quantity, %3 - table caption';
        ProdJournalOutQtyErr: Label 'Output Quantity should be 0 in Production Journal Line linked to Subcontracted Workcenter';
        SubcItemJnlErr: Label '%1 must be zero', Comment = '%1 - "Subcontractor No."';

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderForReleasedProdOrderWithTracking()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Setup: Create Item with Item Tracking Code and Routing. Create and refresh Released Production Order.
        Initialize();
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), '', '');
        AssignTrackingOnProdOrderLine(ProductionOrder."No.");  // Assign Lot Tracking on Prod. Order Line.

        // Exercise: Calculate Subcontracts from Subcontracting Worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Reservation Entry for Status and Tracking after Calculate Subcontracts. Verify Production Quantity and WorkCenter Subcontractor on Subcontracting Worksheet.
        VerifyReservationEntry(Item."No.", ProductionOrder.Quantity, ReservationEntry."Reservation Status"::Surplus, '');
        VerifyRequisitionLineForSubcontract(ProductionOrder, WorkCenter, Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseLineAfterCalcSubcontractOrderAndCarryOutForProdOrderWithTracking()
    begin
        // Verify the Purchase Line created after Calculate Subcontracts and Carry Out on Subcontracting Worksheet.
        // Setup.
        Initialize();
        CalcSubcontractOrderForReleasedProductionOrderWithTracking(false);  // Assign Tracking on Purchase Line FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorAssignTrackingOnPurchLineAfterCalcSubcontractOrderAndCarryOutForProdOrderWithTracking()
    begin
        // Verify the Tracking error on Purchase Line after Calculate Subcontracts and Carry Out.
        // Setup.
        Initialize();
        CalcSubcontractOrderForReleasedProductionOrderWithTracking(true);  // Assign Tracking on Purchase Line TRUE.
    end;

    local procedure CalcSubcontractOrderForReleasedProductionOrderWithTracking(AssignTracking: Boolean)
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Item with Item Tracking Code and Routing. Create and refresh Released Production Order.
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(100, 2), '', '');
        AssignTrackingOnProdOrderLine(ProductionOrder."No.");  // Assign Lot Tracking on Prod. Order Line.
        CalculateSubcontractOrder(WorkCenter);  // Calculate Subcontracts from Subcontracting worksheet.

        // Exercise: Accept and Carry Out Subcontracting Worksheet. Assign Tracking on Purchase Line.
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
        FindPurchaseOrderLine(PurchaseLine, Item."No.");
        if AssignTracking then begin
            asserterror PurchaseLine.OpenItemTrackingLines();

            // Verify: Verify the Tracking error on Purchase Line. Verify the Quantity on Purchase Line created.
            Assert.ExpectedError(ItemTrackingErr);
        end else
            VerifyPurchaseLine(Item."No.", ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchOrderWithCalcSubcontractOrderAndCarryOutForProdOrderWithTracking()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Item with Item Tracking Code and Routing. Create and refresh Released Production Order.
        Initialize();
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(100, 2), '', '');
        AssignTrackingOnProdOrderLine(ProductionOrder."No.");  // Assign Lot Tracking on Prod. Order Line.
        CalculateSubcontractOrder(WorkCenter);  // Calculate Subcontracts from Subcontracting worksheet.

        // Accept and Carry Out Action Message on Subcontracting Worksheet.
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // Exercise: Post Purchase Order as Ship.
        PostPurchaseOrderAsShip(Item."No.");

        // Verify: Verify that Finished Quantity on Prod. Order Line exist after Purchase Order posting.
        VerifyReleasedProdOrderLine(Item."No.", ProductionOrder.Quantity, ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure UndoPurchReceiptWithProductionSubcontracting_NoTracking()
    begin
        UndoPurchReceiptWithProductionSubcontracting(false, false, false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ItemTrackingPageHandler')]
    procedure UndoPurchReceiptWithProductionSubcontracting_LotTracking()
    begin
        UndoPurchReceiptWithProductionSubcontracting(true, false, false)
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure UndoPurchReceiptWithProductionSubcontracting_ErrorOutputUsed()
    var
        OutputUsedErr: Label 'Remaining Quantity must be equal to';
    begin
        asserterror UndoPurchReceiptWithProductionSubcontracting(false, false, true);
        Assert.ExpectedError(OutputUsedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure UndoPurchReceiptWithProductionSubcontracting_ErrorInvoiced()
    var
        AlreadyInvoicedErr: Label 'This receipt has already been invoiced. Undo Receipt can be applied only to posted, but not invoiced receipts.';
    begin
        asserterror UndoPurchReceiptWithProductionSubcontracting(false, true, false);
        Assert.ExpectedError(AlreadyInvoicedErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderForReleasedProductionOrderWithLocationAndTracking()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Setup: Create Item with Item Tracking Code and Routing. Create and refresh Released Production Order with Location.
        Initialize();
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), LocationBlue.Code, '');
        AssignTrackingOnProdOrderLine(ProductionOrder."No.");  // Assign Lot Tracking on Prod. Order Line.

        // Exercise: Calculate Subcontracts from Subcontracting Worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Reservation Entry for Status, Location Code and Tracking after Calculate Subcontracts. Verify Production Quantity and WorkCenter Subcontractor on Subcontracting Worksheet.
        VerifyReservationEntry(Item."No.", ProductionOrder.Quantity, ReservationEntry."Reservation Status"::Surplus, LocationBlue.Code);
        VerifyRequisitionLineForSubcontract(ProductionOrder, WorkCenter, Item."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure PurchaseLineAfterUpdatingVATBusPostingGroupFromHeader()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // Test that after changing VAT bus posting group from Purchase Header created from subcontacting worksheet, Purchase line should not be updated with Item card.
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2), '', '');

        // Calculate Subcontracts from Subcontracting worksheet and Carry Out Action Message.
        CalculateSubcontractOrder(WorkCenter);
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // Exercise: Update the purchase header with VAT bus posting group different from the earlier one.
        LibraryVariableStorage.Enqueue(
          StrSubstNo(RecreatePurchaseLineConfirmHandlerQst, PurchaseHeader.FieldCaption("VAT Bus. Posting Group")));  // Required inside ConfirmHandlerTRUE.
        FindPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        UpdatePurchaseHeaderVATBusPostingGroup(PurchaseHeader);

        // Verify: Verify that the Purchase line should not be updated with Item card. And the field values remains the same.
        VerifyRecreatedPurchaseLine(PurchaseLine, PurchaseHeader."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesCreatesValueEntryWithSourceTypeTakenFromoItemLedgerEntryDuringSubcontracting()
    var
        Item: Record Item;
        ChildItem: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Adjust Cost] [Subcontracting]
        // [SCENARIO 361968] Adjust Cost Item Entries creates Value Entry with "Source Type" and "Source No." taken from original VE during Subcontracting
        Initialize();

        // [GIVEN] Subcontracting Work Center
        // [GIVEN] Item with Routing
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        // [GIVEN] Released Production Order
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(5));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        // [GIVEN] Subcontracting Purchase Order
        // [GIVEN] Post output/consuption. Finish Production Order
        CreateAndPostSubcontractingPurchaseOrder(WorkCenter, Item."No.");
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [WHEN] Run Adjust Cost Item Entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Value Entry is created with "Source Type" and "Source No." taken from from Original VE
        VerifyValueEntrySource(ProductionOrder."No.", WorkCenter."Subcontractor No.", ValueEntry."Source Type"::Vendor);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalSubcontractedPageHandler')]
    [Scope('OnPrem')]
    procedure CheckProductionJournalOutQtyWithSubcontractedWorkCenter()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Production Journal] [Subcontracting]
        // [SCENARIO 363578] Production Journal should fill "Output Quantity" with zero while linked to Subcontracted Work Center
        Initialize();

        // [GIVEN] Released Production Order with Subcontracting
        LibraryInventory.CreateItem(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // [WHEN] Open Production Journal
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [THEN] Production Journal has "Output Quantity" = 0
        // Verify throuhg ProductionJournalSubcontractedPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSubcontractedItemJournalOutputQuantity()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Production Journal] [Subcontracting]
        // [SCENARIO 363578] Item Journal Line should keep "Output Quantity" zero while linked to Subcontracted Work Center
        Initialize();

        // [GIVEN] Item Journal Line linked to Subcontracted Workcenter
        MockSubcontractedJournalLine(ItemJournalLine);

        // [WHEN] Set "Output Quantity" to X <> 0
        asserterror ItemJournalLine.Validate("Output Quantity", LibraryRandom.RandInt(5));

        // [THEN] Error is thrown: "Subcontracor No." must not be
        Assert.ExpectedError(StrSubstNo(SubcItemJnlErr, ItemJournalLine.FieldCaption("Output Quantity")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSubcontractedItemJournalRunTime()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Production Journal] [Subcontracting]
        // [SCENARIO 363578] Item Journal Line should keep "Run Time" zero while linked to Subcontracted Work Center
        Initialize();

        // [GIVEN] Item Journal Line linked to Subcontracted Workcenter
        MockSubcontractedJournalLine(ItemJournalLine);

        // [WHEN] Set "Run Time" to X <> 0
        asserterror ItemJournalLine.Validate("Run Time", LibraryRandom.RandInt(5));

        // [THEN] Error is thrown: "Subcontracor No." must not be
        Assert.ExpectedError(StrSubstNo(SubcItemJnlErr, ItemJournalLine.FieldCaption("Run Time")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSubcontractedItemJournalSetupTime()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Production Journal] [Subcontracting]
        // [SCENARIO 363578] Item Journal Line should keep "Setup Time" zero while linked to Subcontracted Work Center
        Initialize();

        // [GIVEN] Item Journal Line linked to Subcontracted Workcenter
        MockSubcontractedJournalLine(ItemJournalLine);

        // [WHEN] Set "Run Time" to X <> 0
        asserterror ItemJournalLine.Validate("Setup Time", LibraryRandom.RandInt(5));

        // [THEN] Error is thrown: "Subcontracor No." must not be
        Assert.ExpectedError(StrSubstNo(SubcItemJnlErr, ItemJournalLine.FieldCaption("Setup Time")));
    end;

    [Test]
    procedure ConsiderQtyPerUnitOfMeasureForUnitCostInSubcontracting()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Subcontracting] [Unit of Measure]
        // [SCENARIO 403125] The system takes Unit of Measure into account to calculate unit cost when posting output for subcontracting.
        Initialize();

        // [GIVEN] Production item with base unit of measure "PCS", unit cost = 50 LCY.
        // [GIVEN] Create alternate unit of measure "BOX" = 5 "PCS".
        CreateProductionItem(Item, '');
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Create routing for subcontracting, assign it to the item.
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);

        // [GIVEN] Create and refresh production order, quantity = 10.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Change unit of measure on prod. order line from "PCS" to "BOX". Cost amount = 10 * 5 * 50 = 2500 LCY.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProdOrderLine.Modify(true);
        ProdOrderLine.TestField("Cost Amount", ProdOrderLine.Quantity * ProdOrderLine."Qty. per Unit of Measure" * Item."Unit Cost");

        // [GIVEN] Calculate subcontracting, accept action message. This creates a purchase order.
        // [WHEN] Post the purchase order for subcontracting.
        CreateAndPostSubcontractingPurchaseOrder(WorkCenter, Item."No.");

        // [THEN] An output item entry is posted. Cost Amount = 2500 LCY.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Output, Item."No.");
        ItemLedgerEntry.CalcFields("Cost Amount (Expected)");
        ItemLedgerEntry.TestField("Cost Amount (Expected)", ProdOrderLine."Cost Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyRndingPrecisionRespectedOnPurchLineFromSubcontracting()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemUnitOfMeasure: record "Item Unit of Measure";
        BaseUOM: record "Unit of Measure";
        NonBaseUOM: record "Unit of Measure";
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        NonBaseQtyPerUOM: Integer;
    begin
        // Setup: Create Item with two unit of measures and set the base rounding precision to 1
        Initialize();
        NonBaseQtyPerUOM := 6;
        SetupUoMTest(Item, ItemUnitOfMeasure, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, 1);

        // Setup: Create a subcontracting work center for the created item
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);

        // Setup: Create production order where production order line contains quantity on non base unit of measure
        CreateProdOrderAndLineForUoMTest(ProductionOrder, ProdOrderLine, Item, 1, NonBaseUOM, 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // Setup: Calculate subcontrats and carry out suggested requests to create needed purchase lines
        CalculateSubcontractOrder(WorkCenter);
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
        FindPurchaseOrderLine(PurchaseLine, Item."No.");

        // Exercise: When Quanity field is changed
        PurchaseLine.Validate(Quantity, 0.99999);

        // Verify: Quantity (Base) field is recalculated and rounded using the base rounding precision
        PurchaseLine.TestField("Quantity (Base)", 0);

        // Exercise: Purchase document is posted
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Item ledger quantity is rounded
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Output, Item."No.");
        ItemLedgerEntry.TestField(Quantity, 6);
    end;

    [Test]
    procedure RoundingInCostAmountAfterPostingSubcontractingPOWithUoM()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        ValueEntry: Record "Value Entry";
        LotNos: array[20] of Code[50];
        i: Integer;
    begin
        // [FEATURE] [Subcontracting] [Costing] [Rounding] [Unit of Measure]
        // [SCENARIO 468372] Correct rounding in Cost Amount (Actual) after posting subcontracting purchase order with alternate unit of measure.
        Initialize();

        // [GIVEN] Set "Unit-Amount Rounding Precision" = 3 decimal digits (it is 5 digits in standard environment).
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Unit-Amount Rounding Precision" := 0.001;
        GeneralLedgerSetup.Modify();

        // [GIVEN] Lot-tracked item with base unit of measure "KG" and alternate unit of measure "PC" = 0.10273 "KG".
        LibraryItemTracking.CreateLotItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 0.10273);

        // [GIVEN] Add subcontracting routing to the item.
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);

        // [GIVEN] Create and refresh production order for 410.92 "KG".
        // [GIVEN] Add 20 lots, each for 20.546 "KG".
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", 410.92);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        for i := 1 to ArrayLen(LotNos) do begin
            LotNos[i] := LibraryUtility.GenerateGUID();
            LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, '', LotNos[i], 20.546);
        end;

        // [GIVEN] Calculate subcontracting and create purchase order for subcontractor.
        // [GIVEN] Change unit of measure to "PC" on the purchase line, quantity = 4000 "PC". Set "Direct Unit Cost" = 6.
        CalculateSubcontractOrder(WorkCenter);
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
        FindPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseLine.Validate(Quantity, 4000);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Validate("Direct Unit Cost", 6);
        PurchaseLine.Modify(true);

        // [GIVEN] Assign vendor invoice no.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify();

        // [WHEN] Receive and invoice the purchase order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posted cost amount = 4000 * 6 = 24000.00 sharp.
        ValueEntry.SetRange(Type, ValueEntry.Type::"Work Center");
        ValueEntry.SetRange("No.", WorkCenter."No.");
        ValueEntry.CalcSums("Cost Amount (Actual)");
        ValueEntry.TestField("Cost Amount (Actual)", 24000);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePurchaseLinePriceUpdateWithPurchasePriceListFunctionality()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemUnitOfMeasure: record "Item Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO: 479443] Error Qty. per Unit of Measure must have a value in Purchase Line: Document Type=Order, when clicking on the available price in the fact box in a purchase order
        Initialize();

        // [GIVEN] Enable Extended Price Calculation
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // Setup: Create Item with two unit of measures and set the base rounding precision to 1
        SetupUoMTest(Item, ItemUnitOfMeasure, BaseUOM, NonBaseUOM, LibraryRandom.RandInt(10), 1);

        // Setup: Create a subcontracting work center for the created item
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);

        // [GIVEN] Create Purchase Price List
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::Vendor, WorkCenter."Subcontractor No.");
        LibraryPriceCalculation.CreatePriceListLine(PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // Setup: Create production order where production order line contains quantity on base unit of measure
        CreateProdOrderAndLineForUoMTest(ProductionOrder, ProdOrderLine, Item, 1, BaseUOM, 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // Setup: Calculate subcontrats and carry out suggested requests to create needed purchase lines
        CalculateSubcontractOrder(WorkCenter);
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
        FindPurchaseOrderLine(PurchaseLine, Item."No.");

        // [THEN] Open Purchase Order Page
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);

        // [VERIFY] Verify: Lookup to purchase prices from the Purchase Line Factbox open without any error
        PurchaseOrder.Control3.PurchasePrices.Lookup();
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure UndoFirstReceiptInSubcontractingPurchaseOrder()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        WorkCenter: Record "Work Center";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
        FirstReceiptQty: Decimal;
        SecondReceiptQty: Decimal;
        TotalQuantity: Decimal;
    begin
        // [SCENARIO 615586] Undoing first receipt on a subcontracting purchase order should only reverse that receipt
        Initialize();

        // [GIVEN] Create an Item.
        CreateItem(Item);

        // [GIVEN] Create Routing and Update Item for Subcontracting.
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);

        // [GIVEN] Create and Refresh Released Production Order.
        TotalQuantity := LibraryRandom.RandIntInRange(10, 20);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", TotalQuantity, '', '');

        // [GIVEN] Determine quantities for first and second receipts.
        FirstReceiptQty := LibraryRandom.RandIntInRange(6, 9);
        SecondReceiptQty := TotalQuantity - FirstReceiptQty;

        // [GIVEN] Calculate Subcontracting and create Purchase Order.
        CalculateSubcontractOrder(WorkCenter);
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // [GIVEN] Post Purchase Order with first Partial Receipt.
        FindPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.Validate("Qty. to Receive", FirstReceiptQty);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Verify Prod. Order Line after first receipt.
        VerifyReleasedProdOrderLine(Item."No.", TotalQuantity, FirstReceiptQty);

        // [GIVEN] Post Purchase Order with second Partial Receipt.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", SecondReceiptQty);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Verify Prod. Order Line after second receipt.
        VerifyReleasedProdOrderLine(Item."No.", TotalQuantity, TotalQuantity);

        // [GIVEN] Find the first Purchase Receipt Line for the Item.
#pragma warning disable AA0210
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", Item."No.");
#pragma warning restore AA0210
        PurchRcptLine.FindFirst();

        // [WHEN] Undo the selected receipt (first or second based on parameter)
        PostedPurchaseReceipt.OpenEdit();
        PostedPurchaseReceipt.Filter.SetFilter("No.", PurchRcptLine."Document No.");
        PostedPurchaseReceipt.PurchReceiptLines.Last();
        PostedPurchaseReceipt.PurchReceiptLines."&Undo Receipt".Invoke();

        // [GIVEN] Find the last Purchase Receipt Line for the Item after undo.
#pragma warning disable AA0210
        PurchRcptLine.SetFilter(Quantity, '>0');
#pragma warning restore AA0210
        PurchRcptLine.FindLast();

        // [GIVEN] Verify Prod. Order Line after undoing the receipt.
        VerifyReleasedProdOrderLine(Item."No.", TotalQuantity, PurchRcptLine.Quantity);

        // [THEN] Verify that ILE Output Qty. matches expected.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(
            PurchRcptLine.Quantity,
            ItemLedgerEntry.Quantity,
            StrSubstNo(ILEQtyEqualErr, ItemLedgerEntry.FieldCaption(Quantity), PurchRcptLine.Quantity, ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ItemTrackingPageHandlerWithQuantity')]
    procedure UndoSecondReceiptInSubcontractingPurchaseOrder_WithTracking()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        WorkCenter: Record "Work Center";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
        FirstReceiptQty: Decimal;
        SecondReceiptQty: Decimal;
        TotalQuantity: Decimal;
        MustNotBeEqualLbl: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field, %2 = Expected Value, %3 = Table';
    begin
        // [SCENARIO 615586] Undoing first receipt on a subcontracting purchase order with item tracking should only reverse that receipt
        Initialize();

        // [GIVEN] Create an Item with Item Tracking.
        CreateItemWithItemTrackingCode(Item);

        // [GIVEN] Create Routing and Update Item for Subcontracting.
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        TotalQuantity := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", TotalQuantity, '', '');

        // [GIVEN] Determine quantities for first and second receipts.
        FirstReceiptQty := LibraryRandom.RandIntInRange(6, 9);
        SecondReceiptQty := TotalQuantity - FirstReceiptQty;

        // [GIVEN] Assign Tracking on Prod. Order Line before first receipt.
        LibraryVariableStorage.Enqueue(FirstReceiptQty);
        AssignTrackingOnProdOrderLine(ProductionOrder."No.");

        // [GIVEN] Calculate Subcontracting and create Purchase Order.
        CalculateSubcontractOrder(WorkCenter);
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // [GIVEN] Post Purchase Order with first partial receipt.
        FindPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.Validate("Qty. to Receive", FirstReceiptQty);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Verify Prod. Order Line after first receipt.
        VerifyReleasedProdOrderLine(Item."No.", TotalQuantity, FirstReceiptQty);

        // [GIVEN] Assign Tracking on Prod. Order Line before second receipt.
        LibraryVariableStorage.Enqueue(SecondReceiptQty);
        AssignTrackingOnProdOrderLine(ProductionOrder."No.");

        // [GIVEN] Post Purchase Order with second partial receipt.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", SecondReceiptQty);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        VerifyReleasedProdOrderLine(Item."No.", TotalQuantity, TotalQuantity);

        // [WHEN] Undo the selected first receipt
#pragma warning disable AA0210
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", Item."No.");
#pragma warning restore AA0210
        PurchRcptLine.FindFirst();
        PostedPurchaseReceipt.OpenEdit();
        PostedPurchaseReceipt.Filter.SetFilter("No.", PurchRcptLine."Document No.");
        PostedPurchaseReceipt.PurchReceiptLines.Last();

        // [GIVEN] Enqueue the Quantity to be used in Item Tracking Page Handler.
        LibraryVariableStorage.Enqueue(PostedPurchaseReceipt.PurchReceiptLines.Quantity.AsDecimal());
        PostedPurchaseReceipt.PurchReceiptLines."&Undo Receipt".Invoke();

        // [GIVEN] Find the last Purchase Receipt Line for the Item after undo.
#pragma warning disable AA0210
        PurchRcptLine.SetFilter(Quantity, '>0');
#pragma warning restore AA0210
        PurchRcptLine.FindLast();
        VerifyReleasedProdOrderLine(Item."No.", TotalQuantity, PurchRcptLine.Quantity);

        // [THEN] Verify that ILE Output Qty. matches expected
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(
            PurchRcptLine.Quantity,
            ItemLedgerEntry.Quantity,
            StrSubstNo(MustNotBeEqualLbl, ItemLedgerEntry.FieldCaption(Quantity), PurchRcptLine.Quantity, ItemLedgerEntry.TableCaption()));

        // [THEN] Verify that the Item Tracking Lines can again be updated in Production level.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.OpenItemTrackingLines();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ItemTrackingPageHandlerWithQuantity')]
    procedure UndoFirstReceiptInSubcontractingPurchaseOrder_WithTracking()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        WorkCenter: Record "Work Center";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
        FirstReceiptQty: Decimal;
        SecondReceiptQty: Decimal;
        TotalQuantity: Decimal;
        MustNotBeEqualLbl: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field, %2 = Expected Value, %3 = Table';
    begin
        // [SCENARIO 615586] Undoing first receipt on a subcontracting purchase order with item tracking should only reverse that receipt
        Initialize();

        // [GIVEN] Create an Item with Item Tracking.
        CreateItemWithItemTrackingCode(Item);

        // [GIVEN] Create Routing and Update Item for Subcontracting.
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        TotalQuantity := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", TotalQuantity, '', '');

        // [GIVEN] Determine quantities for first and second receipts.
        FirstReceiptQty := LibraryRandom.RandIntInRange(6, 9);
        SecondReceiptQty := TotalQuantity - FirstReceiptQty;

        // [GIVEN] Assign Tracking on Prod. Order Line before first receipt.
        LibraryVariableStorage.Enqueue(FirstReceiptQty);
        AssignTrackingOnProdOrderLine(ProductionOrder."No.");

        // [GIVEN] Calculate Subcontracting and create Purchase Order.
        CalculateSubcontractOrder(WorkCenter);
        AcceptActionMessage(RequisitionLine, Item."No.");
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // [GIVEN] Post Purchase Order with first partial receipt.
        FindPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.Validate("Qty. to Receive", FirstReceiptQty);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Verify Prod. Order Line after first receipt.
        VerifyReleasedProdOrderLine(Item."No.", TotalQuantity, FirstReceiptQty);

        // [GIVEN] Assign Tracking on Prod. Order Line before second receipt.
        LibraryVariableStorage.Enqueue(SecondReceiptQty);
        AssignTrackingOnProdOrderLine(ProductionOrder."No.");

        // [GIVEN] Post Purchase Order with second partial receipt.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", SecondReceiptQty);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        VerifyReleasedProdOrderLine(Item."No.", TotalQuantity, TotalQuantity);

        // [WHEN] Undo the selected second receipt
#pragma warning disable AA0210
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", Item."No.");
#pragma warning restore AA0210
        PurchRcptLine.FindFirst();

        PurchRcptHeader.Get(PurchRcptLine."Document No.");
        PostedPurchaseReceipt.OpenEdit();
        PostedPurchaseReceipt.GoToRecord(PurchRcptHeader);
        PostedPurchaseReceipt.PurchReceiptLines.GoToRecord(PurchRcptLine);

        // [GIVEN] Enqueue the Quantity to be used in Item Tracking Page Handler.
        LibraryVariableStorage.Enqueue(PostedPurchaseReceipt.PurchReceiptLines.Quantity.AsDecimal());
        PostedPurchaseReceipt.PurchReceiptLines."&Undo Receipt".Invoke();

        // [GIVEN] Find the last Purchase Receipt Line for the Item after undo.
#pragma warning disable AA0210
        PurchRcptLine.SetFilter(Quantity, '>0');
#pragma warning restore AA0210
        PurchRcptLine.FindLast();
        VerifyReleasedProdOrderLine(Item."No.", TotalQuantity, PurchRcptLine.Quantity);

        // [THEN] Verify that ILE Output Qty. matches expected
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(
            PurchRcptLine.Quantity,
            ItemLedgerEntry.Quantity,
            StrSubstNo(MustNotBeEqualLbl, ItemLedgerEntry.FieldCaption(Quantity), PurchRcptLine.Quantity, ItemLedgerEntry.TableCaption()));

        // [THEN] Verify that the Item Tracking Lines can again be updated in Production level.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.OpenItemTrackingLines();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Subc SCM Prod. Order");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Subc SCM Prod. Order");

        LibrarySetupStorage.Save(Database::"Inventory Setup");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        CreateLocationSetup();
        LibraryERMCountryData.UpdateInventoryPostingSetup();
        ItemJournalSetup();
        ConsumptionJournalSetup();
        OutputJournalSetup();
        ShopCalendarMgt.ClearInternals(); // clear single instance codeunit vars to avoid influence of other test codeunits

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Subc SCM Prod. Order");
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateLocationWMS(LocationRed, true, false, false, false, false);  // Location Red.
        LibraryWarehouse.CreateLocationWMS(LocationBlue, false, false, false, false, false);  // Location Blue.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationBlue.Code, false);
        LibraryWarehouse.CreateNumberOfBins(LocationRed.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value required for number of Bins.
        LibraryWarehouse.CreateLocationWMS(LocationSilver, true, true, true, false, false);  // Location Silver.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, false);
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value required for Number of Bins.
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure ConsumptionJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type, ConsumptionItemJournalTemplate.Name);
    end;

    local procedure OutputJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Item.
        CreateItem(Item2);

        // Create Production BOM, Parent Item and attach Production BOM.
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, QuantityPer);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Item Tracking Code", CreateItemTrackingCode());
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center"; IsSubcontracted: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        if IsSubcontracted then
            WorkCenter.Validate("Subcontractor No.", LibraryPurchase.CreateVendorNo());
        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateRoutingAndUpdateItemSubc(var Item: Record Item; var WorkCenter: Record "Work Center"; IsSubcontracted: Boolean): Code[10]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
    begin
        CreateWorkCenter(WorkCenter, IsSubcontracted);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLink.FindFirst();
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);

        // Certify Routing after Routing lines creation.
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // Update Routing No on Item.
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
        exit(RoutingLine."Routing Link Code");
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, SourceNo, Quantity, LocationCode, BinCode);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure SetupUoMTest(
        var Item: Record Item;
        var ItemUOM: Record "Item Unit of Measure";
        var BaseUOM: Record "Unit of Measure";
        var NonBaseUOM: Record "Unit of Measure";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", BaseUOM.Code, 1);
        ItemUOM."Qty. Rounding Precision" := QtyRoundingPrecision;
        ItemUOM.Modify();
        Item.Validate("Base Unit of Measure", ItemUOM.Code);
        Item.Modify();
        if NonBaseQtyPerUOM = 0 then
            exit;
        LibraryInventory.CreateUnitOfMeasureCode(NonBaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", NonBaseUOM.Code, NonBaseQtyPerUOM);
    end;

    local procedure CreateProdOrderAndLineForUoMTest(
        var ProductionOrder: Record "Production Order";
        var ProductionOrderLine: Record "Prod. Order Line";
        Item: Record Item;
        ProductionOrderQty: Decimal;
        ProductionOrderLineUOM: Record "Unit of Measure";
        ProductionOrderLineQty: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder,
                                                   ProductionOrder.Status::Released,
                                                   ProductionOrder."Source Type"::Item,
                                                   Item."No.",
                                                   ProductionOrderQty);
        LibraryManufacturing.CreateProdOrderLine(ProductionOrderLine,
                                                 ProductionOrderLine.Status::Released,
                                                 ProductionOrder."No.",
                                                 Item."No.",
                                                 '',
                                                 '',
                                                 0);
        ProductionOrderLine.Validate("Unit of Measure Code", ProductionOrderLineUOM.Code);
        ProductionOrderLine.Validate(Quantity, ProductionOrderLineQty);
        ProductionOrderLine.Modify(true);
    end;

    local procedure AcceptActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
    end;

    local procedure FindReleasedProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    local procedure VerifyPurchaseLine(No: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; Quantity: Decimal; ReservationStatus: Enum "Reservation Status"; LocationCode: Code[10])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, Quantity);
        ReservationEntry.TestField("Reservation Status", ReservationStatus);
        ReservationEntry.TestField("Lot No.");
        ReservationEntry.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyValueEntrySource(ProdOrderNo: Code[20]; SourceNo: Code[20]; SourceType: Enum "Analysis Source Type")
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Order No.", ProdOrderNo);
        ValueEntry.FindSet();
        repeat
            Assert.AreEqual(SourceType, ValueEntry."Source Type", StrSubstNo(ValueEntrySourceTypeErr, SourceType));
            Assert.AreEqual(SourceNo, ValueEntry."Source No.", StrSubstNo(ValueEntrySourceNoErr, SourceNo));
        until ValueEntry.Next() = 0;
    end;

    // Guarded local helpers (were in #if not CLEAN29)

    local procedure MockSubcontractedJournalLine(var ItemJournalLine: Record "Item Journal Line")
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.Init();
        WorkCenter."No." := LibraryUtility.GenerateGUID();
        WorkCenter."Subcontractor No." := LibraryUtility.GenerateGUID();
        WorkCenter.Insert();

        ItemJournalLine.Init();
        LibraryUtility.GetNewRecNo(ItemJournalLine, ItemJournalLine.FieldNo("Line No."));
        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Output;
        ItemJournalLine.Type := ItemJournalLine.Type::"Work Center";
        ItemJournalLine."Work Center No." := WorkCenter."No.";
        ItemJournalLine.Insert();
    end;

    local procedure AssignTrackingOnProdOrderLine(ProdOrderNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.OpenItemTrackingLines();  // Invokes ItemTrackingPageHandler.
    end;

    local procedure CalculateSubcontractOrder(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.SetRange("No.", WorkCenter."No.");
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);
    end;

    local procedure FindPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure PostPurchaseOrderAsShip(ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Ship only.
    end;

    local procedure PostPurchaseOrder(ItemNo: Code[20]; ShipReceive: Boolean; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        if Invoice and (PurchaseHeader."Vendor Invoice No." = '') then
            PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, ShipReceive, Invoice);
    end;

    local procedure FindAndUndoPurcReceiptLine(ItemNo: Code[20]): Code[20]
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
#pragma warning disable AA0210
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
#pragma warning restore AA0210
        PurchRcptLine.FindFirst();

        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
        exit(PurchRcptLine."Document No.");
    end;

    local procedure CreateAndPostSubcontractingPurchaseOrder(WorkCenter: Record "Work Center"; ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        CalculateSubcontractOrder(WorkCenter);
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
        FindPurchaseOrderLine(PurchaseLine, ItemNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchaseHeader.Modify();
        PurchaseLine."Direct Unit Cost" := LibraryRandom.RandInt(5);
        PurchaseLine.Modify();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure UndoPurchReceiptWithProductionSubcontracting(ItemWithTracking: Boolean; DoInvoiceSubcontracting: Boolean; DoConsumeOutputBeforeUndo: Boolean)
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        DocumentNo: Code[20];
    begin
        // [GIVEN] Setup: Create Item with Routing. Create and refresh Released Production Order.
        Initialize();
        if ItemWithTracking then
            CreateItemWithItemTrackingCode(Item)
        else
            CreateItem(Item);
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, true);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        if ItemWithTracking then
            AssignTrackingOnProdOrderLine(ProductionOrder."No.");  // Assign Lot Tracking on Prod. Order Line.

        // [GIVEN] Calculate Subcontracting
        CalculateSubcontractOrder(WorkCenter);  // Calculate Subcontracts from Subcontracting worksheet.
        AcceptActionMessage(RequisitionLine, Item."No."); // Accept and Carry Out Action Message on Subcontracting Worksheet.
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);

        // [GIVEN] Post Purchase Order
        PostPurchaseOrder(Item."No.", true, DoInvoiceSubcontracting);
        VerifyReleasedProdOrderLine(Item."No.", ProductionOrder.Quantity, ProductionOrder.Quantity); // Verify that Finished Quantity on Prod. Order Line exist after Purchase Order posting.

        if DoConsumeOutputBeforeUndo then
            LibraryInventory.PostNegativeAdjustment(Item, '', '', '', ProductionOrder.Quantity / 2, WorkDate(), LibraryRandom.RandDec(100, 2));

        // [WHEN] Undo Purchase Receipt.
        DocumentNo := FindAndUndoPurcReceiptLine(Item."No.");

        // [THEN] Verify that Finished Quantity on Prod. Order Line is 0 after Undo Purchase Receipt.
        VerifyReleasedProdOrderLine(Item."No.", ProductionOrder.Quantity, 0);

        // [THEN] Verify that ILE Output Qty. is 0 after Undo Purchase Receipt.
        VerifyOutputItemLedgerEntryAfterUndo(Item."No.", 0);

        // [THEN] Verify that CapacityLE are reversed after Undo Purchase Receipt.
        VerifyCapacityLedgerEntryAfterUndo(DocumentNo, Item."No.");
    end;

    local procedure UpdatePurchaseHeaderVATBusPostingGroup(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("VAT Bus. Posting Group", GetDifferentVATBusPostingGroup(PurchaseHeader."VAT Bus. Posting Group"));
        PurchaseHeader.Modify(true);
    end;

    local procedure GetDifferentVATBusPostingGroup(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', VATBusPostingGroupCode);
        VATPostingSetup.FindLast();
        exit(VATPostingSetup."VAT Bus. Posting Group");
    end;

    local procedure VerifyRequisitionLineForSubcontract(ProductionOrder: Record "Production Order"; WorkCenter: Record "Work Center"; ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.TestField("Prod. Order No.", ProductionOrder."No.");
        RequisitionLine.TestField(Quantity, ProductionOrder.Quantity);
        RequisitionLine.TestField("Work Center No.", WorkCenter."No.");
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
    end;

    local procedure VerifyReleasedProdOrderLine(ItemNo: Code[20]; Quantity: Decimal; FinishedQuantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindReleasedProdOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField(Quantity, Quantity);
        ProdOrderLine.TestField("Finished Quantity", FinishedQuantity);
    end;

    local procedure VerifyOutputItemLedgerEntryAfterUndo(ItemNo: Code[20]; ExpectedQty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetCurrentKey("Entry Type", "Item No.");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.CalcSums(Quantity);
        ItemLedgerEntry.TestField(Quantity, ExpectedQty);
    end;

    local procedure VerifyCapacityLedgerEntryAfterUndo(DocumentNo: Code[20]; ItemNo: Code[20])
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
        CapacityLedgerEntry.SetRange("Document No.", DocumentNo);
        CapacityLedgerEntry.SetRange("Item No.", ItemNo);
        CapacityLedgerEntry.CalcSums(Quantity, "Output Quantity", "Invoiced Quantity");

        CapacityLedgerEntry.TestField(Quantity, 0);
        CapacityLedgerEntry.TestField("Output Quantity", 0);
        CapacityLedgerEntry.TestField("Invoiced Quantity", 0);
    end;

    local procedure VerifyRecreatedPurchaseLine(PurchaseLine: Record "Purchase Line"; VATBusPostingGroupCode: Code[20])
    var
        RecreatedPurchaseLine: Record "Purchase Line";
    begin
        RecreatedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        RecreatedPurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        RecreatedPurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        RecreatedPurchaseLine.FindFirst();
        // Cannot use GET because one of the key fields "Line No." could be changed while line recreation
        RecreatedPurchaseLine.TestField(Description, PurchaseLine.Description);
        RecreatedPurchaseLine.TestField("Unit Cost (LCY)", PurchaseLine."Unit Cost (LCY)");
        RecreatedPurchaseLine.TestField("Gen. Prod. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        RecreatedPurchaseLine.TestField("VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        RecreatedPurchaseLine.TestField("Qty. per Unit of Measure", PurchaseLine."Qty. per Unit of Measure");
        RecreatedPurchaseLine.TestField("Expected Receipt Date", PurchaseLine."Expected Receipt Date");
        RecreatedPurchaseLine.TestField("Requested Receipt Date", PurchaseLine."Requested Receipt Date");
        RecreatedPurchaseLine.TestField("VAT Bus. Posting Group", VATBusPostingGroupCode);
    end;

    // Handler procedures

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingPageHandlerWithQuantity(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(ConfirmMessage, ExpectedMessage), ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalSubcontractedPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.First();
        Assert.AreEqual(0, ProductionJournal."Output Quantity".AsDecimal(), ProdJournalOutQtyErr);
    end;
}