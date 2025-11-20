// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Journal;
using Microsoft.Warehouse.Journal;
using System.TestLibraries.Utilities;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Item;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Ledger;
using Microsoft.Sales.Document;
using Microsoft.Inventory.Requisition;
using Microsoft.Purchases.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Family;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Manufacturing.Journal;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Routing;
using Microsoft.Inventory.Availability;
using Microsoft.Warehouse.Setup;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Foundation.UOM;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Pricing.PriceList;
using System.Utilities;
using Microsoft.Inventory.Costing;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Planning;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Foundation.Enums;
using Microsoft.Warehouse.Request;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Asset;

codeunit 137079 "SCM Production Order III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Production Order] [SCM]
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
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ShopCalendarMgt: Codeunit "Shop Calendar Management";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        IsInitialized: Boolean;
        ItemJournalLineExistErr: Label 'There is no Item Journal Line within the filter.';
        TrackingMsg: Label 'The change will not affect existing entries';
        ItemTrackingErr: Label 'You cannot define item tracking on this line because it is linked to production order';
        StartingDateMsg: Label 'Starting Date must be less or equal.';
        EndingDateMsg: Label 'Ending Date must be greater or equal.';
        PickActivitiesCreatedMsg: Label 'Number of Invt. Pick activities created';
        PutawayActivitiesCreatedMsg: Label 'Number of Invt. Put-away activities created';
        InboundWhseRequestCreatedMsg: Label 'Inbound Whse. Requests are created.';
        UnadjustedValueEntriesNotCoveredMsg: Label 'Some unadjusted value entries will not be covered with the new setting. You must run the Adjust Cost - Item Entries batch job once to adjust these.';
        ChangeExpectedCostPostingToGLMsg: Label 'If you enable the Expected Cost Posting to G/L, the program must update table Post Value Entry to G/L.';
        ExpectedCostPostingChangedMsg: Label 'Expected Cost Posting to G/L has been changed to Yes. You should now run Post Inventory Cost to G/L.';
        PostJournalLinesConfirmationMsg: Label 'Do you want to post the journal lines';
        JournalLinesPostedMsg: Label 'The journal lines were successfully posted.';
        RecreatePurchaseLineConfirmHandlerQst: Label 'If you change %1, the existing purchase lines will be deleted and new purchase lines based on the new information in the header will be created.\\Do you want to continue?';
        WHHandlingIsRequiredErr: Label 'Warehouse handling is required for Entry Type = Output';
        QtyPickedBaseErr: Label 'Qty. Picked (Base) must not be 0 in Prod. Order Component';
        ItemTrackingMode: Option AssignLotNo,AssignSerialNo,SelectEntries,SetValue,UpdateQuantityBase,SetNewValue;
        LeaveProductionJournalQst: Label 'Do you want to leave the Production Journal?';
        QtyToHandleBaseInTrackingErr: Label 'It must be %1.';
        ProdOrderLineBinCodeErr: Label 'Wrong "Prod. Order Line" BinCode value';
        ItemSubstCountErr: Label 'Wrong Item Substitution''s count.';
        ItemSubstDublicationErr: Label 'Duplicated Substitution Item is found.';
        ItemSubstItemNoErr: Label 'Wron Item Substitution No.';
        ValueEntrySourceTypeErr: Label 'Value Entry Source Type must be equal to %1';
        ValueEntrySourceNoErr: Label 'Value Entry Source No must be equal to %1';
        ProdJournalOutQtyErr: Label 'Output Quantity should be 0 in Production Journal Line linked to Subcontracted Workcenter';
        ComponentsAlreadyPickedQst: Label 'Components for production order %1 have already been picked. Do you want to continue?', Comment = 'Production order no.: Components for production order 101001 have already been picked. Do you want to continue?';
        SubcItemJnlErr: Label '%1 must be zero', Comment = '%1 - "Subcontractor No."';
        RtngLineBinCodeErr: Label 'Wrong %1 in %2.', Comment = '%1: Field(To-Production Bin Code), %2: TableCaption(Prod. Order Routing Line)';
        QuantityImbalanceErr: Label 'out of balance';
        InvalidPrecisionErr: Label 'field to be incorrect';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        MissingReleasedProductionErr: Label 'Production Order %1 is already Finished, you cannot reverse this entry.', Comment = '%1 = Production Order No.';
        CannotHandleEntryTypeErr: Label 'Cannot handle entry type %1 for correction posting of production.', Comment = '%1 - Entry Type';
        ActionShouldNotBeVisibleErr: Label 'Reverse Production Order Transaction should not be visible in Page %1', Comment = '%1 = Page Caption';
        ActionShouldBeVisibleErr: Label 'Reverse Production Order Transaction should be visible in Page %1', Comment = '%1 = Page Caption';
        EntryMustBeEqualErr: Label '%1 must be equal to %2 for Entry No. %3 in the %4.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Entry No., %4 = Table Caption';
        MissingAccountTxt: Label '%1 is missing in %2.', Comment = '%1 = Field Caption, %2 = Table Caption';
        ProductionOrderHasAlreadyBeenReopenedErr: Label 'This production order has already been reopened before. This can only be done once.';
        ReservationEntryMustExistErr: Label '%1 must exist.', Comment = '%1 is Table Caption';
        ItemMustBeEqualErr: Label '%1 must be equal to %2 for Item No. %3 in the %4.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Item No., %4 = Table Caption';
        CannotReverseLastOperationErr: Label '%1 %2 is the last operation of Production Order %3. Reversal of this operation can only be performed from the %4.', Comment = '%1 - Field Caption, %2 - Entry No., %3 - Production Order No., %4 - Item Ledger Entry table caption';
        CannotReverseCapacityLedgerEntryErr: Label 'You cannot reverse %1 No. %2 because the entry has already been involved in a reversal.', Comment = '%1 = Table Caption, %2 = Entry No.';

    [Test]
    [Scope('OnPrem')]
    procedure PostConsumptionForReleasedProductionOrderWithLocationAndBin()
    begin
        // Verify Consumption Entry after post Consumption for the Child Item for Released Production Order.
        // Setup.
        Initialize();
        PostJournalsForReleasedProductionOrderWithLocationAndBin(false);  // Post Output FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialOutputForReleasedProductionOrderWithLocationAndBin()
    begin
        // Verify Output Entry after post Output of the Parent Item for Released Production Order.
        // Setup.
        Initialize();
        PostJournalsForReleasedProductionOrderWithLocationAndBin(true);  // Post Output TRUE.
    end;

    local procedure PostJournalsForReleasedProductionOrderWithLocationAndBin(PostOutput: Boolean): Record "Production Order"
    var
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseEntry: Record "Warehouse Entry";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
        QuantityPer: Integer;
    begin
        // Update Components at Location. Create Parent and Child Items in a Production BOM and certify it. Update Inventory for the Child Item. Create and refresh a Released Production Order.
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationRed.Code);
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        QuantityPer := LibraryRandom.RandInt(5);
        Quantity := LibraryRandom.RandInt(10);
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity + 100, LocationRed.Code, Bin.Code);  // More Component Item required for Production Item.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, LocationRed.Code, Bin.Code);

        // Exercise: Calculate and post Consumption Journal. Create and post Output Journal.
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");
        if PostOutput then
            CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", Quantity / 2);  // Post partial Quantity.

        // Verify: Verify the partial Output Quantity and Location for the Parent Item in Item Ledger Entry and Warehouse Entry. Verify Consumption Quantity and Location for the Child Item in Item Ledger Entry and Warehouse Entry.
        if PostOutput then begin
            VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, Item."No.", Quantity / 2, LocationRed.Code);
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::"Positive Adjmt.", ProductionOrder."No.", Item."No.", Bin.Code, LocationRed.Code, Quantity);
        end else begin
            VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Consumption, ChildItem."No.", -Quantity * QuantityPer, LocationRed.Code);
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::"Negative Adjmt.", ProductionOrder."No.", ChildItem."No.", Bin.Code, LocationRed.Code,
              -Quantity * QuantityPer);
        end;

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);

        exit(ProductionOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorPostConsumptionForAlreadyConsumedComponentItemWithLocation()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
        QuantityPer: Integer;
    begin
        // Setup: Update Components at a Location. Create Parent and Child Items in a Production BOM and certify it. Update Inventory for the Child Item. Create and refresh a Released Production Order.
        Initialize();
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationRed.Code);
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        QuantityPer := LibraryRandom.RandInt(5);
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        Quantity := LibraryRandom.RandInt(10);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity + 100, LocationRed.Code, Bin.Code);  // More Component Item required for Production Item.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, LocationRed.Code, Bin.Code);
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");  // Calculate and post Consumption.

        // Exercise: Create and post Consumption Journal.
        asserterror CalculateAndPostConsumptionJournal(ProductionOrder."No.");

        // Verify: Verify the error post Consumption for the already Consumed Item with Location.
        Assert.ExpectedError(ItemJournalLineExistErr);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorPostConsumptionForAlreadyConsumedComponentItemWithoutLocation()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
        QuantityPer: Integer;
        ComponentsAtLocation: Code[10];
    begin
        // Setup: Update Components at blank Location. Create Parent and Child Items in a Production BOM and certify it. Update Inventory for the Child Item. Create and refresh a Released Production Order.
        Initialize();
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation('');  // Using blank Location.
        Quantity := LibraryRandom.RandInt(10);
        QuantityPer := LibraryRandom.RandInt(5);
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity + 100, '', '');  // More Component Item required for Production Item.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, '', '');
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");  // Calculate and post Consumption.

        // Exercise: Calculate and post Consumption Journal.
        asserterror CalculateAndPostConsumptionJournal(ProductionOrder."No.");

        // Verify: Verify the error post Consumption for the already Consumed Item without Location.
        Assert.ExpectedError(ItemJournalLineExistErr);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForMultiLineSalesWithFirmPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Craete Item. Update Order Tracking Policy on Item. Create and release Sales Order with multiple Sales Lines.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateOrderTrackingPolicyOnItem(Item, Item."Order Tracking Policy"::"Tracking & Action Msg.");
        CreateAndReleaseSalesOrderWithMultipleLines(SalesHeader, Item."No.", Quantity);

        // Exercise: Create and refresh a Firm Planned Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", Quantity, '', '');

        // Verify: Verify the ItemNo and Quantity on Order Tracking Page.
        VerifyOrderTrackingForProductionOrder(Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForMultiLineSalesWithFirmPlannedProdOrderCalcRegenPlanAndCarryOut()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Update Order Tracking Policy on Item. Update Planning parameters on Item.
        Initialize();
        CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateOrderTrackingPolicyOnItem(Item, Item."Order Tracking Policy"::"Tracking & Action Msg.");
        UpdateItemParametersForPlanning(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::"Lot-for-Lot");

        // Create and release Sales Order with multiple Lines, Calculate Regenerative Plan on WORKDATE.
        CreateAndReleaseSalesOrderWithMultipleLines(SalesHeader, Item."No.", Quantity);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Exercise: Accept and Carry Out Action Message.
        AcceptAndCarryOutActionMessageForPlanningWorksheet(Item."No.");

        // Verify: Verify the ItemNo and Quantity on Order Tracking Page.
        VerifyOrderTrackingForProductionOrder(Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineAfterCalcPlanReqWkshWithMaximumQuantityItemForEqualDemand()
    begin
        // Verify the Due Date, Action Message and Quantity on Requisition Line created for Maximum Quantity Item.
        // Setup.
        Initialize();
        CalcPlanReqWkshWithMaximumQuantityItemForEqualDemand(false);  // Accept and Carry Out Action FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineAfterCalcPlanReqWkshWithMaximumQuantityItemForEqualDemand()
    begin
        // Verify the Quantity on Purchase Line created for Maximum Quantity Item after Calc. Plan and Carry Out Action.
        // Setup.
        Initialize();
        CalcPlanReqWkshWithMaximumQuantityItemForEqualDemand(true);  // Accept and Carry Out Action TRUE.
    end;

    local procedure CalcPlanReqWkshWithMaximumQuantityItemForEqualDemand(AcceptAndCarryOutAction: Boolean)
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        InventorySetup: Record "Inventory Setup";
    begin
        // Create item with Reordering Policy. Create and post Purchase Order. Create and post Sales Order with Item Maximum Quantity.
        CreateMaximumQtyItem(Item, LibraryRandom.RandDec(100, 2) + 100);  // Large Quantity required for Item Maximum Inventory.
        CreateAndPostPurchaseOrderAsReceive(PurchaseHeader, Item."No.", Item."Maximum Inventory");
        CreateAndPostSalesOrderAsShip(Item, Item."Maximum Inventory");

        // Exercise: Calculate Plan for Requisition Worksheet on WORKDATE. Accept and Carry Out Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);
        if AcceptAndCarryOutAction then
            AcceptAndCarryOutActionMessageForRequisitionWorksheet(Item."No.");

        // Verify: Verify Quantity on Purchase Line created. Verify the Due Date, Action Message and Quantity on Requisition Line created.
        if AcceptAndCarryOutAction then
            VerifyPurchaseLine(Item."No.", Item."Maximum Inventory")
        else begin
            InventorySetup.Get();
            VerifyRequisitionLine(
              Item."No.", RequisitionLine."Action Message"::New, Item."Maximum Inventory",
              CalcDate(InventorySetup."Default Safety Lead Time", WorkDate()));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineAfterCalcPlanOnPlanWkshForDemandFromBlanketOrderWithLocation()
    begin
        // Verify the Requisition Line after Calculate Plan on Planning Worksheet with demand generated from Blanket Order with Location.
        // Setup.
        Initialize();
        CalcPlanOnPlanWkshForDemandFromBlanketOrderWithLocation(false);  // Accept and Carry Out FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderLineAfterAcceptAndCarryOutPlanWkshForDemandFromBlanketOrderWithLocation()
    begin
        // Verify the Prod. Order Line after Calculate Plan and Carry Out on Planning Worksheet with demand generated from Blanket Order with Location.
        // Setup.
        Initialize();
        CalcPlanOnPlanWkshForDemandFromBlanketOrderWithLocation(true);  // Accept and Carry Out TRUE.
    end;

    local procedure CalcPlanOnPlanWkshForDemandFromBlanketOrderWithLocation(AcceptAndCarryOut: Boolean)
    var
        Item: Record Item;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        OldStockoutWarning: Boolean;
        OldCreditWarnings: Option;
        Quantity: Integer;
    begin
        // Update Sales and Receivables setup. Create Item with Planning parameters with Reordering Policy of Lot for Lot. Create Sales Order from Blanket Order.
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, false, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateItem(Item);
        UpdateItemParametersForPlanning(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::"Lot-for-Lot");
        Quantity := LibraryRandom.RandInt(10);
        CreateSalesOrderFromBlanketOrder(SalesHeader, SalesOrderHeader, Item."No.", Quantity, LocationBlue.Code);

        // Exercise: Calculate Regenerative Plan on WORKDATE for Planning Worksheet. Accept and Carry Out Action Message.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        if AcceptAndCarryOut then
            AcceptAndCarryOutActionMessageForPlanningWorksheet(Item."No.");

        // Verify: Verify the Quantity, Due Date and Location Code on Prod. Order Line created. Verify the Quantity and Location Code and Action Message on Requisition Line.
        if AcceptAndCarryOut then
            VerifyProdOrderLine(Item."No.", LocationBlue.Code, Quantity, WorkDate())
        else
            VerifyRequisitionLineWithLocation(Item."No.", Quantity, LocationBlue.Code, RequisitionLine."Action Message"::New);

        // Tear Down.
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, OldStockoutWarning, OldCreditWarnings);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineAfterCalcPlanTwiceOnPlanWkshForDemandFromBlanketOrderWithLocation()
    var
        Item: Record Item;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        OldStockoutWarning: Boolean;
        OldCreditWarnings: Option;
        Quantity: Integer;
    begin
        // Setup: Update Sales and Receivables setup. Create Item with Planning parameters with Reordering Policy of Lot for Lot. Create Sales Order from Blanket Order.
        Initialize();
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, false, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateItem(Item);
        UpdateItemParametersForPlanning(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::"Lot-for-Lot");
        Quantity := LibraryRandom.RandInt(10);
        CreateSalesOrderFromBlanketOrder(SalesHeader, SalesOrderHeader, Item."No.", Quantity, LocationBlue.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());  // Calculate Regenerative Plan on WORKDATE.
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false); // Post Sales Order as Ship only.

        // Exercise: Calculate Regenerative Plan on WORKDATE for Planning Worksheet after posting Sales Order.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify the Quantity and Location Code and Action Message on Requisition Line.
        VerifyRequisitionLineWithLocation(Item."No.", Quantity, LocationBlue.Code, RequisitionLine."Action Message"::New);

        // Tear Down.
        UpdateSalesReceivablesSetup(OldStockoutWarning, OldCreditWarnings, OldStockoutWarning, OldCreditWarnings);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineAfterCalcPlanOnPlanWkshForSalesOrderWithUpdatedBlanketOrderNoWithLocation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineBlanket: Record "Sales Line";
        SalesOrderHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        Quantity: Integer;
    begin
        // Setup: Create Item with Planning parameters with Reordering Policy of Lot for Lot. Create a Blanket Order.
        Initialize();
        CreateItem(Item);
        UpdateItemParametersForPlanning(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Lot-for-Lot");
        Quantity := LibraryRandom.RandInt(10);
        CreateBlanketOrder(SalesHeader, Item."No.", Quantity, '');

        // Create Sales Order. Update Blanket Order No and Location Code on Sales Order.
        CreateSalesOrder(SalesOrderHeader, Item."No.", Quantity, false);  // Multiple Sales Lines FALSE.
        SelectSalesOrderLine(SalesLine, SalesOrderHeader."No.");

        LibrarySales.FindFirstSalesLine(SalesLineBlanket, SalesHeader);
        UpdateBlanketOrderNoAndLocationOnSalesLine(SalesLine, SalesLineBlanket, LocationBlue.Code);

        // Exercise: Calculate Regenerative Plan for Planning Worksheet on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify the Quantity and Location Code and Action Message on Requisition Line.
        VerifyRequisitionLineWithLocation(Item."No.", Quantity, LocationBlue.Code, RequisitionLine."Action Message"::New);
    end;

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
    [HandlerFunctions('ItemTrackingPageHandler')]
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
    [Scope('OnPrem')]
    procedure StartingDateOnProdOrderRoutingLineForReleasedProdOrderSchedulingBack()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Setup: Create Item. Create Routing Setup and update Routing on Item. Create a Released Production Order.
        Initialize();
        CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(100, 2));

        // Exercise: Refresh Released Production Order with Scheduling Direction Back.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify that the Starting Date is less than or equal to the Due Date on Production Order Routing Line.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        Assert.IsTrue(ProdOrderRoutingLine."Starting Date" <= ProductionOrder."Due Date", StartingDateMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EndingDateOnProdOrderRoutingLineForReleasedProdOrderSchedulingForward()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Setup: Create parent and child Items, create Production BOM. Create Routing Setup and update Routing on Item. Create a Firm Planned Production Order.
        Initialize();
        CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(100, 2) + 1000);  // Large Quantity required.

        // Exercise: Refresh Released Production Order with Scheduling Direction Forward.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);

        // Verify: Verify that the Ending Date is greater than or equal to the Due Date on Production Order Routing Line.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        Assert.IsTrue(ProdOrderRoutingLine."Ending Date" >= ProductionOrder."Due Date", EndingDateMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAmountActualAfterPostConsumptionForReleasedProductionOrder()
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify Cost Amount Actual on Production Order Statistics page after post Consumption for Released Production Order.

        // Setup.
        Initialize();
        PostJournalsForReleasedProductionOrder(false);  // Post Output FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAmountActualAfterPostConsumptionAndOutputForReleasedProductionOrder()
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify Cost Amount Actual on Production Order Statistics page after post Consumption and Output for Released Production Order.

        // Setup.
        Initialize();
        PostJournalsForReleasedProductionOrder(true);  // Post Output TRUE.
    end;

    local procedure PostJournalsForReleasedProductionOrder(PostOutput: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ComponentsAtLocation: Code[10];
        QuantityPer: Integer;
        ActualCost: Decimal;
    begin
        // Update Components at blank Location. Create Parent and Child Items in a Production BOM and certify it. Update Inventory for the Child Item. Create and refresh a Released Production Order.
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation('');
        QuantityPer := LibraryRandom.RandInt(5);
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandInt(10) + 100, '', '');  // Large Quantity required for Component Item.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // Exercise: Calculate and post Consumption Journal. Create and post Output Journal.
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");
        ActualCost := QuantityPer * (ProductionOrder.Quantity * ChildItem."Unit Cost");
        if PostOutput then begin
            CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");  // Change Production Order Status from Released to Finished.
        end;

        // Verify: Verify the Cost Amount Actual on Production Order Statistics Page.
        if PostOutput then
            VerifyCostAmountActualOnFinishedProductionOrderStatisticsPage(ProductionOrder."No.", ActualCost)
        else
            VerifyCostAmountActualOnReleasedProductionOrderStatisticsPage(ProductionOrder."No.", ActualCost);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirmPlannedProductionOrderWithFamily()
    var
        ParentItem: Record Item;
        ParentItem2: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        FamilyItemQuantity: Decimal;
    begin
        // Setup: Create parent and child Items for a Family. Update Inventory for child Items. Create a Family.
        Initialize();
        FamilyItemQuantity := LibraryRandom.RandDec(10, 2);
        CreateItemHierarchyForFamily(ParentItem, ParentItem2, ChildItem, ChildItem2, LibraryRandom.RandInt(5));
        CreateFamily(Family, ParentItem."No.", ParentItem2."No.", FamilyItemQuantity);

        // Exercise: Create and refresh a Firm Planned Production Order.
        CreateAndRefreshProductionOrderWithSourceTypeFamily(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Family."No.", FamilyItemQuantity);

        // Verify: Verify the Production Order Lines created. Production Order Quantity as calculated from Family Item Quantity.
        VerifyProdOrderLine(ParentItem."No.", '', FamilyItemQuantity * FamilyItemQuantity, WorkDate());
        VerifyProdOrderLine(ParentItem2."No.", '', FamilyItemQuantity * FamilyItemQuantity, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalCostOnFinishedProductionOrderStatisticsPageForFamily()
    var
        ParentItem: Record Item;
        ParentItem2: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        FamilyItemQuantity: Decimal;
        ActualCost: Decimal;
        QuantityPer: Decimal;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify the correct Total Actual Cost on Finished Production Order with source type Family.

        // Setup: Create parent and child Items for a Family. Update Inventory for child Items. Create a Family. Create and refresh a Released Production Order.
        Initialize();
        QuantityPer := LibraryRandom.RandInt(5);
        FamilyItemQuantity := LibraryRandom.RandInt(10);
        CreateItemHierarchyForFamily(ParentItem, ParentItem2, ChildItem, ChildItem2, QuantityPer);
        CreateFamily(Family, ParentItem."No.", ParentItem2."No.", FamilyItemQuantity);
        CreateAndRefreshProductionOrderWithSourceTypeFamily(
          ProductionOrder, ProductionOrder.Status::Released, Family."No.", FamilyItemQuantity);

        // Calculate and post Consumption and Output journals.
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", LibraryRandom.RandDec(100, 2) + 100);  // Quantity greater than FamilyItemQuantity.

        // Exercise: Change Production Order Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify the correct Total Actual Cost on Finished Production Order Statistics page.
        ActualCost :=
          QuantityPer * FamilyItemQuantity * (FamilyItemQuantity * ChildItem."Unit Cost" + FamilyItemQuantity * ChildItem2."Unit Cost");
        VerifyTotalActualCostOnFinishedProductionOrderStatisticsPage(ProductionOrder."No.", ActualCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitOfMeasureOnWhseReceiptWithLocation()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // Setup: Create Item with multiple Item Unit of Measure, create and release Purchase Order.
        Initialize();
        CreateItem(Item);
        CreateMultipleItemUnitOfMeasureSetup(Item, ItemUnitOfMeasure, ItemUnitOfMeasure2);

        // Exercise: Create Whse Receipt from Purchase Order.
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, LibraryRandom.RandDec(10, 2));

        // Verify: Verify the Unit of Measure on whse Receipt Line.
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
        WarehouseReceiptLine.TestField("Qty. per Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitOfMeasureOnWhsePutAwayWithLocation()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Setup: Create Item with multiple Item Unit of Measure. Create and release Purchase Order, create Whse Receipt.
        Initialize();
        CreateItem(Item);
        CreateMultipleItemUnitOfMeasureSetup(Item, ItemUnitOfMeasure, ItemUnitOfMeasure2);
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, LibraryRandom.RandDec(10, 2));

        // Exercise: Post Warehouse Receipt.
        PostWarehouseReceipt(PurchaseHeader."No.");

        // Verify: Verify the Put Away created with new Unit of Measure.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", LocationWhite.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        VerifyUOMOnWhseActivityLine(WarehouseActivityLine, ItemUnitOfMeasure.Code, ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewUnitOfMeasureOnWhsePickForReleasedProdOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        ChildItem: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Quantity: Decimal;
        ComponentsAtLocation: Code[10];
    begin
        // Setup: Update Components at Location. Create parent and child Items with multiple Item Unit of Measure in a Prod. BOM, create and release Purchase Order. Create and post Warehouse Receipt.
        Initialize();
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        CreateMultipleItemUnitOfMeasureSetup(ChildItem, ItemUnitOfMeasure, ItemUnitOfMeasure2);
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader, ChildItem."No.", LocationWhite.Code, Quantity);
        PostWarehouseReceipt(PurchaseHeader."No.");

        // Register the Put Away, create and refresh a Released Production Order.
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item."No.", Quantity, LocationWhite.Code, LocationWhite."To-Production Bin Code");

        // Exercise: Create Pick from Released Production Order.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // Verify: Verify that new Unit of Measure is updated on Warehouse Pick Line.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type"::Take);
        VerifyUOMOnWhseActivityLine(WarehouseActivityLine, ItemUnitOfMeasure2.Code, ItemUnitOfMeasure2."Qty. per Unit of Measure");

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewUnitOfMeasureOnRegisteredWhsePutAwayWithProductionBOM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure2: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        ChildItem: Record Item;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create parent and child Items with multiple Item Unit of Measure in a Prod. BOM, create and release Purchase Order. Create and post Warehouse Receipt.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        CreateMultipleItemUnitOfMeasureSetup(ChildItem, ItemUnitOfMeasure, ItemUnitOfMeasure2);
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader, ChildItem."No.", LocationWhite.Code, Quantity);
        PostWarehouseReceipt(PurchaseHeader."No.");

        // Exercise: Register the Put Away created.
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");

        // Verify: Verify the Unit of Measure Code updated on Registered Whse Activity Lines.
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, PurchaseHeader."No.", RegisteredWhseActivityLine."Action Type"::Take,
          RegisteredWhseActivityLine."Activity Type"::"Put-away");
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, ItemUnitOfMeasure.Code, ItemUnitOfMeasure."Qty. per Unit of Measure", Quantity);
        FindRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, PurchaseHeader."No.", RegisteredWhseActivityLine."Action Type"::Place,
          RegisteredWhseActivityLine."Activity Type"::"Put-away");
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine, ItemUnitOfMeasure2.Code, ItemUnitOfMeasure2."Qty. per Unit of Measure", Quantity / 2);  // Used for Break bulk.
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure OutputEntryOnProductionJournalForReleasedProductionOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Item. Create and refresh a Released Production Order.
        Initialize();
        CreateItem(Item);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), LocationWhite.Code,
          LocationWhite."To-Production Bin Code");

        // Exercise & Verify: Open Production Journal for the Released Production Order. Verify the Output Entry on Production Journal through ProductionJournalPageHandler.
        OpenProductionJournalPage(ProductionOrder, Item."No.", Item."No.", ProductionOrder.Quantity, ItemJournalLine."Entry Type"::Output);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure ConsumptionEntryOnProductionJournalForProductionOrderAfterCreateAndRegisterPick()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemJournalLine: Record "Item Journal Line";
        ComponentsAtLocation: Code[10];
        AlwaysCreatePickLine: Boolean;
        Quantity: Decimal;
    begin
        // Setup: Update Location Setup, update Components at Location.
        Initialize();
        AlwaysCreatePickLine := UpdateLocationSetup(LocationWhite, true);  // Always Create Pick Line as TRUE.
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);

        // Create parent and child Items in a Production BOM and certify it. Update Inventory for Child Item. Create and refresh a Released Production Order.
        // Create Warehouse Pick from the Released Production Order.
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, 1);  // Value required to avoid Bin Code mismatch.
        UpdateInventoryWithWhseItemJournal(ChildItem, LocationWhite, Quantity);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationWhite.Code,
          LocationWhite."To-Production Bin Code");
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);  // Register the Pick created.

        // Exercise & Verify: Open Production Journal for the Released Production Order. Verify the Consumption Entry on Production Journal through ProductionJournalPageHandler.
        OpenProductionJournalPage(ProductionOrder, ChildItem."No.", Item."No.", Quantity, ItemJournalLine."Entry Type"::Consumption);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
        UpdateLocationSetup(LocationWhite, AlwaysCreatePickLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickForProductionOrderWithMultipleComponents()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Update Components at a Location. Create parent and multiple components in a Production BOM and certify it. Update Inventory for component Items. Create and refresh a Released Production Order.
        Initialize();
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationSilver.Code);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        Quantity := LibraryRandom.RandInt(100);
        CreateAndCertifyProdBOMWithMultipleComponent(Item, Item2, Item3);
        UpdateComponentsInventory(Item2."No.", Item3."No.", LocationSilver.Code, Bin.Code, Quantity);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationSilver.Code, Bin.Code);

        // Exercise: Create Inventory Pick from the Released Production Order.
        LibraryVariableStorage.Enqueue(PickActivitiesCreatedMsg);  // Enqueue variable required inside MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // Verify: Verify that Inventory Pick created successfully.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationSilver.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLine(WarehouseActivityLine, Item2."No.", Quantity);
        VerifyWarehouseActivityLine(WarehouseActivityLine, Item3."No.", Quantity);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedPartialInventoryPickForProductionOrderWithMultipleComponents()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Update Components at a Location. Create parent and multiple components in a Production BOM and certify it. Update Inventory for component Items. Create and refresh a Released Production Order.
        Initialize();
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationSilver.Code);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        Quantity := LibraryRandom.RandInt(100);
        CreateAndCertifyProdBOMWithMultipleComponent(Item, Item2, Item3);
        UpdateComponentsInventory(Item2."No.", Item3."No.", LocationSilver.Code, Bin.Code, Quantity);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationSilver.Code, Bin.Code);

        // Create Inventory Pick from the Released Production Order. Update partial quantity on Inventory Pick line created.
        LibraryVariableStorage.Enqueue(PickActivitiesCreatedMsg);  // Enqueue variable required inside MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);
        UpdateQuantityOnWarehouseActivityLine(
          ProductionOrder."No.", WarehouseActivityLine."Action Type"::Take, Quantity / 2, LocationSilver.Code);
        FindWarehouseActivityHeader(
          WarehouseActivityHeader, ProductionOrder."No.", WarehouseActivityLine."Action Type"::Take, LocationSilver.Code);

        // Exercise: Post Inventory Pick.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);  // Post as Invoice False.

        // Verify: Verify that Inventory Pick posted successfully with partial Quantity.
        VerifyPostedInventoryPickLine(ProductionOrder."No.", Item2."No.", Bin.Code, Quantity / 2, LocationSilver.Code);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostConsumptionCompItemWithBackwardFlushingForReleasedProdOrderError()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
    begin
        // Setup: Create Parent and Child Items in Certified Production BOM. Update Flushing method on child Item. Update Inventory for the Child Item. Create Routing. Create and Refresh a Released Production Order.
        Initialize();
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandDec(10, 2) + 100, '', '');  // Large Component Quantity is required.
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(10, 2), '', '');

        // Exercise: Calculate and post Consumption for the child Item.
        asserterror CalculateAndPostConsumptionJournal(ProductionOrder."No.");

        // Verify: Verify the error post Consumption.
        Assert.ExpectedError(ItemJournalLineExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputAndFinishReleasedProdOrderWithComponentBackwardFlushing()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify Finished Quantity is correct on Prod. Order Line with component Flushing Method = Backward, after Prod. Order change Status from Released to Finished.

        // Setup: Create Parent and Child Items in Certified Production BOM. Update Flushing method on child Item. Update Inventory for the Child Item. Create Routing. Create and Refresh a Released Production Order.
        Initialize();
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandDec(10, 2) + 100, '', '');  // Large Component Quantity is required.
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(10, 2), '', '');
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);  // Create and post Output Journal for the Production Order.

        // Exercise: Change Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");  // Change Status from Released to Finished.

        // Verify: Verify the Finished Quantity on Prod. Order Line.
        VerifyFinishedProdOrderLine(Item."No.", ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAmountActualAfterPostNegativeOutputForProdOrderWithComponentBackwardFlushing()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Parent and Child Items in Certified Production BOM. Update Backward Flushing method on child Item. Create and post Purchase Order for Child Item. Create and Refresh a Released Production Order.
        Initialize();
        CreateProdOrderItemSetupWithOutputJournalAndExplodeRouting(Item, ChildItem, ProductionOrder, LibraryRandom.RandInt(10), LibraryRandom.RandInt(5));

        // Exercise: Post the negative Output for the Production Order.
        CreateAndPostOutputJournalWithApplyEntry(Item."No.", -ProductionOrder.Quantity);

        // Verify: Verify the Cost Amount Actual as zero for Output Entry.
        VerifyValueEntry(Item."No.", ProductionOrder."No.", ItemJournalLine."Entry Type"::Output, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostAmountActualAfterPostOutputAndFinishReleasedProdOrderWithComponentBackwardFlushing()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        BOMQtyPer: Integer;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify that Cost Amount is correct in Value Entry after Production Order post Output and change status from Released to Finished, child item has Flushing Method = Backward.

        // Setup: Create Parent and Child Items in Certified Production BOM. Update Backward Flushing method on child Item. Create and post Purchase Order for Child Item. Create and Refresh a Released Production Order.
        Initialize();
        BOMQtyPer := LibraryRandom.RandInt(5);
        CreateProdOrderItemSetupWithOutputJournalAndExplodeRouting(Item, ChildItem, ProductionOrder, LibraryRandom.RandInt(10), BOMQtyPer);

        // Exercise: Change Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify the Cost Amount Actual in Value Entry created. Verify the Cost Amount Actual as zero for Output Entry.
        VerifyValueEntry(
          ChildItem."No.", ProductionOrder."No.", ItemJournalLine."Entry Type"::Consumption,
          -ProductionOrder.Quantity * BOMQtyPer * ChildItem."Unit Cost");
        VerifyValueEntry(Item."No.", ProductionOrder."No.", ItemJournalLine."Entry Type"::Output, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitOfMeasureCodeOnProdOrderLineWithBOMVersionCode()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create parent and child Items in a Certified Production BOM. Create Certified Production BOM version with Copy Version and certify it. Create and refresh a Released Production Order.
        Initialize();
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        CreateCertifiedProductionBOMVersionWithCopyBOM(Item."Production BOM No.", Item."Base Unit of Measure");
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Exercise: Update Production BOM Version Code on Production Order Line.
        UpdateProdBOMVersionCodeOnProdOrderLine(Item);

        // Verify: Verify the Unit Of Measure Code remains same on Production Order Line when Production BOM Version Code is changed.
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");
        ProdOrderLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityPickedAfterRegisterWhsePickForProductionOrder()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        AlwaysCreatePickLine: Boolean;
        Quantity: Decimal;
    begin
        // Setup: Update Location Setup. Create parent and child Items in a Production BOM and certify it. Update Inventory for Child Item. Create and refresh a Released Production Order.
        // Create Warehouse Pick from the Released Production Order.
        Initialize();
        AlwaysCreatePickLine := UpdateLocationSetup(LocationWhite, true);  // Always Create Pick Line as TRUE.
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, 1);  // Value required to avoid Bin Code mismatch.
        UpdateInventoryWithWhseItemJournal(ChildItem, LocationWhite, Quantity);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationWhite.Code,
          LocationWhite."To-Production Bin Code");
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // Exercise: Register the Whse Pick.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify: Verify the Qty Picked and Qty Picked (Base) on Production Order Component.
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status::Released, ChildItem."No.", ProductionOrder.Quantity);

        // Tear Down.
        UpdateLocationSetup(LocationWhite, AlwaysCreatePickLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhsePickAfterRefreshProductionOrderForAlreadyPickedItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        AlwaysCreatePickLine: Boolean;
        Quantity: Decimal;
    begin
        // Setup: Update Location Setup. Create parent and child Items in a Production BOM and certify it. Update Inventory for Child Item. Create and refresh a Released Production Order.
        // Create Warehouse Pick from the Released Production Order.
        Initialize();
        AlwaysCreatePickLine := UpdateLocationSetup(LocationWhite, true);  // Always Create Pick Line as TRUE.
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, 1);  // Value required to avoid Bin Code mismatch.
        UpdateInventoryWithWhseItemJournal(ChildItem, LocationWhite, Quantity);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationWhite.Code,
          LocationWhite."To-Production Bin Code");
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // Register the Whse Pick. Refresh the Production Order again.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryVariableStorage.Enqueue(StrSubstNo(ComponentsAlreadyPickedQst, ProductionOrder."No."));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Exercise: Create Whse Pick again.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // Verify: Verify the Take and Place Pick lines created after refresh Production Order twice.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLine(WarehouseActivityLine, ChildItem."No.", ProductionOrder.Quantity);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type"::Place);
        VerifyWarehouseActivityLine(WarehouseActivityLine, ChildItem."No.", ProductionOrder.Quantity);

        // Tear Down.
        UpdateLocationSetup(LocationWhite, AlwaysCreatePickLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhsePickForReleasedProductionOrderWithItemFlushingPickAndBackward()
    begin
        // Verify the Movement Warehouse Entries created after create Whse Pick with Child Item Flushing method Pick + Backward.
        // Setup.
        Initialize();
        CreateAndRegisterWhsePickForProductionOrderWithItemFlushingPickAndBackward(false);  // Register Pick FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseEntryAfterRegisterPickForReleasedProductionOrderWithItemFlushingPickAndBackward()
    begin
        // Verify the Movement Warehouse Entries created after Register Whse Pick with Child Item Flushing method Pick + Backward.
        // Setup.
        Initialize();
        CreateAndRegisterWhsePickForProductionOrderWithItemFlushingPickAndBackward(true);  // Register Pick TRUE.
    end;

    local procedure CreateAndRegisterWhsePickForProductionOrderWithItemFlushingPickAndBackward(RegisterPick: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
        ComponentsAtLocation: Code[10];
    begin
        // Update Components at Location. Create parent and child Items in a Production BOM. Update Flushing Method on Child Item. Update Child Item Inventory. Create and refresh a Released Production Order.
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        UpdateItemFlushingMethodPickAndBackward(ChildItem);
        UpdateInventoryWithWhseItemJournal(ChildItem, LocationWhite, Quantity);
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item."No.", Quantity, LocationWhite.Code, LocationWhite."To-Production Bin Code");

        // Exercise: Create Whse Pick from Released Production Order. Register the Whse Pick created.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        if RegisterPick then
            RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityHeader.Type::Pick);

        // Verify: Verify the Movement Warehouse Entry created after Register Whse Pick. Verify the Pick created for Child Item with Pick + Backward Flushing method.
        if RegisterPick then
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, ProductionOrder."No.", ChildItem."No.", LocationWhite."Cross-Dock Bin Code",
              LocationWhite.Code, -Quantity)
        else begin
            FindWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, ProductionOrder."No.",
              WarehouseActivityLine."Action Type"::Take);
            VerifyWarehouseActivityLine(WarehouseActivityLine, ChildItem."No.", ProductionOrder.Quantity);
            FindWhseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationWhite.Code, ProductionOrder."No.",
              WarehouseActivityLine."Action Type"::Place);
            VerifyWarehouseActivityLine(WarehouseActivityLine, ChildItem."No.", ProductionOrder.Quantity);
        end;

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseEntryAfterPutAwayForReleasedProductionOrderWithItemFlushingBackward()
    begin
        // Verify the Movement Warehouse Entries created after post Whse Receipt for Item with Backward Flushing method.
        // Setup.
        Initialize();
        CreateAndRegisterWhsePutAwayForProductionOrderWithItemFlushingBackward(false);  // Register Put Away FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseEntriesAfterRegisterPutAwayForReleasedProductionOrderWithItemFlushingBackward()
    begin
        // Verify the Movement Warehouse Entries created after Register Whse Put Away for Item with Backward Flushing method.
        // Setup.
        Initialize();
        CreateAndRegisterWhsePutAwayForProductionOrderWithItemFlushingBackward(true);  // Register Put Away TRUE.
    end;

    local procedure CreateAndRegisterWhsePutAwayForProductionOrderWithItemFlushingBackward(RegisterPutAway: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
    begin
        // Create parent and child Items in a Production BOM and update Backward Flushing on child Item. Create and release Purchase Order. Create Warehouse Receipt.
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader, ChildItem."No.", LocationWhite.Code, Quantity);

        // Exercise: Post Warehouse Receipt. Register the Put Away created.
        PostWarehouseReceipt(PurchaseHeader."No.");
        if RegisterPutAway then
            RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");

        // Verify: Verify the Movement Warehouse Entries created after post Whse Receipt and Register Whse Put Away for Child Item with Backward Flushing method.
        if RegisterPutAway then
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, PurchaseHeader."No.", ChildItem."No.", LocationWhite."Receipt Bin Code",
              LocationWhite.Code, -Quantity)
        else
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::"Positive Adjmt.", PurchaseHeader."No.", ChildItem."No.", LocationWhite."Receipt Bin Code",
              LocationWhite.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,MessageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure ValueEntriesForFinishedProdOrderWithNewUOM()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        InventorySetup: Record "Inventory Setup";
        ValueEntry: Record "Value Entry";
        CostAmount: Decimal;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify that Value Entries are correct for Finished Production Order if Prod. Order Line is updated with new UOM, then Production Journal posted, then status changed from Released to Finished.

        // Setup: Create parent and child Items in a Production BOM and certify it. Update Overhead rate, Unit of measure and Quantity per unit of measure on Parent Item. Create and Post Purchase Order as Receive.
        Initialize();
        UpdateInventorySetup(InventorySetup);
        CreateItemsSetup(ParentItem, ChildItem, LibraryRandom.RandInt(5));
        UpdateItemOverheadRate(ParentItem);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ParentItem."No.", LibraryRandom.RandInt(10));
        // Max possible demand for the component item is BOMLine.Quantity * ProductionOrder.Quantity * ItemUnitOfMeasure."Quantity per Unit of Measure" = 10 * 5 * 10
        CreateAndPostPurchaseOrderWithDirectUnitCostAsReceive(PurchaseHeader, ChildItem."No.", 500);

        // Create and refresh Released Production Order and change Unit of Measure on Production Order Line.
        CreateAndRefreshProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandDec(10, 2), '', '');
        UpdateProdOrderLineUnitOfMeasureCode(ProdOrderLine, ParentItem."No.", ItemUnitOfMeasure.Code);

        // Open Production Journal and Post.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");  // Handler used -PostProductionJournalHandler.

        // Exercise: Change Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify Value Entries for Finished Production Order With Entry Type Direct Cost and Indirect Cost. Verify the Cost Amount, Cost Per Unit and Invoiced Quantity as Zero.
        CostAmount := ProdOrderLine."Overhead Rate" * ItemUnitOfMeasure."Qty. per Unit of Measure" * ProductionOrder.Quantity;
        VerifyValueEntryForEntryType(
            ValueEntry."Entry Type"::"Direct Cost", ProductionOrder."No.",
            ProductionOrder.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", 0, 0, 0, 0);
        VerifyValueEntryForEntryType(
            ValueEntry."Entry Type"::"Indirect Cost", ProductionOrder."No.", 0, CostAmount, 0, ProdOrderLine."Overhead Rate", CostAmount);
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
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithRequirePickLocationForItemWithRouting()
    begin
        // Verify production journal with negative quantity on output line can be posted with Require Pick Location for Item with routing
        PostOutputCorrectionWithRequirePickLocation(true); // TRUE indicates routing exists
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithRequirePickLocationForItemWithoutRouting()
    begin
        // Verify production journal with negative quantity on output line can be posted with Require Pick Location for Item without routing
        PostOutputCorrectionWithRequirePickLocation(false); // FALSE indicates routing doesn't exist
    end;

    local procedure PostOutputCorrectionWithRequirePickLocation(HasRouting: Boolean)
    var
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        Location: Record Location;
    begin
        // Setup: Create Production Item
        Initialize();
        LibraryInventory.CreateItem(Item);

        if HasRouting then begin
            CreateRoutingAndUpdateItem(Item, WorkCenter); // Set Routing No. for Item
            FindLastRoutingLine(RoutingLine, Item."Routing No."); // The Operation No. for last routing line is needed when posting output with negative quantity
        end;

        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false); // Create a Require-Pick Location
        // Create and refresh release Production Order with setting Location code
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), Location.Code, ''); // Set Bin Code to empty
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity); // Create and post Output Journal for the Production Order.

        // Exercise and Verify: Post output journal with negative quantity and expect the post can succeed
        CreateAndPostOutputJournalWithApplyEntryAndOperationNo(Item."No.", -ProductionOrder.Quantity, RoutingLine."Operation No.");

        // Verify: 2 Item Ledger Entries for the production item exist, one with positive quantity, one with negative quantity
        VerifyOutputItemLedgerEntry(Item."No.", ProductionOrder."Location Code", ProductionOrder.Quantity, -ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithLocationBinMandatory()
    var
        Bin: Record Bin;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Test to verify the production journal with negative quantity can be posted with Bin Mandatory Location for Item with routing.

        // Use a Bin-Mandatory Location
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);
        CreateOutputCorrectionWithLocation(Item, ProductionOrder, LocationRed.Code, Bin.Code, true);

        // Exercise and Verify: Post output journal with negative quantity and expect the post can succeed
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // Verify: 2 Item Ledger Entries for the production item exist, one with positive quantity, one with negative quantity
        VerifyOutputItemLedgerEntry(Item."No.", ProductionOrder."Location Code", ProductionOrder.Quantity, -ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithLocationRequirePickWithoutApplyToEntry()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Test to verify the error message pops up when posting production correction journal without setting Apply-to Entry using Location with Require Pick.

        // Create a Require-Pick Location and create output correct journal without "Applies-to Entry"
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);
        CreateOutputCorrectionWithLocation(Item, ProductionOrder, Location.Code, '', false);

        // Exercise and Verify: Post output journal and expect the error pops up
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        Assert.ExpectedError(WHHandlingIsRequiredErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithLocationRequirePickAndShipmentWithoutApplyToEntry()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // Test to verify the error message pops up when posting production correction journal without setting Apply-to Entry using Location with Require Pick and Require Shipment.

        // Create a Require-Pick and Require-Shipment Location and create output correct journal without "Applies-to Entry"
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);
        Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)";
        Location.Modify();
        CreateOutputCorrectionWithLocation(Item, ProductionOrder, Location.Code, '', false);

        // Exercise and Verify: Post output journal and expect the error pops up
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        Assert.ExpectedTestFieldError(ItemJnlLine.FieldCaption("Applies-to Entry"), '');
    end;

    local procedure CreateOutputCorrectionWithLocation(var Item: Record Item; var ProductionOrder: Record "Production Order"; LocationCode: Code[10]; BinCode: Code[20]; SetAppliesToEntry: Boolean)
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // Setup: Create Production Item
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter); // Set Routing No. for Item
        FindLastRoutingLine(RoutingLine, Item."Routing No."); // The Operation No. for last routing line is needed when posting output with negative quantity

        // Create and refresh release Production Order with setting Location code
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), LocationCode, BinCode);
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);

        // Create output journal with negative quantity
        CreateOutputJournalWithApplyEntryAndOperationNo(
          Item."No.", -ProductionOrder.Quantity, RoutingLine."Operation No.", SetAppliesToEntry);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithLocationRequirePickAndItemTracking()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        Location: Record Location;
    begin
        // Setup: Create a Require-Pick Location
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // Create Output Correction Journal with Location and Item Tracking.
        CreateOutputCorrectionWithLocationAndItemTracking(Item, ProductionOrder, Location.Code, true);

        // Exercise and Verify: Post output journal with negative quantity and expect the post can succeed
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // Verify: 2 Item Ledger Entries for the production item exist, one with positive quantity, one with negative quantity
        VerifyOutputItemLedgerEntry(Item."No.", ProductionOrder."Location Code", ProductionOrder.Quantity, -ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithLocationRequirePickAndItemTrackingWithoutApplyToItemEntry()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        Location: Record Location;
    begin
        // Test to verify the error message pops up when posting production correction journal without setting Apply-to Item Entry using Location with Require Pick.

        // Setup: Create a Require-Pick Location
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        // Create Output Correction Journal with Location and Item Tracking without " Apply-to Item Entry".
        CreateOutputCorrectionWithLocationAndItemTracking(Item, ProductionOrder, Location.Code, false);

        // Exercise and Verify: Post output journal and verify error pops up.
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        Assert.ExpectedError(WHHandlingIsRequiredErr);

        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithItemTrackingLooksForSoleOpenOriginalOutputEntryWithSameLotToApply()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 266675] When a user posts reversed output with lot no. and does not set an entry to apply, the program finds the sole original output with the same lot and populates "Applies-to Entry" field.

        // [GIVEN] Lot-tracked item "I".
        // [GIVEN] Released production order for "I".
        // [GIVEN] Set lot no. "L" on the output journal line and post the output of "I". Output quantity = "Q".
        // [GIVEN] Create a reversed line in the output journal with item = "I", lot no. = "L", quantity = "-Q" and blank "Applies-to Entry".
        CreateOutputCorrectionWithLocationAndItemTracking(Item, ProductionOrder, '', false);

        // [WHEN] Post the output correction.
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [THEN] The reversed output is successfully posted and applied to the original one.
        VerifyReversedOutputItemLedgerEntry(Item."No.");

        // Tear down.
        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithItemTrackingLooksForSoleOpenOriginalOutputEntryWithSameSNToApply()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 266675] When a user posts reversed output with serial no. and does not set an entry to apply, the program finds the sole original output with the same serial no. and populates "Applies-to Entry" field.
        Initialize();

        // [GIVEN] Serial no.-tracked item "I".
        LibraryItemTracking.CreateSerialItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for 1 pc of "I".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", 1, '', '');

        // [GIVEN] Set serial no. "S" on the output journal line and post the output of "I".
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrder."No.");
        ItemJournalLine.Validate(Quantity, ProductionOrder.Quantity);
        ItemJournalLine.Modify(true);
        OpenItemTrackingLines(ItemJournalLine, ItemTrackingMode::AssignSerialNo);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create a reversed line in the output journal with item = "I", serial no. = "S", quantity = -1 and blank "Applies-to Entry".
        CreateReversedOutputJournalLine(
            ItemJournalLine, ProductionOrder."No.", Item."No.", FindLastOperationNo(Item."Routing No."), -ProductionOrder.Quantity);
        OpenItemTrackingLines(ItemJournalLine, ItemTrackingMode::SelectEntries);

        // [WHEN] Post the output correction.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] The reversed output is successfully posted and applied to the original one.
        VerifyReversedOutputItemLedgerEntry(Item."No.");

        // Tear down.
        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithItemTrackingDoesNotFindEntryToApplyWhenSeveralEntriesMatch()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        LotNo: Code[50];
        i: Integer;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 266675] When a user posts reversed output with item tracking, the program does not populate "Applies-to Entry" automatically in case the original output entry cannot be selected unambiguously.
        Initialize();

        // [GIVEN] Lot-tracked item "I".
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for "2Q" pcs of the "I".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", 2 * LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Post two output entries with item "I" and lot "L", each output for "Q" pcs.
        LotNo := LibraryUtility.GenerateGUID();
        for i := 1 to 2 do begin
            CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrder."No.");
            ItemJournalLine.Validate(Quantity, ProductionOrder.Quantity / 2);
            ItemJournalLine.Modify(true);

            OpenItemTrackingLinesSetValue(ItemJournalLine, LotNo, '', ProductionOrder.Quantity / 2);
            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        end;

        // [GIVEN] Create a reversed line in the output journal with item = "I", lot no. = "L", quantity = "-Q" and blank "Applies-to Entry".
        CreateOutputJournalWithApplyEntryAndItemTracking(
          Item."No.", -ProductionOrder.Quantity / 2, FindLastOperationNo(Item."Routing No."), false);

        // [WHEN] Post the output correction.
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [THEN] "Applies-to Entry must have a value" error message is raised. The program could not unambiguously define the original entry to apply.
        Assert.ExpectedTestFieldError(ItemJournalLine.FieldCaption("Applies-to Entry"), '');

        // Tear down.
        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithItemTrackingDoesNotFindEntryToApplyWhenLotNotMatch()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 266675] When a user posts reversed output with item tracking, the program does not populate "Applies-to Entry" automatically in case item tracking in the original output does not match.
        Initialize();

        // [GIVEN] Lot-tracked item "I".
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for "I".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Set lot no. "L1" on the output journal line and post the output of "I". Output quantity = "Q".
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", ProductionOrder.Quantity);

        // [GIVEN] Create a reversed line in the output journal with item = "I", quantity = "-Q", blank "Applies-to Entry" and new lot no. = "L2".
        CreateReversedOutputJournalLine(
            ItemJournalLine, ProductionOrder."No.", Item."No.", FindLastOperationNo(Item."Routing No."), -ProductionOrder.Quantity);
        OpenItemTrackingLinesSetValue(ItemJournalLine, LibraryUtility.GenerateGUID(), '', -ProductionOrder.Quantity);

        // [WHEN] Post the output correction.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] "Applies-to Entry must have a value" error message is raised. The program could not find an output entry with lot no. "L2".
        Assert.ExpectedTestFieldError(ItemJournalLine.FieldCaption("Applies-to Entry"), '');

        // Tear down.
        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithItemTrackingDoesNotFindEntryToApplyWhenLotNotSuffice()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 266675] When a user posts reversed output with item tracking, the program does not populate "Applies-to Entry" automatically in case the remaining quantity in the original output does not suffice for full application.
        Initialize();

        // [GIVEN] Lot-tracked item "I".
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for "2Q" pcs of the "I".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", 2 * LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Set lot no. "L" on the output journal line and post the output of "I". Output quantity = "2Q".
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", ProductionOrder.Quantity);

        // [GIVEN] Create a reversed line in the output journal with item = "I", lot no. = "L", quantity = "-2Q" and blank "Applies-to Entry".
        CreateReversedOutputJournalLine(
            ItemJournalLine, ProductionOrder."No.", Item."No.", FindLastOperationNo(Item."Routing No."), -ProductionOrder.Quantity);
        OpenItemTrackingLines(ItemJournalLine, ItemTrackingMode::SelectEntries);

        // [GIVEN] Post the negative adjustment for "Q" pcs of lot "L".
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Output, Item."No.");
        CreateAndPostInvtAdjustmentOfItemWithLot(Item."No.", ItemLedgerEntry."Lot No.", -ProductionOrder.Quantity / 2);

        // [WHEN] Post the output correction.
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [THEN] "Applies-to Entry must have a value" error message is raised. The remaining quantity of the original output is now "Q" pcs, that is not enough to fully apply the reversed output for "2Q" pcs.
        Assert.ExpectedTestFieldError(ItemJournalLine.FieldCaption("Applies-to Entry"), '');

        // Tear down.
        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputCorrectionWithItemTrackingDoesNotFindEntryToApplyWhenProdOrderLineNotMatch()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        i: Integer;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 266675] When a user posts reversed output with item tracking, the program does not populate "Applies-to Entry" automatically in case the original output was posted for a different prod. order line.
        Initialize();

        // [GIVEN] Lot-tracked item "I".
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for "2Q" pcs of the "I".
        // [GIVEN] The production order has two prod. order lines "POL1", "POL2", each for "Q" pcs.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", 2 * LibraryRandom.RandInt(10));
        for i := 1 to ArrayLen(ProdOrderLine) do
            LibraryManufacturing.CreateProdOrderLine(
              ProdOrderLine[i], ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', '', ProductionOrder.Quantity / 2);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, false, false);

        // [GIVEN] Open the output journal and explode the routing.
        // [GIVEN] Define the item tracking on the journal line representing prod. order line "POL1". Lot No. = "L".
        CreateOutputJournal(ItemJournalLine, ProductionOrder."No.", Item."No.");
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        ItemJournalLine.Validate(Quantity, ProductionOrder.Quantity / 2);
        ItemJournalLine.Modify(true);
        OpenItemTrackingLines(ItemJournalLine, ItemTrackingMode::AssignLotNo);

        // [GIVEN] Delete the output journal lines representing prod. order line "POL2".
        ItemJournalLine.SetRange("Order Line No.", ProdOrderLine[2]."Line No.");
        ItemJournalLine.DeleteAll(true);

        // [GIVEN] Post the output.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create a reversed line in the output journal with item = "I", lot no. = "L", quantity = "-Q" and blank "Applies-to Entry".
        // [GIVEN] Set "Order Line No." = "POL2" on the reversed output line.
        CreateOutputJournal(ItemJournalLine, ProductionOrder."No.", Item."No.");
        ItemJournalLine.Validate("Output Quantity", -ProductionOrder.Quantity / 2);
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine[2]."Line No.");
        ItemJournalLine.Validate("Operation No.", FindLastOperationNo(Item."Routing No."));
        ItemJournalLine.Modify(true);
        OpenItemTrackingLines(ItemJournalLine, ItemTrackingMode::SelectEntries);

        // [WHEN] Post the output correction.
        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] "Applies-to Entry must have a value" error message is raised. The program could not find an original output for prod. order line "POL2".
        Assert.ExpectedTestFieldError(ItemJournalLine.FieldCaption("Applies-to Entry"), '');

        // Tear down.
        DeleteReservationEntry(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure OutputQtyWithScrapInProductionJournalAfterCreateReleasedProductionOrder()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        RoutingLine: Record "Routing Line";
        Quantity: Decimal;
        ScrapFactor: Decimal;
        ScrapFactor2: Decimal;
        FixedScrapQty: Decimal;
        FixedScrapQty2: Decimal;
        RndgPrecision: Decimal;
        OutputQty: Decimal;
    begin
        // Test to verify Output Quantity in Production Journal is correct with setting Fixed Scrap Quantity and Scrap Factor % in Routing.

        // Setup: Create Routing with Item. Set "Scrap Factor %" and "Fixed Scrap Quantity" for Routing Lines.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateRoutingWithScrapAndFlushingMethod(
          Item, WorkCenter."Flushing Method"::Manual, true, LibraryRandom.RandDec(10, 2), LibraryRandom.RandInt(5));

        // Exercise: Create Released Production Order.
        Quantity := LibraryRandom.RandInt(10);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, '', '');

        // Calculate the ScrapFactor & FixedScrapQty manually to avoid the rounding issue.
        FindFirstRoutingLine(RoutingLine, Item."Routing No.");
        RndgPrecision := LibraryRandom.RandDec(0, 5);
        ScrapFactor := 1 + RoutingLine."Scrap Factor %" / 100;
        FixedScrapQty := RoutingLine."Fixed Scrap Quantity";
        RoutingLine.Next();
        ScrapFactor2 := Round(ScrapFactor * (1 + RoutingLine."Scrap Factor %" / 100), RndgPrecision);
        FixedScrapQty2 := Round(RoutingLine."Fixed Scrap Quantity" * ScrapFactor + FixedScrapQty, RndgPrecision);
        OutputQty := Round(Quantity * ScrapFactor2 + FixedScrapQty2, RndgPrecision);

        // Verify: Open Production Journal for the Released Production Order.
        // Verify the Output Quantity on Production Journal through ProductionJournalPageHandler.
        OpenProductionJournalPage(ProductionOrder, Item."No.", Item."No.", OutputQty, ItemJournalLine."Entry Type"::Output);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActualCapacityCostOnReleasedProductionOrderStatisticsPage()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
        RunTime: Decimal;
        UnitCost: Decimal;
    begin
        // Test to verify Capacity Cost should be recognized in Production order Statistics as Actual Cost when posting output journal with Output Quantity = 0.
        Initialize();

        // Setup: Create and refresh release Production Order with setting blank Location code
        LibraryInventory.CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter); // Set Routing No. for Item
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // Create and Post Output Journal with Output Quantity = 0
        RunTime := LibraryRandom.RandDec(10, 2);
        UnitCost := LibraryRandom.RandDec(10, 2);
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, UnitCost);

        // Exercise: Open Release Production Order Statistics Page
        OpenReleasedProductionOrderStatisticsPage(ProductionOrderStatistics, ProductionOrder."No.");

        // Verify: Capacity Cost and Total Cost for Actual Cost column is correct on Release Production Order Statistics Page
        ProductionOrderStatistics.CapacityCost_ActualCost.AssertEquals(RunTime * UnitCost);
        ProductionOrderStatistics.TotalCost_ActualCost.AssertEquals(RunTime * UnitCost);
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandlerWithUpdateQuantity,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure PostProductionJournalWithItemFlushingPickAndBackward()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Test to verify an error pops up when posting the Production Journal with Qty. Picked (Base) is zero
        // in Prod. Order Component with Item Flushing Method is Pick + Backward.

        // Setup: Create Item with BOM and Routing. Update Inventory with Item Journal.
        Initialize();
        CreateItemWithBOMAndRouting(Item, ChildItem, LibraryRandom.RandInt(5));
        UpdateLocationAndBins(LocationSilver);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1); // Find Bin of Index 1.
        Quantity := LibraryRandom.RandInt(10);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandIntInRange(50, 100), LocationSilver.Code, Bin.Code); // Large Component Quantity is required.

        // Create and refresh 1st Released Production Order. Create and register the Whse. Pick created from Released Production Order.
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item."No.", Quantity, LocationSilver.Code, '');
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Create 2nd Released Production Order.
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item."No.", Quantity, LocationSilver.Code, LocationSilver."To-Production Bin Code");
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");

        // Open Production Journal Page, update Output Quantity and Post Production Journal on PostProductionJournalHandlerWithUpdateQuantity
        asserterror OpenProductionJournalPage(ProductionOrder, Item."No.", Item."No.", Quantity, ItemJournalLine."Entry Type"::Output);

        // Verify: Verify an error pops up when posting Production Journal with Qty. Picked (Base) is zero in Prod. Order Component.
        Assert.ExpectedError(QtyPickedBaseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CarryOutProductionOrderByPlanningWorksheet()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify Bin Code is correct in production order line after carry out the planning line with Warehouse LocationWhite.
        // Bin Code should be From-Production Bin Code of LocationWhite.

        // Setup: Create Item. Create Sales Order and update Location on Sales Line.
        Initialize();
        CreateItem(Item);
        UpdateItemParametersForPlanning(Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::"Lot-for-Lot");
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandInt(50), false); // Multiple Sales Lines is FALSE.
        UpdateLocationOnSalesLine(SalesHeader."No.", LocationWhite.Code);

        // Calculate Regenerative Plan on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Exercise: Accept and Carry Out Action Message.
        AcceptAndCarryOutActionMessageForPlanningWorksheet(Item."No.");

        // Verify: Verify Bin Code in Production Order Line.
        VerifyBinCodeInProductionOrderLine(Item."No.", LocationWhite."From-Production Bin Code");
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostProductionJournalAfterChangingUOMOnProdOrdLine()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseEntry: Record "Warehouse Entry";
        ItemNo: Code[20];
    begin
        // Test to verify the Quantity in Warehouse Entry is based on the UOM with Posting after changing UOM on Production Order Line.

        // Setup: Create Item with Routing. Create Item UOM. Create and refresh Release Production Order.
        Initialize();
        ItemNo := CreateItemWithRouting();
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, LibraryRandom.RandInt(10));
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, ItemNo, LibraryRandom.RandInt(20),
          LocationWhite.Code, LocationWhite."To-Production Bin Code");

        // Change UOM on Production Order Line.
        FindReleasedProdOrderLine(ProdOrderLine, ItemNo);
        UpdateProdOrderLineUnitOfMeasureCode(ProdOrderLine, ItemNo, ItemUnitOfMeasure.Code);
        UpdateInventoryAccountInterim(ProdOrderLine."Location Code", ProdOrderLine."Inventory Posting Group");

        // Exercise: Open Production Journal and post by handler PostProductionJournalHandler.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // Verify: Verify Quantity on Warehouse Entry is correct.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", ProductionOrder."No.", ItemNo,
          LocationWhite."To-Production Bin Code", LocationWhite.Code, ProdOrderLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostProductionJournalWithDifferentUOMForConsumption()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        QuantityPer: Decimal;
    begin
        // Test to verify the Quantity of ChildItem with consumed in Warehouse Entry is based on the UOM of Prod. BOM Line.

        // Setup: Create Item with BOM and Routing. Create ChildItem UOM. Update UOM of Prod. BOM line.
        // Create and refresh Released Production Order.
        Initialize();
        QuantityPer := LibraryRandom.RandIntInRange(2, 5); // It must be greater than 1.
        CreateItemWithBOMAndRouting(Item, ChildItem, QuantityPer);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ChildItem."No.", QuantityPer);
        UpdateBOMHeaderWithLineUOM(Item."Production BOM No.", ChildItem."No.", ItemUnitOfMeasure.Code);
        UpdateInventoryWithWhseItemJournal(ChildItem, LocationWhite, LibraryRandom.RandInt(10) + 1000);

        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item."No.", LibraryRandom.RandInt(10),
          LocationWhite.Code, LocationWhite."To-Production Bin Code");

        // Create and register Pick from Released Production Order.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Exercise: Open Production Journal and post by PostProductionJournalHandler.
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // Verify: Verify Quantity of ChildItem consumed on Warehouse Entry is correct.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Negative Adjmt.", ProductionOrder."No.", ChildItem."No.",
          LocationWhite."To-Production Bin Code", LocationWhite.Code, -(ProdOrderLine.Quantity * QuantityPer));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler,PostProductionJournalHandlerWithUpdateQuantity,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderWhenBackFlushingConsumptionAndManualOutputWithError()
    var
        Verification: Option VerifyErr,VerifyItemLedgerEntry;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify Error message is correct when Finish Production Order for Back Flushing Consumption and Manual Flushing Output with Scrap.

        FinishProdOrderWhenBackFlushingConsumptionAndManualFlushingOutputWithScrap(Verification::VerifyErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler,PostProductionJournalHandlerWithUpdateQuantity,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderWhenBackFlushingConsumptionAndManualOutputWithUpdateTracking()
    var
        Verification: Option VerifyErr,VerifyItemLedgerEntry;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify Production Order can be Finished when updating Tracking for Back Flushing Consumption and Manual Flushing Output with Scrap.

        FinishProdOrderWhenBackFlushingConsumptionAndManualFlushingOutputWithScrap(Verification::VerifyItemLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByBOMPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAvailByBOMLevelWithMultipleUOM()
    var
        Item: Record Item;
        ChildItem: Record Item;
        TopItem: Record Item;
        QuantityPer: Decimal;
        QuantityPer2: Decimal;
        QtyPerUnitOfMeasure: Decimal;
        QtyPerUnitOfMeasure2: Decimal;
        AvailableQty: Decimal;
        AvailableQty2: Decimal;
        ChildItemAbleToMakeParentQty: Decimal;
        ChildItemAbleToMakeTopItemQty: Decimal;
    begin
        // Setup: Create Production BOM, Parent Item and attach Production BOM. Create Child Item UOM. Update UOM of Prod. BOM line.
        // Create and post Item Journal Line for Child Item.
        Initialize();
        CreateItem(ChildItem);
        InitSetupForProdBOMWithMultipleUOM(Item, ChildItem, QuantityPer, QtyPerUnitOfMeasure, AvailableQty);
        InitSetupForProdBOMWithMultipleUOM(TopItem, Item, QuantityPer2, QtyPerUnitOfMeasure2, AvailableQty2);

        // Item is a BOM Item, so "Able to Make Parent" = (AvailQty + "Able to Make Parent") / "Qty. per Parent".
        // "Able to Make Top Item" = AvailQty / "Qty. per Top Item" + "Able to Make Top Item".
        // ChildItem is a Leaf Item, so "Able to Make Parent" := AvailQty / "Qty. per Parent", "Able to Make Top Item" := AvailQty / "Qty. per Top Item".
        ChildItemAbleToMakeParentQty := AvailableQty / (QuantityPer * QtyPerUnitOfMeasure);
        ChildItemAbleToMakeTopItemQty := AvailableQty / (QuantityPer * QtyPerUnitOfMeasure) / (QuantityPer2 * QtyPerUnitOfMeasure2);
        EnqueueVariablesForItemAvailByBOMPage(
          Item."No.", (AvailableQty2 + ChildItemAbleToMakeParentQty) / (QuantityPer2 * QtyPerUnitOfMeasure2),
          AvailableQty2 / (QuantityPer2 * QtyPerUnitOfMeasure2) + ChildItemAbleToMakeTopItemQty);
        EnqueueVariablesForItemAvailByBOMPage(ChildItem."No.", ChildItemAbleToMakeParentQty, ChildItemAbleToMakeTopItemQty);

        // Exercise & Verify: Run Item Availablity By BOM Level Page.
        // Verify Able to Make Parent and Able to Make Top Item of Item and ChildItem through ItemAvailabilityByBOMPageHandler.
        RunItemAvailByBOMLevelPage(TopItem);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseRequestExistsWhenAddingNewCompWithZeroQty()
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        NewProdOrderComponent: Record "Prod. Order Component";
        Item: Record Item;
        ChildItem: Record Item;
        WhseProdRelease: Codeunit "Whse.-Production Release";
    begin
        // [FEATURE] [Warehouse] [Manufacturing] [Warehouse Request]
        // [SCENARIO 109052.1] Verify 'Warehouse Request' exists when adding new component with zero Qty

        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);  // Require Pick

        // [GIVEN] Create Released Production Order "PO"
        CreateItemsSetup(Item, ChildItem, 10 + LibraryRandom.RandInt(10));
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", 10 + LibraryRandom.RandInt(10), Location.Code, '');

        // [GIVEN] Create new Prod. Order Component "C"
        CreateAndInitNewProdOrderComponent(NewProdOrderComponent, ProdOrderComponent, ProductionOrder);

        // [WHEN] Insert new "C" to "PO" line with zero Quantity
        WhseProdRelease.ReleaseLine(NewProdOrderComponent, ProdOrderComponent); // simulate (Rec,xRec) 'Prod. Order Component'.INSERT trigger

        // [THEN] Warehouse Request exists for "PO"
        VerifyWhseRequestExist(ProductionOrder."No.", Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhsePickRequestExistsWhenAddingNewCompAfterFullyConsumpedComp()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        NewProdOrderComponent: Record "Prod. Order Component";
        Item: Record Item;
        ChildItem: Record Item;
        WhseProdRelease: Codeunit "Whse.-Production Release";
        Quantity: Decimal;
        QuantityPer: Decimal;
    begin
        // [FEATURE] [Warehouse] [Manufacturing] [Warehouse Request]
        // [SCENARIO 109052.2] Verify 'Whse. Pick Request' exists when adding new component after fully consumed previous component

        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, true);  // Require Pick, Shipment
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create production item, fill inventory with consumption item "CI"
        Quantity := 10 + LibraryRandom.RandInt(10);
        QuantityPer := 10 + LibraryRandom.RandInt(10);
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity * QuantityPer * 2, Location.Code, '');

        // [GIVEN] Create Released Production Order "PO", make Whse. Pick, register Pick and Post Consumption Journal
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, Location.Code, '');
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        FindAndRegisterWhseActivity(Location.Code, ProductionOrder."No.");
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");

        // [GIVEN] Create new Prod. Order Component "C"
        CreateAndInitNewProdOrderComponent(NewProdOrderComponent, ProdOrderComponent, ProductionOrder);

        // [WHEN] Insert "C" after "CI"
        WhseProdRelease.ReleaseLine(NewProdOrderComponent, ProdOrderComponent); // simulate (Rec,xRec) 'Prod. Order Component'.INSERT trigger

        // [THEN] Whse. Pick Request exists for "PO"
        VerifyWhsePickRequestExist(ProductionOrder."No.", Location.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotPostOutputJournalWithChangedOrderLineNo()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        NewProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Production] [Manufacturing] [Output Journal]
        // [SCENARIO 109053] Posting of Output Journal is not allowed with ItemNo different from Order Line's Item

        Initialize();
        CreateItem(Item);
        CreateItem(Item2);

        // [GIVEN] Create and Refresh Released Production Order "RPO" for Item "X1"
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(100), '', '');

        // [GIVEN] Manually add new Prod. Order Line with new Item "X2"
        CreateAddProdOrderLine(NewProdOrderLine, ProductionOrder, Item2."No.");

        // [GIVEN] Open Output Journal and add a line for "RPO" SourceNo Item "X1"
        CreateOutputJournal(ItemJournalLine, ProductionOrder."No.", Item."No.");
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [GIVEN] Modify Output Journal's "Order Line No." to the line with item "X2"
        ItemJournalLine.Validate("Order Line No.", NewProdOrderLine."Line No.");
        ItemJournalLine.Modify(true);

        // [WHEN] Post the Output Journal
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [THEN] Error occurs: 'Item No. must be equal to "X2" in Item Journal Line... '
        Assert.ExpectedTestFieldError(ItemJournalLine.FieldCaption("Item No."), Item2."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckProdOrderLineGetsBinCodeFromWorkCenterThroughPlanningRoutingLine()
    var
        RequisitionLine: Record "Requisition Line";
        WorkCenter: Record "Work Center";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Planning] [Bin] [Planning Worksheet] [Work Center]
        // [SCENARIO 360750.1] ProdOrderLine gets BinCode from Work Center through Planning Routing Line

        Initialize();

        // [GIVEN] Create Requisition Line by calculating Regenerative Plan. Update Work Center No on Planning Routing.
        CreateRequisitionLineWithPlanningRouting(RequisitionLine, WorkCenter, ItemNo);

        // [WHEN] Carry out Action Message
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] ProdOrderLine's BinCode is same as Work Center's Bin Code
        VerifyProdOrderLineBinCode(ItemNo, WorkCenter."From-Production Bin Code");
    end;

    [Test]
    [HandlerFunctions('ItemSubstEntries_MPH')]
    [Scope('OnPrem')]
    procedure ItemSubstitutionALLtoALLHasNoDuplications()
    var
        TempItem: Record Item temporary;
        ProdOrderComponent: Record "Prod. Order Component";
        ItemNo: array[10] of Code[20];
        ItemCount: Integer;
        i: Integer;
    begin
        // [FEATURE] [Production] [Item Substitutions]
        // [SCENARIO] No duplicate items in Substitution list for ALL-to-ALL subtitution setup

        Initialize();
        ItemCount := ArrayLen(ItemNo);

        // [GIVEN] N Items with ALL-to-ALL substitution setup
        for i := 1 to ItemCount do
            ItemNo[i] := CreateSimpleItem();

        for i := 1 to ItemCount do
            CreateItemSubstitution(ItemNo, i);

        // [WHEN] Show Item substitution list for the first item
        ProdOrderComponent.Init();
        ProdOrderComponent."Item No." := ItemNo[1];
        ProdOrderComponent.ShowItemSub();

        // [THEN] Number of substitutions are equal to (N - 1)
        Assert.AreEqual(ItemCount - 1, LibraryVariableStorage.Length(), ItemSubstCountErr);

        // [THEN] There is no duplications within substitution list
        TempItem.Init();
        for i := 1 to ItemCount - 1 do begin
            TempItem."No." := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(TempItem."No."));
            Assert.IsTrue(TempItem.Insert(), ItemSubstDublicationErr);
        end;

        // [THEN] There are correct substitution Items
        for i := 2 to ItemCount do
            Assert.IsTrue(TempItem.Get(ItemNo[i]), ItemSubstItemNoErr);
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
    [HandlerFunctions('ConfirmHandlerTRUE,PostProductionJournalHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesCreatesValueEntryWithSourceTypeTakenFromoItemJournalLine()
    var
        Item: Record Item;
        ChildItem: Record Item;
        WorkCenter: Record "Work Center";
        ValueEntry: Record "Value Entry";
        Quantity: Decimal;
        ProdOrderNo: Code[20];
    begin
        // [FEATURE] [Adjust Cost] [Subcontracting]
        // [SCENARIO 361968] Adjust Cost Item Entries creates Value Entry with "Source Type" and "Source No." taken from original VE
        Initialize();

        // [GIVEN] Item with Routing
        Quantity := LibraryRandom.RandInt(5);
        CreateItemsSetup(Item, ChildItem, Quantity);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity * Quantity, '', ''); // Required supply is ProdBOMLine.Quantity * ProductionOrder.Quantity
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify();
        // [GIVEN] Released Production Order
        // [GIVEN] Post output/consuption. Finish Production Order
        ProdOrderNo := CreateFinishedProdOrder(Item."No.", Quantity);

        // [WHEN] Run Adjust Cost Item Entries
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // [THEN] Value Entry is created with "Source Type" and "Source No." taken from from Original VE
        VerifyValueEntrySource(ProdOrderNo, Item."No.", ValueEntry."Source Type"::Item);
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
    [Scope('OnPrem')]
    procedure ConsumptionJournalForZeroExpectedQuantity()
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [SCENARIO 378650] Post Consumption Journal Job for Component with Zero Expected Quantity should set Remaining Quantity for this Component to zero.
        Initialize();

        // [GIVEN] Released Production Order.
        // [GIVEN] Prod. Order Component with "Quantity Per" = 0.
        CreateProdOrderAddNewComponentAndCreateConsumptionLine(ProdOrderComponent, 0);

        // [WHEN] Post Consumption Journal Line for this Component.
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        // [THEN] The Component has "Remaining Qty. (Base)" = 0.
        ProdOrderComponent.Find();
        ProdOrderComponent.TestField("Remaining Qty. (Base)", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateProdOrderLineExpectedQuantity()
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Prod. Order Component] [UT]
        // [SCENARIO 379075] Remaining Quantity should be 0 if Expected Qty. is validated to 0, regardless of posted consumption quantity.
        Initialize();

        // [GIVEN] Item Ledger Entry with Entry Type = Consumption and Quantity <> 0.
        // [GIVEN] Prod. Order Component.
        MockProdOrderComponent(ProdOrderComponent);
        MockItemLedgerEntryForConsumption(ProdOrderComponent);

        // [WHEN] Revalidate "Expected Quantity" of this Component to 0.
        ProdOrderComponent.Validate("Expected Quantity", 0);

        // [THEN] The Component has "Remaining Quantity" = 0.
        ProdOrderComponent.TestField("Remaining Quantity", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlannedProdOrderRoutingGetsToProdBinFromWorkCenter()
    var
        RequisitionLine: Record "Requisition Line";
        WorkCenter: Record "Work Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Planning Worksheet] [Work Center] [Bin]
        // [SCENARIO 379347] Prod. Order Routing Line gets "To-Production Bin Code" from Work Center with Manual Flushing Method through Planning.
        Initialize();

        // [GIVEN] Create Work Center with "Flushing Method" = Manual and "To-Production Bin Code" = "B".
        // [GIVEN] Create Requisition Line by calculating Regenerative Plan. Update Work Center on Planning Routing.
        CreateRequisitionLineWithPlanningRouting(RequisitionLine, WorkCenter, ItemNo);

        // [WHEN] Carry out Action Message.
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] "To-Production Bin Code" in Prod. Order Routing Line is equal to "B".
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ItemNo);
        Assert.AreEqual(
          WorkCenter."To-Production Bin Code", ProdOrderRoutingLine."To-Production Bin Code",
          StrSubstNo(RtngLineBinCodeErr, ProdOrderRoutingLine.FieldCaption("To-Production Bin Code"), ProdOrderRoutingLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlannedProdOrderRoutingGetsOpenShopFloorBinFromWorkCenter()
    var
        RequisitionLine: Record "Requisition Line";
        WorkCenter: Record "Work Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Planning Worksheet] [Work Center] [Bin]
        // [SCENARIO 379347] Prod. Order Routing Line gets "Open Shop Floor Bin Code" from Work Center with non-Manual Flushing Method through Planning.
        Initialize();

        // [GIVEN] Create Work Center with "Flushing Method" <> Manual and "Open Shop Floor Bin Code" = "B".
        // [GIVEN] Create Requisition Line by calculating Regenerative Plan. Update Work Center on Planning Routing.
        CreateRequisitionLineWithPlanningRouting(RequisitionLine, WorkCenter, ItemNo);
        WorkCenter.Validate("Flushing Method", LibraryRandom.RandInt(2)); // forward or backward
        WorkCenter.Modify(true);

        // [WHEN] Carry out Action Message.
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] "Open Shop Floor Bin Code" in Prod. Order Routing Line is equal to "B".
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ItemNo);
        Assert.AreEqual(
          WorkCenter."Open Shop Floor Bin Code", ProdOrderRoutingLine."Open Shop Floor Bin Code",
          StrSubstNo(RtngLineBinCodeErr, ProdOrderRoutingLine.FieldCaption("Open Shop Floor Bin Code"), ProdOrderRoutingLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeShouldBeFilledAfterValidatingVariantCodeinProductionOrderLine()
    var
        ChildItem: Record Item;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [Production] [Bin]
        // [SCENARIO 379950] Released Production Order should successfully post output on changing status to finished if variant code was changed before it in Production Order Line.
        Initialize();

        // [GIVEN] Create parent Item with routing, child Item and Production BOM.
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));
        CreateRoutingAndUpdateItemSubc(Item, WorkCenter, false);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Update Flushing Method On child Item to Backward.
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);

        // [GIVEN] Inventory of ChildItem in white Location in Open Shop Floor Bin.
        UpdateItemInventoryForLocation(ChildItem, LocationWhite, LibraryRandom.RandDecInRange(11, 100, 2));

        // [GIVEN] Released Production Order with 1 line.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(10, 2), LocationWhite.Code, '');
        UpdateFlushingMethodOnProdOrderRoutingLine(ProductionOrder);

        // [WHEN] Change Variant Code in Production Order Line.
        UpdateVariantCodeInProductionOrderLine(ProdOrderLine, ProductionOrder, ItemVariant.Code);

        // [THEN] Bin Code should be filled and production order should change status successfully.
        ProdOrderLine.TestField("Bin Code", LocationWhite."From-Production Bin Code");
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        VerifyProductionOrderIsEmpty(ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningComponentBinCopiedFromWorkCenterProductionBinWithRoutingLink()
    var
        ParentItem: Record Item;
        ComponentItem: array[2] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeader: Record "Routing Header";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Bin] [Routing] [Production BOM] [Routing Link]
        // [SCENARIO 253201] Bin code in the planning component line shoud be taken from the "To-Production Bin Code" field of the work center linked to the corresponding production BOM line

        Initialize();

        // [GIVEN] Manufactured item "I" with two components "C1" and "C2"
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(ComponentItem[1]);
        LibraryInventory.CreateItem(ComponentItem[2]);

        // [GIVEN] Work center "W1" with "To-Production Bin" "B1"
        CreateWorkCenterWithLocationAndBin(WorkCenter[1], LocationSilver.Code);
        // [GIVEN] Work center "W2" with "To-Production Bin" "B2"
        CreateWorkCenterWithNewToProductionBin(WorkCenter[2], LocationSilver.Code);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ParentItem."Base Unit of Measure");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [GIVEN] Routing operation on the work center "W1" linked to a production BOM line with component "C1"
        CreateLinkedProdBOMLineAndRoutingLine(ProductionBOMHeader, RoutingHeader, WorkCenter[1]."No.", ComponentItem[1]."No.");
        // [GIVEN] Routing operation on the work center "W2" linked to a production BOM line with component "C2"
        CreateLinkedProdBOMLineAndRoutingLine(ProductionBOMHeader, RoutingHeader, WorkCenter[2]."No.", ComponentItem[2]."No.");

        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        UpdateItemManufacturingProperties(ParentItem, ProductionBOMHeader."No.", RoutingHeader."No.");

        // [GIVEN] Sales order for the top-level item "I"
        CreateSalesOrderOnLocation(SalesHeader, ParentItem."No.", LibraryRandom.RandInt(100), WorkCenter[1]."Location Code");

        // [WHEN] Run regenerative plan for the item "I"
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, WorkDate(), WorkDate());

        // [THEN] Planning component line for the item "C1" has "Bin Code" = "B1"
        VerifyPlanningComponentBin(ComponentItem[1]."No.", WorkCenter[1]."Location Code", WorkCenter[1]."To-Production Bin Code");
        // [THEN] Planning component line for the item "C2" has "Bin Code" = "B2"
        VerifyPlanningComponentBin(ComponentItem[2]."No.", WorkCenter[2]."Location Code", WorkCenter[2]."To-Production Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningComponentBinCopiedFromFirstWorkCenterProdBinWhenNoRoutingLink()
    var
        ParentItem: Record Item;
        ComponentItem: array[2] of Record Item;
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Bin] [Routing] [Production BOM]
        // [SCENARIO 253201] Bin code in the planning component line shoud be taken from the "To-Production Bin Code" field of the work center in the first routing operation if there is no routing link

        Initialize();

        // [GIVEN] Manufactured item "I" with two components "C1" and "C2"
        CreateAndCertifyProdBOMWithMultipleComponent(ParentItem, ComponentItem[1], ComponentItem[2]);

        // [GIVEN] Work center "W1" with "To-Production Bin" "B1"
        CreateWorkCenterWithLocationAndBin(WorkCenter[1], LocationSilver.Code);
        // [GIVEN] Work center "W2" with "To-Production Bin" "B2"
        CreateWorkCenterWithNewToProductionBin(WorkCenter[2], LocationSilver.Code);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter[1]."No.");
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter[2]."No.");

        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        UpdateItemManufacturingProperties(ParentItem, ParentItem."Production BOM No.", RoutingHeader."No.");

        // [GIVEN] Sales order for the top-level item "I"
        CreateSalesOrderOnLocation(SalesHeader, ParentItem."No.", LibraryRandom.RandInt(100), WorkCenter[1]."Location Code");

        // [WHEN] Run regenerative plan for the item "I"
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, WorkDate(), WorkDate());

        // [THEN] "To-Production Bin Code" is "B1" on both planning component lines
        VerifyPlanningComponentBin(ComponentItem[1]."No.", WorkCenter[1]."Location Code", WorkCenter[1]."To-Production Bin Code");
        VerifyPlanningComponentBin(ComponentItem[2]."No.", WorkCenter[1]."Location Code", WorkCenter[1]."To-Production Bin Code");
    end;

    [Test]
    [HandlerFunctions('ProdOrderRoutingPageHandler')]
    [Scope('OnPrem')]
    procedure CustomSelectedBinIsNotRedefinedWithToProdBinCode()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 262029] Non-blank bin code on a production order line is not redefined, despite the different "From-Production Bin Code" setting on the location.
        Initialize();

        // [GIVEN] Location "L" with two bins - "B1", "B2".
        // [GIVEN] Set "From-Production Bin Code" on the location = "B1".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        LibraryWarehouse.FindBin(Bin[1], Location.Code, '', 1);
        LibraryWarehouse.FindBin(Bin[2], Location.Code, '', 2);
        Location.Validate("From-Production Bin Code", Bin[1].Code);
        Location.Modify(true);

        // [GIVEN] Released production order on location "L".
        CreateAndRefreshProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), Location.Code, '');
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Set "Bin Code" = "B2" on the production order line.
        ProdOrderLine.Validate("Bin Code", Bin[2].Code);
        ProdOrderLine.Modify(true);

        // [WHEN] Show routing for the production order.
        ProdOrderLine.ShowRouting();

        // [THEN] Manually defined "Bin Code" = "B2" on the production order line is not changed.
        ProdOrderLine.Find();
        ProdOrderLine.TestField("Bin Code", Bin[2].Code);
    end;

    [Test]
    [HandlerFunctions('ProdOrderRoutingPageHandler')]
    [Scope('OnPrem')]
    procedure BlankBinCodeOnProdOrderLineIsUpdatedWithDefaultBin()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 262029] Blank bin code on a production order line is populated with a bin code, that has a default bin content for the item, location and variant on the prod. order line.
        Initialize();

        // [GIVEN] Location "L" with mandatory bin.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Released production order for item "I" on location "L". "Bin Code" is blank on the prod. order line.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), Location.Code, '');
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Create bin content for item "I", location "L", bin "B", default = TRUE.
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [WHEN] Show routing for the production order.
        ProdOrderLine.ShowRouting();

        // [THEN] "Bin Code" on the prod. order line is updated to "B".
        ProdOrderLine.Find();
        ProdOrderLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [HandlerFunctions('ProdOrderRoutingPageHandler')]
    [Scope('OnPrem')]
    procedure UnitCostOnProdOrderLineIsNotChangedOnShowRouting()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        UnitCost: Decimal;
    begin
        // [SCENARIO 262029] If you open and close Routing page in a production order, it won't affect unit cost on production order lines.
        Initialize();

        // [GIVEN] Released production order.
        CreateAndRefreshProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', '');
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Set unit cost on the prod. order line = "X".
        UnitCost := LibraryRandom.RandDec(10, 2);
        ProdOrderLine.Validate("Unit Cost", UnitCost);
        ProdOrderLine.Modify(true);

        // [WHEN] Show routing for the production order.
        ProdOrderLine.ShowRouting();

        // [THEN] Unit cost on the prod. order line remains to be equal to "X".
        ProdOrderLine.Find();
        ProdOrderLine.TestField("Unit Cost", UnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedCostOnPostingOutputIsInheritedFromItemIfSKUDoesNotExist()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Expected Cost]
        // [SCENARIO 266183] Unit cost on item card is posted as expected unit cost of output if no stockkeeping unit exists for the item and location.
        Initialize();

        // [GIVEN] Item with "Unit Cost" = 0.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Released production order for "Q" pcs of the item.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), LocationBlue.Code, '');

        // [GIVEN] Update "Unit Cost" on the item to "X".
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);

        // [WHEN] Post the output.
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);

        // [THEN] Expected cost of the output is equal to "Q" * "X".
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Expected)", ProductionOrder.Quantity * Item."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedCostOnPostingOutputIsInheritedFromSKUIfItExists()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Expected Cost] [Stockkeeping Unit]
        // [SCENARIO 266183] Unit cost on stockkeeping unit card is posted as expected unit cost of output if SKU exists for the item and location.
        Initialize();

        // [GIVEN] Item "I" with "Unit Cost" = 0.
        // [GIVEN] Stockkeeping unit for item "I" on location "L".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, LocationBlue.Code, Item."No.", '');

        // [GIVEN] Released production order for "Q" pcs of the item.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), LocationBlue.Code, '');

        // [GIVEN] Update "Unit Cost" on the item to "X".
        // [GIVEN] Update "Unit Cost" on the stockkeeping unit to "Y".
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        SKU.Validate("Unit Cost", LibraryRandom.RandDecInRange(11, 20, 2));
        SKU.Modify(true);

        // [WHEN] Post the output.
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);

        // [THEN] xpected cost of the output is equal to "Q" * "Y".
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Expected)", ProductionOrder.Quantity * SKU."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddingNewComponentDoesNotCheckActualConsumedQty()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Prod. Order Component] [Consumption] [UT]
        // [SCENARIO 287655] Adding new prod. order component does not check for lack of previously posted consumption.
        Initialize();

        // [GIVEN] Component item "C" is in inventory.
        LibraryInventory.CreateItem(CompItem);
        CreateAndPostItemJournalLine(CompItem."No.", LibraryRandom.RandIntInRange(50, 100), '', '');

        // [GIVEN] Production item "P" does not have a production BOM yet.
        // [GIVEN] Released production order for item "P".
        LibraryInventory.CreateItem(ProdItem);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", LibraryRandom.RandInt(10), '', '');
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Post the consumption of "C" in consumption journal.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Consumption, CompItem."No.", LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Initialize a new prod. order component.
        ProdOrderComponent.Init();
        ProdOrderComponent.Validate(Status, ProdOrderLine.Status);
        ProdOrderComponent.Validate("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.Validate("Prod. Order Line No.", ProdOrderLine."Line No.");

        // [WHEN] Select item "C" on the new prod. order component line.
        ProdOrderComponent.Validate("Item No.", CompItem."No.");

        // [THEN] The new component is successfully added.
        ProdOrderComponent.TestField("Unit of Measure Code", CompItem."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyingExistingComponentChecksActualConsumedQtyIsZero()
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Prod. Order Component] [Consumption] [UT]
        // [SCENARIO 287655] Updating item no. on prod. order component checks that there were no previously posted consumption for this prod. order component line.
        Initialize();

        // [GIVEN] Component item "C" is in inventory.
        // [GIVEN] Production item "P" has a production BOM with item "C" as a component.
        // [GIVEN] Released production order for item "P".
        // [GIVEN] Post the consumption of item "C" in consumption journal.
        CreateProdOrderAddNewComponentAndCreateConsumptionLine(ProdOrderComponent, 1);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        // [WHEN] Change Item No. on prod. order component from "C" to a new item "X".
        ProdOrderComponent.Find();
        asserterror ProdOrderComponent.Validate("Item No.", LibraryInventory.CreateItemNo());

        // [THEN] Error is thrown, reading that there was a posted consumption on this component line.
        Assert.ExpectedTestFieldError(ProdOrderComponent.FieldCaption("Act. Consumption (Qty)"), Format(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculatingProdOrderDateTimeAsMininumAndMaximumAmongProdOrderLines()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 291614] AdjustStartEndingDate function on Production Order table finds the earliest and the latest dates among prod. order lines to populate Starting Date and Ending Date respectively.
        Initialize();

        // [GIVEN] Released production order.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        // [GIVEN] The production order has eight lines with various starting, ending and due dates.
        // [GIVEN] The earliest starting date-time is 05/01/20 11:00, the latest ending date-time is 30/01/20 22:00.
        // [GIVEN] The latest due date is 01/02/20.
        CreateProdOrderLineWithDates(ProductionOrder, 20200116D, 080000T, 20200122D);
        CreateProdOrderLineWithDates(ProductionOrder, 20200130D, 220000T, 20200131D); // the latest ending date
        CreateProdOrderLineWithDates(ProductionOrder, 20200105D, 150000T, 20200117D);
        CreateProdOrderLineWithDates(ProductionOrder, 20200117D, 140000T, 20200118D);
        CreateProdOrderLineWithDates(ProductionOrder, 20200105D, 110000T, 20200101D); // the earliest starting date
        CreateProdOrderLineWithDates(ProductionOrder, 20200107D, 020000T, 20200130D);
        CreateProdOrderLineWithDates(ProductionOrder, 20200130D, 080000T, 20200201D); // the latest due date
        CreateProdOrderLineWithDates(ProductionOrder, 20200124D, 170000T, 20200128D);

        // [WHEN] Invoke 'AdjustStartEndingDate' function on the production order.
        ProductionOrder.AdjustStartEndingDate();

        // [THEN] The production order dates are updated.
        // [THEN] Starting date-time = 05/01/20 11:00.
        // [THEN] Ending date-time = 30/01/20 22:00.
        // [THEN] Due date = 01/02/20.
        ProductionOrder.TestField("Starting Date-Time", CreateDateTime(20200105D, 110000T));
        ProductionOrder.TestField("Ending Date-Time", CreateDateTime(20200130D, 220000T));
        ProductionOrder.TestField("Due Date", 20200201D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculateFunctionOnProdOrderLineUpdatesProdOrderDates()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
        Direction: Option Forward,Backward;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 291614] Invoking Recalculate function on a production order line updates dates on the production order without running 'AdjustStartEndingDate' on the production order explicitly.
        Initialize();

        // [GIVEN] Released production order.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Change dates on the production order, so they do not match the dates on the production order line.
        ProductionOrder."Starting Date" := ProductionOrder."Starting Date" - LibraryRandom.RandIntInRange(5, 10);
        ProductionOrder."Ending Date" := ProductionOrder."Ending Date" + LibraryRandom.RandIntInRange(5, 10);
        ProductionOrder."Due Date" := ProductionOrder."Due Date" + LibraryRandom.RandIntInRange(5, 10);
        ProductionOrder.Modify();

        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [WHEN] Recalculate the production order line.
        CalculateProdOrder.Recalculate(ProdOrderLine, Direction::Backward, false);

        // [THEN] The dates on the production order are equal to the dates on the production order line.
        ProductionOrder.Find();
        ProductionOrder.TestField("Starting Date", ProdOrderLine."Starting Date");
        ProductionOrder.TestField("Ending Date", ProdOrderLine."Ending Date");
        ProductionOrder.TestField("Due Date", ProdOrderLine."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdatePreviousNextOperationNoProdOrderRouting()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemNo: Code[20];
        FirstOperationNo: Code[10];
        LastOperationNo: Code[10];
    begin
        // [FEATURE] [Routing]
        // [SCENARIO 291617] "Next/Previous Operation No." are automatically relinked on deletion of Prod. Order Routing Lines
        Initialize();

        // [GIVEN] Created Item "IT" with Routing of type "Serial" and 3 Routing Lines
        ItemNo := CreateItemSerialRoutingSeveralLines(3);

        // [GIVEN] Released Prod. Order for item "IT" Created and Refreshed
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder,
          ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item,
          ItemNo,
          LibraryRandom.RandDec(10, 0));

        // [GIVEN] First Prod. Order Routing Line with "Operation No." = 10
        // [GIVEN] Last Prod. Order Routing Line with "Operation No." = 30
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        FirstOperationNo := ProdOrderRoutingLine."Operation No.";
        ProdOrderRoutingLine.FindLast();
        LastOperationNo := ProdOrderRoutingLine."Operation No.";

        // [WHEN] CheckPreviousAndNext called on the middle Prod. Order Routing Line
        ProdOrderRoutingLine.Next(-1);
        ProdOrderRoutingLine.CheckPreviousAndNext();

        // [THEN] "Next Operation No." = 30 on the first Prod. Order Routing Line
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(LastOperationNo, ProdOrderRoutingLine."Next Operation No.", '');

        // [THEN] "Previous Operation No." = 10 on the last Prod. Order Routing Line
        ProdOrderRoutingLine.FindLast();
        Assert.AreEqual(FirstOperationNo, ProdOrderRoutingLine."Previous Operation No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPositiveOutputDoesNotRequireMandatoryWhseHandling()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseEntry: Record "Warehouse Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Inventory Put-away] [Output]
        // [SCENARIO 297641] Warehouse handling is not mandatory when posting production output on location set up for required put-away.
        Initialize();

        // [GIVEN] Location "L" with "Require Put-away" = TRUE, "Require Receive" = FALSE.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Item "I" with routing.
        LibraryInventory.CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for item "I" on location "L".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), Location.Code, Bin.Code);

        // [GIVEN] Open output journal and explode routing for the production order.
        // [GIVEN] Set the output quantity.
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrder."No.");
        ItemJournalLine.Validate("Output Quantity", ProductionOrder.Quantity);
        ItemJournalLine.Modify(true);

        // [WHEN] Post the output journal.
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [THEN] The output is successfully posted.
        // [THEN] The warehouse and item entries representing the output are created.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", ProductionOrder."No.", Item."No.",
          Bin.Code, Location.Code, ProductionOrder.Quantity);
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Output, Item."No.", ProductionOrder.Quantity, Location.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostingOutputFailsIfInventoryPutAwayAlreadyExists()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Inventory Put-away] [Output]
        // [SCENARIO 297641] A user cannot proceed posting output directly from output journal after they created an inventory put-away.
        Initialize();

        // [GIVEN] Location "L" with "Require Put-away" = TRUE, "Require Receive" = FALSE.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Item "I" with routing.
        LibraryInventory.CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order for item "I" on location "L".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), Location.Code, Bin.Code);

        // [GIVEN] Create inbound warehouse request and inventory put-away from the production order.
        LibraryVariableStorage.Enqueue(InboundWhseRequestCreatedMsg);
        LibraryVariableStorage.Enqueue(PutawayActivitiesCreatedMsg);
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);

        // [GIVEN] Open output journal and explode routing for the production order.
        // [GIVEN] Set the output quantity.
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrder."No.");
        ItemJournalLine.Validate("Output Quantity", ProductionOrder.Quantity);
        ItemJournalLine.Modify(true);

        // [WHEN] Post the output journal.
        asserterror LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [THEN] The posting fails. A user is notified that they have to proceed with the inventory put-away to post the output.
        Assert.ExpectedError(WHHandlingIsRequiredErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeIsFromProdBinCodeForLocationWithDirectedPAAndPick()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Bin] [UT]
        // [SCENARIO 321444] Bin Code is by default blank on production order despite the "From-Production Bin Code" setting on location with directed put-away and pick.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));

        ProductionOrder.Validate("Location Code", LocationWhite.Code);

        ProductionOrder.TestField("Bin Code", '');
        LocationWhite.TestField("From-Production Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeIsNotOverriddenToDefaultForLocationWithDirectedPAAndPick()
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        ProductionOrder: Record "Production Order";
        FromProdBinCode: Code[20];
    begin
        // [FEATURE] [Bin] [UT]
        // [SCENARIO 321444] Bin Code is not set to "Default Bin" when you select location code with enabled directed put-away and pick on production order and "From-Production Bin Code" is not defined.
        Initialize();

        LocationWhite.Find();
        FromProdBinCode := LocationWhite."From-Production Bin Code";
        LocationWhite."From-Production Bin Code" := '';
        LocationWhite.Modify();

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 1);
        LibraryWarehouse.CreateBinContent(BinContent, LocationWhite.Code, Zone.Code, Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));

        ProductionOrder.Validate("Location Code", LocationWhite.Code);

        ProductionOrder.TestField("Bin Code", '');

        // tear down
        LocationWhite."From-Production Bin Code" := FromProdBinCode;
        LocationWhite.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeIsOverriddenToDefaultForBasicWMSLocation()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Bin] [UT]
        // [SCENARIO 321444] Bin Code is set to "Default Bin" when you select a location with disabled directed put-away and pick on production order and "From-Production Bin Code" is not defined.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));

        ProductionOrder.Validate("Location Code", Location.Code);

        ProductionOrder.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDateOnCalendarEntry()
    var
        CalendarEntry: Record "Calendar Entry";
        StartingTime: Time;
        EndingTime: Time;
        CurrDate: Date;
    begin
        // [FEATURE] [Calendar Entry] [UT]
        // [SCENARIO 331428] GetStartingEndingDateAndTime function in Calendar Entry table initializes StartingTime,EndingTime and Date variables used as expressions on date and time controls on Calendar Entry page.
        Initialize();

        CalendarEntry.Init();
        CalendarEntry."No." := LibraryUtility.GenerateGUID();
        CalendarEntry."Starting Date-Time" := CreateDateTime(WorkDate(), 120000T);
        CalendarEntry."Ending Date-Time" := CreateDateTime(WorkDate() + 30, 120000T);

        CalendarEntry.GetStartingEndingDateAndTime(StartingTime, EndingTime, CurrDate);

        Assert.AreEqual(DT2Time(CalendarEntry."Starting Date-Time"), StartingTime, '');
        Assert.AreEqual(DT2Time(CalendarEntry."Ending Date-Time"), EndingTime, '');
        Assert.AreEqual(DT2Date(CalendarEntry."Ending Date-Time"), CurrDate, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnPlannedProductionOrderCard()
    var
        PlannedProdOrder: Record "Production Order";
        PlannedProductionOrderCard: TestPage "Planned Production Order";
        NewDate: Date;
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 379091] Validating "Starting Date-Time" and "Ending Date-Time" on a new planned prod. order line does not reset previously entered data.
        Initialize();

        MockProductionOrder(PlannedProdOrder, PlannedProdOrder.Status::Planned);

        PlannedProductionOrderCard.OpenEdit();
        PlannedProductionOrderCard.FILTER.SetFilter("No.", PlannedProdOrder."No.");

        NewDate := LibraryRandom.RandDate(30);

        ItemNo := LibraryInventory.CreateItemNo();
        PlannedProductionOrderCard.ProdOrderLines.New();
        PlannedProductionOrderCard.ProdOrderLines."Item No.".SetValue(ItemNo);
        PlannedProductionOrderCard.ProdOrderLines."Ending Date-Time".SetValue(NewDate);
        PlannedProductionOrderCard.ProdOrderLines."Item No.".AssertEquals(ItemNo);

        PlannedProductionOrderCard.ProdOrderLines.New();
        PlannedProductionOrderCard.ProdOrderLines."Item No.".SetValue(ItemNo);
        PlannedProductionOrderCard.ProdOrderLines."Starting Date-Time".SetValue(NewDate);
        PlannedProductionOrderCard.ProdOrderLines."Item No.".AssertEquals(ItemNo);

        PlannedProductionOrderCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnFirmPlannedProductionOrderCard()
    var
        FirmPlannedProdOrder: Record "Production Order";
        FirmPlannedProdOrderCard: TestPage "Firm Planned Prod. Order";
        NewDate: Date;
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 379091] Validating "Starting Date-Time" and "Ending Date-Time" on a new firm planned prod. order line does not reset previously entered data.
        Initialize();

        MockProductionOrder(FirmPlannedProdOrder, FirmPlannedProdOrder.Status::"Firm Planned");

        FirmPlannedProdOrderCard.OpenEdit();
        FirmPlannedProdOrderCard.FILTER.SetFilter("No.", FirmPlannedProdOrder."No.");

        NewDate := LibraryRandom.RandDate(30);
        FirmPlannedProdOrderCard."Due Date".SetValue(NewDate);

        ItemNo := LibraryInventory.CreateItemNo();
        FirmPlannedProdOrderCard.ProdOrderLines.New();
        FirmPlannedProdOrderCard.ProdOrderLines."Item No.".SetValue(ItemNo);
        FirmPlannedProdOrderCard.ProdOrderLines."Ending Date-Time".SetValue(NewDate);
        FirmPlannedProdOrderCard.ProdOrderLines."Item No.".AssertEquals(ItemNo);

        FirmPlannedProdOrderCard.ProdOrderLines.New();
        FirmPlannedProdOrderCard.ProdOrderLines."Item No.".SetValue(ItemNo);
        FirmPlannedProdOrderCard.ProdOrderLines."Starting Date-Time".SetValue(NewDate);
        FirmPlannedProdOrderCard.ProdOrderLines."Item No.".AssertEquals(ItemNo);

        FirmPlannedProdOrderCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnReleasedProductionOrderCard()
    var
        ReleasedProdOrder: Record "Production Order";
        ReleasedProductionOrderCard: TestPage "Released Production Order";
        NewDate: Date;
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 379091] Validating "Starting Date-Time" and "Ending Date-Time" on a new released prod. order line does not reset previously entered data.
        Initialize();

        MockProductionOrder(ReleasedProdOrder, ReleasedProdOrder.Status::Released);

        ReleasedProductionOrderCard.OpenEdit();
        ReleasedProductionOrderCard.FILTER.SetFilter("No.", ReleasedProdOrder."No.");

        NewDate := LibraryRandom.RandDate(30);

        ItemNo := LibraryInventory.CreateItemNo();
        ReleasedProductionOrderCard.ProdOrderLines.New();
        ReleasedProductionOrderCard.ProdOrderLines."Item No.".SetValue(ItemNo);
        ReleasedProductionOrderCard.ProdOrderLines."Ending Date-Time".SetValue(NewDate);
        ReleasedProductionOrderCard.ProdOrderLines."Item No.".AssertEquals(ItemNo);

        ReleasedProductionOrderCard.ProdOrderLines.New();
        ReleasedProductionOrderCard.ProdOrderLines."Item No.".SetValue(ItemNo);
        ReleasedProductionOrderCard.ProdOrderLines."Starting Date-Time".SetValue(NewDate);
        ReleasedProductionOrderCard.ProdOrderLines."Item No.".AssertEquals(ItemNo);

        ReleasedProductionOrderCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnSimulatedProductionOrderCard()
    var
        SimulatedProdOrder: Record "Production Order";
        SimulatedProductionOrderCard: TestPage "Simulated Production Order";
        NewDate: Date;
        ItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 379091] Validating "Starting Date-Time" and "Ending Date-Time" on a new simulated prod. order line does not reset previously entered data.
        Initialize();

        MockProductionOrder(SimulatedProdOrder, SimulatedProdOrder.Status::Simulated);

        SimulatedProductionOrderCard.OpenEdit();
        SimulatedProductionOrderCard.FILTER.SetFilter("No.", SimulatedProdOrder."No.");

        NewDate := LibraryRandom.RandDate(30);

        ItemNo := LibraryInventory.CreateItemNo();
        SimulatedProductionOrderCard.ProdOrderLines.New();
        SimulatedProductionOrderCard.ProdOrderLines."Item No.".SetValue(ItemNo);
        SimulatedProductionOrderCard.ProdOrderLines."Ending Date-Time".SetValue(NewDate);
        SimulatedProductionOrderCard.ProdOrderLines."Item No.".AssertEquals(ItemNo);

        SimulatedProductionOrderCard.ProdOrderLines.New();
        SimulatedProductionOrderCard.ProdOrderLines."Item No.".SetValue(ItemNo);
        SimulatedProductionOrderCard.ProdOrderLines."Starting Date-Time".SetValue(NewDate);
        SimulatedProductionOrderCard.ProdOrderLines."Item No.".AssertEquals(ItemNo);

        SimulatedProductionOrderCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnProdOrderCapacityNeed()
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderCapacityNeedPage: TestPage "Prod. Order Capacity Need";
        NewDate: Date;
        NewTime: Time;
    begin
        // [FEATURE] [Capacity Need] [UI]
        // [SCENARIO 331428] "Starting Time", "Ending Time" and "Date" controls on Capacity Need page are expressions calculated from datetime fields. Updating any of these controls will validate the corresponding field in the table.
        Initialize();

        ProdOrderCapacityNeed.Init();
        ProdOrderCapacityNeed."Prod. Order No." := LibraryUtility.GenerateGUID();
        ProdOrderCapacityNeed."Starting Date-Time" := CreateDateTime(WorkDate(), 120000T);
        ProdOrderCapacityNeed."Ending Date-Time" := CreateDateTime(WorkDate() + 30, 120000T);
        ProdOrderCapacityNeed.Insert();

        ProdOrderCapacityNeedPage.OpenEdit();
        ProdOrderCapacityNeedPage.FILTER.SetFilter("Prod. Order No.", ProdOrderCapacityNeed."Prod. Order No.");
        ProdOrderCapacityNeedPage."Starting Time".AssertEquals(DT2Time(ProdOrderCapacityNeed."Starting Date-Time"));
        ProdOrderCapacityNeedPage."Ending Time".AssertEquals(DT2Time(ProdOrderCapacityNeed."Ending Date-Time"));
        ProdOrderCapacityNeedPage.Date.AssertEquals(DT2Date(ProdOrderCapacityNeed."Ending Date-Time"));

        NewDate := LibraryRandom.RandDate(30);
        ProdOrderCapacityNeedPage.Date.SetValue(NewDate);
        ProdOrderCapacityNeed.Find();
        ProdOrderCapacityNeed.TestField(Date, NewDate);

        NewTime := DT2Time(RoundDateTime(CreateDateTime(NewDate, 120000T)));
        ProdOrderCapacityNeedPage."Starting Time".SetValue(NewTime);
        ProdOrderCapacityNeed.Find();
        ProdOrderCapacityNeed.TestField("Starting Time", NewTime);

        NewTime := DT2Time(RoundDateTime(CreateDateTime(NewDate, 120000T)));
        ProdOrderCapacityNeedPage."Ending Time".SetValue(NewTime);
        ProdOrderCapacityNeed.Find();
        ProdOrderCapacityNeed.TestField("Ending Time", NewTime);

        ProdOrderCapacityNeedPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDatesOnProdOrderRouting()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        StartingTime: Time;
        EndingTime: Time;
        StartingDate: Date;
        EndingDate: Date;
    begin
        // [FEATURE] [Production Order Routing Line] [UT]
        // [SCENARIO 331428] GetStartingEndingDateAndTime function in Prod. Order Routing Line table initializes StartingTime, EndingTime, StartingDate, EndingDate variables used as expressions on time and date controls on Prod. Order Routing page.
        Initialize();

        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine."Prod. Order No." := LibraryUtility.GenerateGUID();
        ProdOrderRoutingLine."Starting Date-Time" := CreateDateTime(WorkDate(), 120000T);
        ProdOrderRoutingLine."Ending Date-Time" := CreateDateTime(WorkDate() + 30, 120000T);

        ProdOrderRoutingLine.GetStartingEndingDateAndTime(StartingTime, StartingDate, EndingTime, EndingDate);

        Assert.AreEqual(DT2Time(ProdOrderRoutingLine."Starting Date-Time"), StartingTime, '');
        Assert.AreEqual(DT2Time(ProdOrderRoutingLine."Ending Date-Time"), EndingTime, '');
        Assert.AreEqual(DT2Date(ProdOrderRoutingLine."Starting Date-Time"), StartingDate, '');
        Assert.AreEqual(DT2Date(ProdOrderRoutingLine."Ending Date-Time"), EndingDate, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateTimeIsUpdatedOnChangeProdOrderStatus()
    var
        ProductionOrder: Record "Production Order";
        ReleasedProdOrderNo: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379013] "Starting Date-Time" and "Ending Date-Time" are updated on changing status of Production Order.
        Initialize();

        // [GIVEN] Firm Planned Production Order with "Starting Date"  = 'D1' and "Ending Date" = 'D2'.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item,
            LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2));
        ProductionOrder."Starting Date" := LibraryRandom.RandDate(10);
        ProductionOrder."Ending Date" := LibraryRandom.RandDate(20);
        ProductionOrder.Modify(true);

        // [WHEN] Change status of Firm Planned Production Order to Released.
        ReleasedProdOrderNo :=
            LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProductionOrder."No.");

        // [THEN] "Starting Date-Time" and "Ending Date-Time" are corresponded with "Starting Date" + "Starting Time" and "Ending Date" + "Ending Time".
        ProductionOrder.Get(ProductionOrder.Status::Released, ReleasedProdOrderNo);
        ProductionOrder.TestField("Starting Date-Time", CreateDateTime(ProductionOrder."Starting Date", ProductionOrder."Starting Time"));
        ProductionOrder.TestField("Ending Date-Time", CreateDateTime(ProductionOrder."Ending Date", ProductionOrder."Ending Time"));
    end;

    [Test]
    procedure FromProductionBinCodeAtWorkCenterIsUsedForProdOrderSKUExists()
    var
        Location: Record Location;
        Bin: array[4] of Record Bin;
        BinContent: Record "Bin Content";
        WorkCenter: Record "Work Center";
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Work Center] [Bin]
        // [SCENARIO 383668] Bin Code from "From-Production Bin Code" of Work Center of the SKU's routing is used with the top priority as a default bin for production order.
        Initialize();

        // [GIVEN] Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location "L" with bin "A" set up as "From-Production Bin Code".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("From-Production Bin Code", Bin[1].Code);
        Location.Modify(true);

        // [GIVEN] Create stockkeeping unit at location "L".
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, Item."No.", '');

        // [GIVEN] Bin "B" set up as Default bin at the location.
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin[2].Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Work Center at location "L". Set bin "C" as "From-Production Bin Code".
        // [GIVEN] Create a routing with the work center and update the item.
        LibraryWarehouse.CreateBin(Bin[3], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateWorkCenterWithFromProductionBinCode(WorkCenter, Location.Code, Bin[3].Code);
        UpdateItemManufacturingProperties(Item, '', CreateRouting(WorkCenter."No."));

        // [GIVEN] Second Work Center at location "L". Set bin "D" as "From-Production Bin Code".
        // [GIVEN] Create a routing with the work center and update the SKU.
        LibraryWarehouse.CreateBin(Bin[4], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateWorkCenterWithFromProductionBinCode(WorkCenter, Location.Code, Bin[4].Code);
        UpdateSKUManufacturingProperties(StockkeepingUnit, '', CreateRouting(WorkCenter."No."));

        // [GIVEN] Create production order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Validate location code = "L" on the production order.
        ProductionOrder.Validate("Location Code", Location.Code);

        // [THEN] Bin Code on the production order has been updated to "D" which is a "From-Production Bin Code" in the Work Center of the SKU's routing.
        ProductionOrder.TestField("Bin Code", Bin[4].Code);
    end;

    [Test]
    procedure FromProductionBinCodeAtWorkCenterIsUsedForProdOrder()
    var
        Location: Record Location;
        Bin: array[3] of Record Bin;
        BinContent: Record "Bin Content";
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Work Center] [Bin]
        // [SCENARIO 383668] Bin Code from "From-Production Bin Code" of Work Center of the item's routing is used with the 1st priority as a default bin for production order.
        Initialize();

        // [GIVEN] Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location "L" with bin "A" set up as "From-Production Bin Code".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("From-Production Bin Code", Bin[1].Code);
        Location.Modify(true);

        // [GIVEN] Bin "B" set up as Default bin at the location.
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin[2].Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Work Center at location "L". Set bin "C" as "From-Production Bin Code".
        // [GIVEN] Create a routing with the work center and update the item.
        LibraryWarehouse.CreateBin(Bin[3], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateWorkCenterWithFromProductionBinCode(WorkCenter, Location.Code, Bin[3].Code);
        UpdateItemManufacturingProperties(Item, '', CreateRouting(WorkCenter."No."));

        // [GIVEN] Create production order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Validate location code = "L" on the production order.
        ProductionOrder.Validate("Location Code", Location.Code);

        // [THEN] Bin Code on the production order has been updated to "C" which is a "From-Production Bin Code" in the Work Center of the item's routing.
        ProductionOrder.TestField("Bin Code", Bin[3].Code);
    end;

    [Test]
    procedure FromProductionBinCodeAtLocationIsUsedForProdOrder()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        BinContent: Record "Bin Content";
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Location] [Bin]
        // [SCENARIO 383668] Bin Code from "From-Production Bin Code" setting at location is used with the 2nd priority as a default bin for production order.
        Initialize();

        // [GIVEN] Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location "L" with bin "A" set up as "From-Production Bin Code".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("From-Production Bin Code", Bin[1].Code);
        Location.Modify(true);

        // [GIVEN] Bin "B" set up as Default bin at the location.
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin[2].Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Work Center at location "L".
        // [GIVEN] Create a routing with the work center and update the item.
        CreateWorkCenterWithFromProductionBinCode(WorkCenter, Location.Code, '');
        UpdateItemManufacturingProperties(Item, '', CreateRouting(WorkCenter."No."));

        // [GIVEN] Create and refresh production order.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), Location.Code, '');

        // [WHEN] Validate location code = "L" on the production order.
        ProductionOrder.Validate("Location Code", Location.Code);

        // [THEN] Bin Code on the production order has been updated to "A" which is a "From-Production Bin Code" at location "L".
        ProductionOrder.TestField("Bin Code", Bin[1].Code);
    end;

    [Test]
    procedure DefaultBinIsUsedForProdOrder()
    var
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Bin]
        // [SCENARIO 383668] Default Bin at location is used with the 3rd priority as a default bin for production order.
        Initialize();

        // [GIVEN] Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Bin "A" set up as Default bin at the location.
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Work Center at location "L".
        // [GIVEN] Create a routing with the work center and update the item.
        CreateWorkCenterWithFromProductionBinCode(WorkCenter, Location.Code, '');
        UpdateItemManufacturingProperties(Item, '', CreateRouting(WorkCenter."No."));

        // [GIVEN] Create and refresh production order.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), Location.Code, '');

        // [WHEN] Validate location code = "L" on the production order.
        ProductionOrder.Validate("Location Code", Location.Code);

        // [THEN] Bin Code on the production order has been updated to "A" which is a default bin at location "L".
        ProductionOrder.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    procedure FromProductionBinCodeAtWorkCenterIsUsedForProdOrderLine()
    var
        Location: Record Location;
        Bin: Record Bin;
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Work Center] [Bin] [Prod. Order Line]
        // [SCENARIO 383668] "From-Production Bin Code" from Work Center is used when you manually add a new prod. order line.
        Initialize();

        // [GIVEN] Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Create production order at "L".
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Work Center at location "L".
        // [GIVEN] Create a routing with the work center and update the item.
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateWorkCenterWithFromProductionBinCode(WorkCenter, Location.Code, Bin.Code);
        UpdateItemManufacturingProperties(Item, '', CreateRouting(WorkCenter."No."));

        // [WHEN] Add a prod. order line to the production order.
        ProdOrderLine.Init();
        ProdOrderLine.Validate(Status, ProductionOrder.Status);
        ProdOrderLine.Validate("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.Validate("Line No.", LibraryUtility.GetNewRecNo(ProdOrderLine, ProdOrderLine.FieldNo("Line No.")));
        ProdOrderLine.Validate("Item No.", Item."No.");

        // [THEN]
        ProdOrderLine.TestField("Location Code", Location.Code);
        ProdOrderLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [HandlerFunctions('ProdOrderRoutingPageHandler')]
    procedure ProdOrderLineBinCodeNotUpdatedWhenOpenAndViewProdOrderRouting()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Work Center] [Bin] [Prod. Order Line] [Prod. Order Routing]
        // [SCENARIO 383668] When a user open and closes Prod. Order Routing page, this action does not update bin code on the prod. order line.
        Initialize();

        // [GIVEN] Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Work Center at location "L". Set bin "B" as "From-Production Bin Code".
        // [GIVEN] Create a routing with the work center and update the item.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateWorkCenterWithFromProductionBinCode(WorkCenter, Location.Code, Bin[1].Code);
        UpdateItemManufacturingProperties(Item, '', CreateRouting(WorkCenter."No."));

        // [GIVEN] Create and refresh production order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), Location.Code, '');

        // [GIVEN] Update Bin Code to "C" on the prod. order line.
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.Validate("Bin Code", Bin[2].Code);
        ProdOrderLine.Modify(true);

        // [WHEN] Open and close Prod. Order Routing page from the prod. order line.
        ProdOrderLine.ShowRouting();

        // [THEN] Bin Code on the prod. order line remains "C".
        ProdOrderLine.Find();
        ProdOrderLine.TestField("Bin Code", Bin[2].Code);
    end;

    [Test]
    [HandlerFunctions('ProdOrderRoutingAddOperationPageHandler')]
    procedure ProdOrderLineBinCodeUpdatedWhenOpenAndEditProdOrderRouting()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        WorkCenter: array[2] of Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Work Center] [Bin] [Prod. Order Line] [Prod. Order Routing]
        // [SCENARIO 383668]
        Initialize();

        // [GIVEN] Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location "L".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Create 2 Work Centers "WC1" and "WC2" at location "L". Set bin code "B1" on "WC1" and bin code "B2" on "WC2".
        // [GIVEN] Create a routing with the work center "WC1" and update the item.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateWorkCenterWithFromProductionBinCode(WorkCenter[1], Location.Code, Bin[1].Code);
        CreateWorkCenterWithFromProductionBinCode(WorkCenter[2], Location.Code, Bin[2].Code);
        UpdateItemManufacturingProperties(Item, '', CreateRouting(WorkCenter[1]."No."));

        // [GIVEN] Create and refresh production order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), Location.Code, '');

        // [WHEN] Open Prod. Order Routing page from the prod. order line and add a new operation with work center "WC2".
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        LibraryVariableStorage.Enqueue(WorkCenter[2]."No.");
        ProdOrderLine.ShowRouting();

        // [THEN] Bin Code on the prod. order line is updated to "B2".
        ProdOrderLine.Find();
        ProdOrderLine.TestField("Bin Code", Bin[2].Code);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure FinishProdOrderRoutingOnChangeProdOrderStatusToFinished()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Prod. Order Routing]
        // [SCENARIO 387763] Routing Status on prod. order routing is changed to finish when Stan finishes the production order.
        Initialize();

        // [GIVEN] Production item with routing.
        CreateProductionItem(Item, '');
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Released production order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [WHEN] Change the status of the production order to "Finished".
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] "Routing Status" on the prod. order routing is changed to "Finished".
        FindProdOrderRoutingLine(ProdOrderRoutingLine, Item."No.");
        ProdOrderRoutingLine.TestField("Routing Status", ProdOrderRoutingLine."Routing Status"::Finished);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    procedure ItemRdngPrecisionIsIgnoredOnCalcConsumptionAfterPickInProductionJnl()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        DummyItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Consumption] [Pick] [Production Journal]
        // [SCENARIO 387690] Production journal shows picked quantity of a component even if is less than "Rounding Precision" value on the item.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Component item "C" with "Rounding Precision" = 100.
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Rounding Precision", Qty);
        CompItem.Modify(true);

        // [GIVEN] Production item "P" with component "C".
        CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem, 1);
        CreateProductionItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Post 100 pcs of "C" to inventory to directed put-away and pick location.
        UpdateInventoryWithWhseItemJournal(CompItem, LocationWhite, Qty);

        // [GIVEN] Released production order for 100 pcs of "P".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Qty, LocationWhite.Code, '');

        // [GIVEN] Create warehouse pick.
        // [GIVEN] Set "Qty. to Handle" = 75 on pick lines and register.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        WarehouseActivityLine.SetRange("Item No.", CompItem."No.");

        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", Qty * 3 / 4);
            WarehouseActivityLine.Modify();
        until WarehouseActivityLine.Next() = 0;

        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Open production journal.
        // [THEN] The consumption line for component "C" in the production journal shows quantity = 75.
        OpenProductionJournalPage(
          ProductionOrder, CompItem."No.", ProdItem."No.", Qty * 3 / 4, DummyItemJournalLine."Entry Type"::Consumption);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ItemRdngPrecisionIsIgnoredOnCalcConsumptionAfterPickInConsumptionJnl()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Consumption] [Pick] [Consumption Journal]
        // [SCENARIO 387690] Consumption journal shows picked quantity of a component even if is less than "Rounding Precision" value on the item.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Component item "C" with "Rounding Precision" = 100.
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Rounding Precision", Qty);
        CompItem.Modify(true);

        // [GIVEN] Production item "P" with component "C".
        CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem, 1);
        CreateProductionItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Post 100 pcs of "C" to inventory to directed put-away and pick location.
        UpdateInventoryWithWhseItemJournal(CompItem, LocationWhite, Qty);

        // [GIVEN] Released production order for 100 pcs of "P".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Qty, LocationWhite.Code, '');

        // [GIVEN] Create warehouse pick.
        // [GIVEN] Set "Qty. to Handle" = 75 on pick lines and register.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        WarehouseActivityLine.SetRange("Item No.", CompItem."No.");

        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", Qty / 2);
            WarehouseActivityLine.Modify();
        until WarehouseActivityLine.Next() = 0;

        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Calculate consumption in consumption journal.
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrder."No.", ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        // [THEN] A consumption journal line for 75 pcs of item "C" is created.
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        ItemJournalLine.TestField("Item No.", CompItem."No.");
        ItemJournalLine.TestField(Quantity, Qty / 2);
    end;

    [Test]
    procedure ItemRdngPrecisionOnMultipleCalcConsumptionAfterPickInConsumptionJnl()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Consumption] [Pick] [Consumption Journal]
        // [BUG 439491] Dealing with rounding precision 1, and calc. consumption using "actual output" option, rounding is consistant. 
        Initialize();

        // [GIVEN] Component item "C"
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Production item "P" with component "C".
        CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem, 100.6);
        CreateProductionItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Create and Post 200 pcs of "C".
        CreateAndPostItemJournal(ItemJournalLine."Entry Type"::"Positive Adjmt.", CompItem."No.", 200);

        // [GIVEN] Released production order for 1 pcs of "P".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", 1, '', '');

        // [GIVEN] Open output journal and explode routing for the production order.
        // [GIVEN] Set the output quantity.
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrder."No.");
        ItemJournalLine.Validate("Output Quantity", ProductionOrder.Quantity);
        ItemJournalLine.Modify(true);

        // [WHEN] Post the output journal.
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);

        // [WHEN] Calculate consumption in consumption journal.
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);

        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");

        LibraryManufacturing.CalculateConsumptionForJournal(
          ProductionOrder, ProdOrderComponent, WorkDate(), true);

        // [THEN] A consumption journal line for 101 pcs of item "C" is created. With default rounding precision 1
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        ItemJournalLine.TestField("Item No.", CompItem."No.");
        ItemJournalLine.TestField(Quantity, 101);

        // [THEN] The consumption journal line has item tracking and can be successfully posted.
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        // [WHEN] Second time Calculate consumption in consumption journal
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);

        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");

        LibraryManufacturing.CalculateConsumptionForJournal(
          ProductionOrder, ProdOrderComponent, WorkDate(), true);

        // [THEN] A consumption journal line is not created since 0 pcs of item "C" is avalible.
        asserterror SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        Assert.ExpectedError(ItemJournalLineExistErr);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalHandler,ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure RoundingIsIgnoredOnNonLastLineOnProductionJournal()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // Initialize and create a workcenter
        Initialize();
        CreateWorkCenter(WorkCenter, false);

        // Create a routing with 2 routing lines, first line having a 0.1% scrap percentage
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLine.Validate("Scrap Factor %", 0.1);
        RoutingLine.Modify(true);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // Create Item with replenishment system = production
        CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");

        // Create 2 item unit of measures with base having a rounding precision as 1 and assign the base unit of measure to the created item.
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        ItemUnitOfMeasure.Validate("Qty. Rounding Precision", 1);
        ItemUnitOfMeasure.Modify(true);
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 6);

        // Create a produciton order for the item and assign the non-base item unit of measure
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", 1);
        LibraryManufacturing.CreateProdOrderLine(ProductionOrderLine, ProductionOrderLine.Status::Released, ProductionOrder."No.", Item."No.", '', '', 1);
        ProductionOrderLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProductionOrderLine.Modify(true);

        // Refresh production order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, false, false);

        // 'Released Production Order' and navigate to the created produciton order
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // Setup data to be passed to the Produciton Jounral handler. Journal is partiall posted
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(2); // Number of lines
        LibraryVariableStorage.Enqueue(1.001); // 'Expected Output Quantity' on first line
        LibraryVariableStorage.Enqueue(1); // Set 'Expected Output Quantity' value on first line
        LibraryVariableStorage.Enqueue(1); // 'Expected Output Quantity' on second  line
        LibraryVariableStorage.Enqueue(0); // Set 'Expected Output Quantity' value on second line
        LibraryVariableStorage.Enqueue(true); // Post the journal
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();

        // Setup data to be passed to the Production Jounrnal. Data is validated and remaining is posted without errors 
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(2); // Number of lines
        LibraryVariableStorage.Enqueue(0.001); // 'Expected Output Quantity' on first line. 0.001 is left as rounding does not happen on non-last lines
        LibraryVariableStorage.Enqueue(0.001); // Set 'Expected Output Quantity' value on first line
        LibraryVariableStorage.Enqueue(1); // 'Expected Output Quantity' on second  line
        LibraryVariableStorage.Enqueue(1); // Set 'Expected Output Quantity' value on second line
        LibraryVariableStorage.Enqueue(true); // Post the journal
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();
    end;

    [Test]
    procedure StartAndEndingTimeIsAlignedWhenManufacturingSetupHasNoNormalTimeSetup()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
    begin
        Initialize();

        // [GIVEN] An item.
        CreateItem(Item);

        // [GIVEN] Manufacturing setup with no normal starting/ending time.
        ManufacturingSetup.Get();
        ManufacturingSetup."Normal Starting Time" := 0T;
        ManufacturingSetup."Normal Ending Time" := 0T;
        ManufacturingSetup.Modify();

        // [WHEN] Creating a new released production order for the item.
        ProductionOrder.InitRecord();
        ProductionOrder.Validate("Source No.", Item."No.");
        ProductionOrder.Insert(true);

        // [THEN] Starting/ending time should be aligned with starting/ending datetime.
        Assert.AreEqual(
            DT2Time(ProductionOrder."Starting Date-Time"),
            ProductionOrder."Starting Time",
            'Expected starting time to be in aligned with starting date time'
        );
        Assert.AreEqual(
            DT2Time(ProductionOrder."Ending Date-Time"),
            ProductionOrder."Ending Time",
            'Expected ending time to be in aligned with ending date time'
        );
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcConsumptionConsumesComponentCompletely()
    var
        ItemProduct: Record Item;
        ItemComponent: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        NonBaseUOMComp: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        BaseUOMComp: Record "Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO] Calculate Consumption and posting consume the components completely and does not leave behind anything from rounding

        // [GIVEN] Add yourselves as Warehouse Employee to WHITE location
        Initialize();

        // [GIVEN] Create ItemProduct. BaseUoM = PCS. Additional UoM = BOX = 6. No rounding.
        NonBaseQtyPerUOM := 6;
        SetupUoMTest(ItemProduct, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);

        // [GIVEN] Create ItemComponent. BaseUoM = PCS. UoM Rounding 1. Consumption rounding = 0.00001
        QtyRoundingPrecision := 1;
        SetupUoMTest(ItemComponent, ItemUOM, BaseUOMComp, NonBaseUOMComp, NonBaseQtyPerUOM, QtyRoundingPrecision);
        ItemComponent."Rounding Precision" := 0.00001;
        ItemComponent.Modify();

        // [GIVEN] Create and post Warehouse Item Journal for WHITE location for ItemComponent, Qty = 12 PCS.
        UpdateInventoryWithWhseItemJournal(ItemComponent, LocationWhite, 12);

        // [GIVEN] Create a new Released Production order and add line ItemProduct, Qty 2.00002 BOX, Location = WHITE.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ItemProduct."No.", 2.00002, LocationWhite.Code, LocationWhite."From-Production Bin Code");
        ProductionOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProductionOrderLine.FindFirst();
        ProductionOrderLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        ProductionOrderLine.Modify(true);

        // [WHEN] Components are setup. Add line, ItemComponent, Location = WHITE, Qty Per = 72 pcs
        CreateProdOrderComponentForUoMTest(ProdOrderComponent, ProductionOrder, ProductionOrderLine, ItemComponent, NonBaseUOMComp);
        ProdOrderComponent.Validate("Quantity per", 12);
        ProdOrderComponent.Validate("Location Code", LocationWhite.Code);
        ProdOrderComponent.Modify(true);

        // [THEN] Expected quantity is rounded with the rounding precision defined.
        ProdOrderComponent.TestField("Expected Quantity", 24);
        ProdOrderComponent.TestField("Expected Qty. (Base)", 144);

        // [GIVEN] Create and register pick for the production order
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehouseActivity(ProductionOrder."No.", "Warehouse Activity Type"::Pick);  // Register the Pick created.

        // [WHEN] Consumption is calculated and posted. 
        CalculateAndPostConsumptionJournal(ProductionOrder."No.");

        // [WHEN] Calculate consumption in consumption journal.
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrder."No.", ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        // [THEN] A consumption journal line for 0 pcs of ItemComponent is created.
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        ItemJournalLine.TestField("Item No.", ItemComponent."No.");
        ItemJournalLine.TestField(Quantity, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThrowQtyRoundingErrorWhenExpectedQtyIsOfInvalidPrecision()
    var
        ItemProduct: Record Item;
        ItemComponent: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO] Throw rounding error when setting 'Quantity Per' causes the 'Expected Quantity' to be of a invalid precision

        // [GIVEN] Add yourselves as Warehouse Employee to WHITE location
        Initialize();

        // [GIVEN] Create ItemProduct. BaseUoM = PCS. Additional UoM = BOX = 6. No rounding.
        NonBaseQtyPerUOM := 6;
        SetupUoMTest(ItemProduct, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);

        // [GIVEN] Create ItemComponent. BaseUoM = PCS. UoM Rounding 1. Consumption rounding = 0.00001
        QtyRoundingPrecision := 1;
        SetupUoMTest(ItemComponent, ItemUOM, BaseUOM, NonBaseUOM, 0, QtyRoundingPrecision);
        ItemComponent."Rounding Precision" := 0.00001;
        ItemComponent.Modify();

        // [GIVEN] Add ItemComponents to the inventory in WHITE location
        CreateAndPostItemJournalLine(ItemComponent."No.", 1000, LocationWhite.Code, '');

        // [GIVEN] Create and post Warehouse Item Journal for WHITE location for ItemComponent, Qty = 12 PCS.
        UpdateInventoryWithWhseItemJournal(ItemComponent, LocationWhite, 12);

        // [GIVEN] Create a new Released Production order and add line ItemProduct, Qty 2.00002 BOX, Location = WHITE.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ItemProduct."No.", 2.00002, LocationWhite.Code, '');
        ProductionOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProductionOrderLine.FindFirst();
        ProductionOrderLine.Validate("Unit of Measure Code", NonBaseUOM.Code);
        ProductionOrderLine.Modify(true);

        // [WHEN] Components are setup. Add line, ItemComponent, Location = WHITE, Qty Per = 72 pcs
        CreateProdOrderComponentForUoMTest(ProdOrderComponent, ProductionOrder, ProductionOrderLine, ItemComponent, BaseUOM);

        // [THEN] Error is thrown because the 'Expected Quantity' gets evaluated to an invalid precision-
        asserterror ProdOrderComponent.Validate("Quantity per", 72);
        Assert.ExpectedError(InvalidPrecisionErr);
    end;

    [ModalPageHandler]
    procedure ProductionJournalModalHandler(var ProductionJournal: TestPage "Production Journal")
    var
        NoOfLines: Integer;
        Index: Integer;
    begin
        NoOfLines := LibraryVariableStorage.DequeueInteger();

        if NoOfLines <> 0 then
            ProductionJournal.First();

        for Index := 0 to NoOfLines do begin
            ProductionJournal."Output Quantity".AssertEquals(LibraryVariableStorage.DequeueDecimal());
            ProductionJournal."Output Quantity".SetValue(LibraryVariableStorage.DequeueDecimal());
            ProductionJournal.Next();
            Index += 1;
        end;

        if LibraryVariableStorage.DequeueBoolean() then
            ProductionJournal.Post.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThrowQtyRoundingErrorOnProdOrdLine()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO 392869] Throw Error while Rounding Item Quantity on Production Order Line based on UOM Rounding Precision.
        // [GIVEN] An item with base UoM, rounding precision and non-base UoM.
        Initialize();
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(2, 10), QtyRoundingPrecision);
        SetupUoMTest(Item, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0 in production line.
        CreateProdOrderAndLineForUoMTest(ProductionOrder, ProductionOrderLine, Item, 1, NonBaseUOM, 0);

        // [THEN] Throw error due to rounding of quantity to 0.
        asserterror ProductionOrderLine.Validate(Quantity, 1 / LibraryRandom.RandIntInRange(101, 1000));
        Assert.ExpectedError(QuantityImbalanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionSpecifiedOnProdOrdLine()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        QtyToSet: Decimal;
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO 392869] Item Base Quantity should be Rounded on Prod Order Line based on Specified Rounding Precision.
        // [GIVEN] An item with base UoM, rounding precision and non-base UoM.
        Initialize();
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(2, 10), QtyRoundingPrecision);
        SetupUoMTest(Item, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);

        // [WHEN] Adding an item with Non Base UoM and quantity to the production order line.
        QtyToSet := LibraryRandom.RandDec(10, 7);
        CreateProdOrderAndLineForUoMTest(ProductionOrder, ProductionOrderLine, Item, 1, NonBaseUOM, QtyToSet);

        // [THEN] The base quantity should be rounded with the specified rounding precision.
        Assert.AreEqual(Round(NonBaseQtyPerUOM * ProductionOrderLine.Quantity, QtyRoundingPrecision),
                        ProductionOrderLine."Quantity (Base)",
                        'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BaseQtyIsRoundedWithRoundingPrecisionUnspecifiedOnProdOrdLine()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        QtyToSet: Decimal;
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO 392869] Item Base Quantity should be Rounded on Prod Order Line based on default rounding precision.
        // [GIVEN] An item with base UoM, rounding precision and non-base UoM.
        Initialize();
        NonBaseQtyPerUOM := LibraryRandom.RandDec(10, 3);
        SetupUoMTest(Item, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);

        // [WHEN] Adding an item with Non Base UoM and quantity to the production order line.
        QtyToSet := LibraryRandom.RandDec(10, 7);
        CreateProdOrderAndLineForUoMTest(ProductionOrder, ProductionOrderLine, Item, 1, NonBaseUOM, QtyToSet);

        // [THEN] The quantity is rounded with the default rounding precision.
        Assert.AreEqual(Round(QtyToSet, 0.00001),
                        ProductionOrderLine.Quantity,
                        'Quantity is not rounded correctly.');

        // [THEN] The base quantity is rounded with the default rounding precision.
        Assert.AreEqual(Round(NonBaseQtyPerUOM * ProductionOrderLine.Quantity, 0.00001),
                        ProductionOrderLine."Quantity (Base)",
                        'Base quantity is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThrowQtyRoundingErrorOnProdOrdComponent()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO 392869] Throw Error while Rounding Quantities on Production Order Component based on UOM Rounding Precision.
        // [GIVEN] An item with base UoM, rounding precision and non-base UoM.
        Initialize();
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(2, 10), QtyRoundingPrecision);
        SetupUoMTest(Item, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);

        // [GIVEN] Released Production order and production line with Non Base UoM and quantities as 1.
        CreateProdOrderAndLineForUoMTest(ProductionOrder, ProductionOrderLine, Item, 1, NonBaseUOM, 1);

        // [GIVEN] Production Order Component for production order line  with Non Base UoM.
        CreateProdOrderComponentForUoMTest(ProdOrderComponent, ProductionOrder, ProductionOrderLine, Item, NonBaseUOM);

        // [WHEN] Quantity is set to a value that rounds the base quantity to 0 in production order component.
        asserterror ProdOrderComponent.Validate("Quantity per", 1 / LibraryRandom.RandIntInRange(101, 1000));

        // [THEN] Throw error due to rounding of quantity to 0.
        Assert.ExpectedError(QuantityImbalanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ThrowRoundingErrorOnProdOrdCompRemainingQty()
    var
        ItemProdOrderLine: Record Item;
        ItemProdOrderComp: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO 392869] Throw Error while Rounding Remaining Quantity Base on Production Order Component based on UOM Rounding Precision.
        Initialize();

        // [GIVEN] Released Production order for source Item with Quantity 1
        // [GIVEN] Production order line containing an Item with base UoM, UoM rounding precision, non-base UoM and Quantity = "1".
        QtyRoundingPrecision := 1;
        NonBaseQtyPerUOM := 1;
        SetupUoMTest(ItemProdOrderLine, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        CreateProdOrderAndLineForUoMTest(ProductionOrder, ProductionOrderLine, ItemProdOrderLine, 1, BaseUOM, 1);

        // [GIVEN] Production order component for the Production order line containing an item with base UoM, UoM rounding precision, non-base UoM.
        // [GIVEN] Item's rounding precision = 0.00001.
        QtyRoundingPrecision := 1;
        NonBaseQtyPerUOM := 2;
        SetupUoMTest(ItemProdOrderComp, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        ItemProdOrderComp."Rounding Precision" := 0.00001;
        ItemProdOrderComp.Modify();
        CreateProdOrderComponentForUoMTest(ProdOrderComponent, ProductionOrder, ProductionOrderLine, ItemProdOrderComp, NonBaseUOM);

        // [GIVEN] 1000 Quantity of ItemProdOrderComp inventory.
        CreateAndPostItemJournalLine(ItemProdOrderComp."No.", 1000, '', '');

        // [WHEN] Consumption Quantity for the component item is 1 in base quantity.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, 1);

        // [WHEN] Throw error due to rounding of Base Remaining quantity to 0 when "Quantity per" is 0.7.
        asserterror ProdOrderComponent.Validate("Quantity per", 0.070);

        // [THEN] Verify expected error
        Assert.ExpectedError(QuantityImbalanceErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyAreRoundedWithRoundingPrecisionSpecifiedOnProdOrderComponent()
    var
        ItemProduct: Record Item;
        ItemComponent: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        QtyToSetProdLine: Decimal;
        QtyPerToSetProdComp: Decimal;
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO 392869] Quantities should be Rounded on Production Order Component based on Specified Rounding Precision.
        Initialize();
        // [GIVEN] Released Production order for source Item with Quantity 1
        // [GIVEN] Production order line containing an Item with base UoM, UoM rounding precision, non-base UoM and Quantity.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(2, 10), 0.00001);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandIntInRange(2, 10), QtyRoundingPrecision);

        SetupUoMTest(ItemProduct, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        QtyToSetProdLine := LibraryRandom.RandDec(10, 2);
        CreateProdOrderAndLineForUoMTest(ProductionOrder, ProductionOrderLine, ItemProduct, 1, NonBaseUOM, QtyToSetProdLine);

        // [GIVEN] Production order component for the Production order line containing an item with base UoM, UoM rounding precision, non-base UoM.
        QtyRoundingPrecision := Round(1 / LibraryRandom.RandIntInRange(1, 10), 0.01);
        NonBaseQtyPerUOM := Round(LibraryRandom.RandDec(10, 3), QtyRoundingPrecision);
        SetupUoMTest(ItemComponent, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        ItemComponent."Rounding Precision" := 1 / LibraryRandom.RandIntInRange(1, 10);
        ItemComponent.Modify();
        CreateProdOrderComponentForUoMTest(ProdOrderComponent, ProductionOrder, ProductionOrderLine, ItemComponent, NonBaseUOM);

        // [WHEN] Adding "Quantity per" on Production order Component.
        QtyPerToSetProdComp := LibraryRandom.RandDec(10, 7);
        ProdOrderComponent.Validate("Quantity per", QtyPerToSetProdComp);

        // [THEN] The base quantity should be rounded with production component's rounding precision.
        Assert.AreEqual(Round(NonBaseQtyPerUOM * ProdOrderComponent.Quantity, QtyRoundingPrecision),
                        ProdOrderComponent."Quantity (Base)",
                        'ProdOrderComponent."Quantity (Base)" is not rounded correctly.');

        // [THEN] The expected quantity should be rounded up with item's rounding precision.
        Assert.AreEqual(Round(ProdOrderComponent."Expected Qty. (Base)" / ProdOrderComponent."Qty. per Unit of Measure", 0.00001), ProdOrderComponent."Expected Quantity", 'ProdOrderComponent."Expected Quantity" is not rounded correctly.');

        // [THEN] The base expected quantity should be rounded with production component's rounding precision.
        Assert.AreEqual(Round(ProdOrderComponent."Expected Quantity" * NonBaseQtyPerUOM,
                        QtyRoundingPrecision), ProdOrderComponent."Expected Qty. (Base)",
                        'ProdOrderComponent."Expected Quantity (Base)" is not rounded correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyAreRoundedWithRoundingPrecisionUnspecifiedOnProdOrderComponent()
    var
        ItemProdOrderLine: Record Item;
        ItemProdOrderComp: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        QtyToSetProdLine: Decimal;
        QtyToSetProdComp: Decimal;
        NonBaseQtyPerUOM: Decimal;
        QtyRoundingPrecision: Decimal;
    begin
        // [SCENARIO 392869] Quantities should be Rounded on Production Order Component based on Unspecified Rounding Precision.
        Initialize();
        // [GIVEN] Released Production order for source Item with Quantity 1
        // [GIVEN] Production order line containing an Item with base UoM, non-base UoM, Quantity and default UoM rounding precision.
        NonBaseQtyPerUOM := LibraryRandom.RandDec(10, 3);
        SetupUoMTest(ItemProdOrderLine, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        QtyToSetProdLine := LibraryRandom.RandDec(10, 2);
        CreateProdOrderAndLineForUoMTest(ProductionOrder, ProductionOrderLine, ItemProdOrderLine, 1, NonBaseUOM, QtyToSetProdLine);

        // [GIVEN] Production order component for the Production order line containing an item with base UoM, unspecified UoM rounding precision, non-base UoM.
        NonBaseQtyPerUOM := LibraryRandom.RandDec(10, 3);
        SetupUoMTest(ItemProdOrderComp, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, QtyRoundingPrecision);
        ItemProdOrderComp."Rounding Precision" := 1 / LibraryRandom.RandIntInRange(1, 10);
        ItemProdOrderComp.Modify();
        CreateProdOrderComponentForUoMTest(ProdOrderComponent, ProductionOrder, ProductionOrderLine, ItemProdOrderComp, NonBaseUOM);

        // [WHEN] Adding "Quantity per" on Production order Component.
        QtyToSetProdComp := LibraryRandom.RandDec(10, 7);
        ProdOrderComponent.Validate("Quantity per", QtyToSetProdComp);

        // [THEN] The quantity should be rounded with default rounding precision.
        Assert.AreEqual(Round(QtyToSetProdComp, 0.00001),
                        ProdOrderComponent.Quantity,
                        'ProdOrderComponent.Quantity is not rounded correctly.');

        // [THEN] The base quantity should be rounded with default rounding precision.
        Assert.AreEqual(Round(NonBaseQtyPerUOM * ProdOrderComponent.Quantity, 0.00001),
                        ProdOrderComponent."Quantity (Base)",
                        'ProdOrderComponent."Quantity (Base)" is not rounded correctly.');

        // [THEN] The expected quantity should be rounded up with item's rounding precision.
        Assert.AreEqual(Round(ProdOrderComponent.Quantity * QtyToSetProdLine,
                        ItemProdOrderComp."Rounding Precision", '>'),
                        ProdOrderComponent."Expected Quantity", 'ProdOrderComponent."Expected Quantity" is not rounded correctly.');

        // [THEN] The base expected quantity should be rounded with default rounding precision.
        Assert.AreEqual(Round(ProdOrderComponent."Expected Quantity" * NonBaseQtyPerUOM,
                        0.00001), ProdOrderComponent."Expected Qty. (Base)",
                        'ProdOrderComponent."Expected Quantity (Base)" is not rounded correctly.');
    end;

    [Test]
    procedure UpdatingProdOrderRoutingLineAfterManuallyScheduledRoutingLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        i: Integer;
    begin
        // [FEATURE] [Routing]
        // [SCENARIO 397089] A user can set later starting date on prod. order routing line following the one set up for manually scheduling.
        Initialize();

        // [GIVEN] Routing with 4 lines.
        // [GIVEN] First two lines have zero setup and run time.
        // [GIVEN] Last two lines have setup and run time populated.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for i := 1 to 2 do begin
            LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine, '', Format(i), RoutingLine.Type::"Work Center", WorkCenter."No.");
        end;
        for i := 3 to 4 do begin
            LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine, '', Format(i), RoutingLine.Type::"Work Center", WorkCenter."No.");
            RoutingLine.Validate("Setup Time", 10);
            RoutingLine.Validate("Run Time", 20);
            RoutingLine.Modify(true);
        end;
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Create item and update routing no.
        LibraryInventory.CreateItem(Item);
        UpdateItemManufacturingProperties(Item, '', RoutingHeader."No.");

        // [GIVEN] Create and refresh released production order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", 1, '', '');

        // [GIVEN] Set "Schedule Manually" to all prod. order routing lines except the last one.
        FindProdOrderRoutingLine(ProdOrderRoutingLine, Item."No.");
        ProdOrderRoutingLine.ModifyAll("Schedule Manually", true, true);
        ProdOrderRoutingLine.FindLast();
        ProdOrderRoutingLine.Validate("Schedule Manually", false);

        // [WHEN] Update "Starting Date" on the last prod. order routing line to the nearest non-working day (Saturday).
        ProdOrderRoutingLine.Validate("Starting Date", CalcDate('<WD6>', WorkDate()));

        // [THEN] No error message is shown.
        // [THEN] The "Starting Date" is updated to the nearest working day (next Monday).
        Assert.IsTrue(ProdOrderRoutingLine."Starting Date" > CalcDate('<WD6>', WorkDate()), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure RunTimeCapacityNeedOnManuallyScheduledRoutingLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[4] of Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        i: Integer;
    begin
        // [FEATURE] [Routing] [Capacity Need]
        // [SCENARIO 397134] Capacity need for run time is re-created for prod. order routing line with "Manually Schedule" = TRUE (routing line "1") when a user reschedules a routing line that follows the line "1".
        Initialize();

        // [GIVEN] Routing with 4 lines.
        // [GIVEN] First two lines have zero setup and run time.
        // [GIVEN] Last two lines have setup and run time populated.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for i := 1 to 2 do begin
            LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[i], '', Format(i), RoutingLine[i].Type::"Work Center", WorkCenter."No.");
        end;
        for i := 3 to 4 do begin
            LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[i], '', Format(i), RoutingLine[i].Type::"Work Center", WorkCenter."No.");
            RoutingLine[i].Validate("Setup Time", 10);
            RoutingLine[i].Validate("Run Time", 20);
            RoutingLine[i].Modify(true);
        end;
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Create item and update routing no.
        LibraryInventory.CreateItem(Item);
        UpdateItemManufacturingProperties(Item, '', RoutingHeader."No.");

        // [GIVEN] Create and refresh released production order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", 1, '', '');

        // [GIVEN] Set "Schedule Manually" = TRUE and "Routing Status" = Finished on the 1st operation in the prod. order routing.
        FindProdOrderRoutingLineWithSpecifiedOperationNo(ProdOrderRoutingLine, Item."No.", RoutingLine[1]."Operation No.");
        ProdOrderRoutingLine.Validate("Schedule Manually", true);
        ProdOrderRoutingLine.Validate("Routing Status", ProdOrderRoutingLine."Routing Status"::Finished);
        ProdOrderRoutingLine.Modify(true);

        // [GIVEN] Set "Schedule Manually" = TRUE and "Routing Status" = Finished on the 2nd operation in the prod. order routing.
        FindProdOrderRoutingLineWithSpecifiedOperationNo(ProdOrderRoutingLine, Item."No.", RoutingLine[2]."Operation No.");
        ProdOrderRoutingLine.Validate("Schedule Manually", true);
        ProdOrderRoutingLine.Validate("Routing Status", ProdOrderRoutingLine."Routing Status"::Finished);
        ProdOrderRoutingLine.Modify(true);

        // [GIVEN] Set "Schedule Manually" = TRUE on the 3rd operation in the prod. order routing.
        FindProdOrderRoutingLineWithSpecifiedOperationNo(ProdOrderRoutingLine, Item."No.", RoutingLine[3]."Operation No.");
        ProdOrderRoutingLine.Validate("Schedule Manually", true);
        ProdOrderRoutingLine.Modify(true);

        // [WHEN] Update "Starting Date" on the last prod. order routing line (4th operation) to a later date.
        FindProdOrderRoutingLineWithSpecifiedOperationNo(ProdOrderRoutingLine, Item."No.", RoutingLine[4]."Operation No.");
        ProdOrderRoutingLine.Validate("Starting Date", CalcDate('<WD6>', WorkDate()));
        ProdOrderRoutingLine.Modify(true);

        // [THEN] Prod. order capacity need for the 3rd (previous) operation shows correct run time.
        FindProdOrderRoutingLineWithSpecifiedOperationNo(ProdOrderRoutingLine, Item."No.", RoutingLine[3]."Operation No.");
        FindProdOrderCapacityNeed(ProdOrderCapacityNeed, ProdOrderRoutingLine);
        ProdOrderCapacityNeed.TestField("Allocated Time", ProdOrderRoutingLine."Run Time");
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
    procedure LastModifiedDateUpdatedOnChangeDueDate()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 410598] Update "Last Date Modified" on change due date in production order.
        Initialize();

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(10));
        ProductionOrder."Last Date Modified" := 0D;
        ProductionOrder.Modify();

        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", LibraryRandom.RandDateFrom(ProductionOrder."Due Date", 10));

        ProductionOrder.TestField("Last Date Modified", Today);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UoMRoundingExpectedQuantityCalculatedCorrectly()
    var
        ItemProduct: Record Item;
        ItemComponent: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        NonBaseUOM: Record "Unit of Measure";
        NonBaseUOMComp: Record "Unit of Measure";
        BaseUOM: Record "Unit of Measure";
        BaseUOMComp: Record "Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        NonBaseQtyPerUOM: Decimal;
    begin
        // [SCENARIO]

        // [GIVEN] Add yourselves as Warehouse Employee to WHITE location
        Initialize();

        // [GIVEN] ItemProduct. BaseUoM = PCS. Additional UoM = BOX = 180. No rounding.
        NonBaseQtyPerUOM := 180;
        SetupUoMTest(ItemProduct, ItemUOM, BaseUOM, NonBaseUOM, NonBaseQtyPerUOM, 0);

        // [GIVEN] ItemComponent. BaseUoM = PCS. Consumption rounding = 0.00001
        SetupUoMTest(ItemComponent, ItemUOM, BaseUOMComp, NonBaseUOMComp, 0, 0);
        ItemComponent."Rounding Precision" := 0.00001;
        ItemComponent.Modify();

        // [GIVEN] Production BOM for ItemProduct with Non-base UoM and with ItemComponent Quantity Per = 0.00027.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, NonBaseUOM.Code);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemComponent."No.", 0.00027);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        ItemProduct.Validate("Replenishment System", ItemProduct."Replenishment System"::"Prod. Order");
        ItemProduct.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ItemProduct.Modify(true);

        // [GIVEN] Create a new Released Production order and add line ItemProduct, Qty 39360 PCS.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item,
            ItemProduct."No.",
            39360
        );
        LibraryManufacturing.CreateProdOrderLine(
            ProductionOrderLine,
            ProductionOrderLine.Status::Released,
            ProductionOrder."No.",
            ItemProduct."No.",
            '',
            '',
            39360
        );

        // [WHEN] Refreshing released production order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Expected quantity for component is correctly calculated and rounded with the rounding precision defined.
        ProdOrderComponent.SetRange("Item No.", ItemComponent."No.");
        ProdOrderComponent.FindFirst();

        // Expected quantity = (39360 PCS / (180 PCS / BOX)) * 0.00027 = 0.0590445 ≈ 0.05904
        ProdOrderComponent.TestField("Expected Quantity", 0.05904);
        ProdOrderComponent.TestField("Expected Qty. (Base)", 0.05904);
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
    procedure ConsiderLeadTimeBeforeCalculateComponents()
    var
        OldCompItem: Record Item;
        NewCompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        LeadTime: DateFormula;
        StartingEndingDate: Date;
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO 425879] Lead Time period is considered before calculating components to respect Starting Date and Ending Date in production BOM.
        Initialize();
        Evaluate(LeadTime, '<10D>');
        StartingEndingDate := CalcDate('<-5D>', WorkDate());

        // [GIVEN] Component items "Old", "New".
        // [GIVEN] Finished item "P".
        LibraryInventory.CreateItem(OldCompItem);
        LibraryInventory.CreateItem(NewCompItem);
        LibraryInventory.CreateItem(ProdItem);

        // [GIVEN] Production BOM with two lines:
        // [GIVEN] Line 1: item "Old", ending date = WorkDate() - 5 days.
        // [GIVEN] Line 2: item "New", starting date = WorkDate() - 5 days.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, OldCompItem."No.", 1);
        ProductionBOMLine.Validate("Ending Date", StartingEndingDate);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, NewCompItem."No.", 1);
        ProductionBOMLine.Validate("Starting Date", StartingEndingDate);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Set "Lead Time Calculation" = 10 days for item "P".
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Validate("Lead Time Calculation", LeadTime);
        ProdItem.Modify(true);

        // [WHEN] Create and refresh production order for "P".
        LibraryManufacturing.CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", 1);

        // [THEN] The item "Old" is included in prod. order components.
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", OldCompItem."No.");
        ProdOrderComponent.FindFirst();
        Assert.IsTrue(ProdOrderComponent."Due Date" < WorkDate(), '');

        // [THEN] The item "New" is NOT included in prod. order components.
        ProdOrderComponent.SetRange("Item No.", NewCompItem."No.");
        Assert.RecordIsEmpty(ProdOrderComponent);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingHandler,ItemTrackingSummaryPageHandler')]
    procedure NegativeConsumptionWithItemTracking()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Consumption] [Item Tracking]
        // [SCENARIO 421872] Create and post negative consumption with item tracking by Calc. Consumption.
        Initialize();

        // [GIVEN] Lot-tracked item "C"
        LibraryItemTracking.CreateLotItem(CompItem);

        // [GIVEN] Post 100 pcs of "C" to inventory, assign lot no.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
            CompItem."No.", LibraryRandom.RandIntInRange(50, 100));
        OpenItemTrackingLines(ItemJournalLine, ItemTrackingMode::AssignLotNo);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create production BOM, select "C" as a component.
        // [GIVEN] Assign the production BOM to finished item "F".
        CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem, 1);
        CreateProductionItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Create and refresh production order for 12 pcs of the finished good "F".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", 12, '', '');

        // [GIVEN] Post output for 12 pcs.
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);

        // [GIVEN] Post three iterations of consumption, each for 5 pcs, select lot no. from inventory.
        CalculateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", 5);
        CalculateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", 5);
        CalculateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", 5);

        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [WHEN] Calculate consumption by actual output in consumption journal.
        LibraryManufacturing.CalculateConsumptionForJournal(ProductionOrder, ProdOrderComponent, WorkDate(), true);

        // [THEN] Consumption journal line is created. Quantity = 12 - 15 = -3.
        Clear(ItemJournalLine);
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        ItemJournalLine.TestField(Quantity, -3);

        // [THEN] The consumption journal line has item tracking and can be successfully posted.
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        LibraryVariableStorage.AssertEmpty();
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
    procedure VerifyFinishedProdOrderLineDataForFamilySourceTypeAndRoutingWithBackwardFlushingOnWorkCenter()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Family: Record Family;
        FamilyLine: Record "Family Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO 477400] Verify finished production order line data for family source type and routing with backward flushing on work center.
        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Work Center
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::"Backward");
        WorkCenter.Modify(true);

        // [GIVEN] Create Routing and certified it
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Setup Time", 1);
        RoutingLine.Validate("Run Time", 1);
        RoutingLine.Modify(true);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Create Family and Family Line
        LibraryManufacturing.CreateFamily(Family);
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Item."No.", 1);

        // [GIVEN] Create and refresh a Released Production Order
        CreateAndRefreshProductionOrderWithSourceTypeFamily(
          ProductionOrder, ProductionOrder.Status::Released, Family."No.", 1);

        // [WHEN] Change Production Order Status from Released to Finished
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Verify results
        ProdOrderLine.SetRange(Status, ProductionOrder.Status::Finished);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.TestField("Finished Quantity", ProductionOrder.Quantity);
        ProdOrderLine.TestField("Finished Qty. (Base)", ProductionOrder.Quantity);
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
    procedure VerifyReleasedProdOrderAllocatedCapacityForFamilySourceType()
    var
        Items: array[2] of Record Item;
        WorkCenters: array[3] of Record "Work Center";
        RoutingHeader: Record "Routing Header";
        Family: Record Family;
        FamilyLine: Record "Family Line";
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO 485090] Verify released prod. order allocated capacity for family source type
        Initialize();

        // [GIVEN] Create Items
        LibraryInventory.CreateItem(Items[1]);
        LibraryInventory.CreateItem(Items[2]);

        // [GIVEN] Create Work Centers
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenters[1]);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenters[2]);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenters[3]);

        // [GIVEN] Create Routing and certified it
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLineWithWorkCenter(RoutingHeader, WorkCenters[1], '10', 100, 3);
        CreateRoutingLineWithWorkCenter(RoutingHeader, WorkCenters[2], '20', 50, 2);
        CreateRoutingLineWithWorkCenter(RoutingHeader, WorkCenters[3], '30', 0, 1);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Create Family and Family Lines
        LibraryManufacturing.CreateFamily(Family);
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Items[1]."No.", 2);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Items[2]."No.", 2);

        // [WHEN] Create and refresh a Released Production Order
        CreateAndRefreshProductionOrderWithSourceTypeFamily(
          ProductionOrder, ProductionOrder.Status::Released, Family."No.", 100);

        // [THEN] Verify results
        VerifyProdOrderCapacity(ProductionOrder, WorkCenters[1], 5);
        VerifyProdOrderCapacity(ProductionOrder, WorkCenters[2], 4);
        VerifyProdOrderCapacity(ProductionOrder, WorkCenters[3], 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ChangeStatusOnProdOrderPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderChangeStatusBulk()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        ProdOrderNo1, ProdOrderNo2 : Code[20];
    begin
        // [SCENARIO 555888] Multiple selected Production Orders with the same status can have their status changed at the same time (new action on page)
        Initialize();

        // [GIVEN] Two production orders with status released
        CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        ProdOrderNo1 := ProductionOrder."No.";
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        ProdOrderNo2 := ProductionOrder."No.";

        // [WHEN] Using the new action
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released); // Simulating the user selection
        ProductionOrder.SetFilter("No.", '%1|%2', ProdOrderNo1, ProdOrderNo2);
        Commit();
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(Enum::"Production Order Status"::Finished);
        ProdOrderStatusMgt.ChangeStatusWithSelectionFilter(ProductionOrder);

        // [THEN] The statuses have changed only for the selected production orders
        asserterror ProductionOrder.Get(ProductionOrder.Status::Released, ProdOrderNo1);
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProdOrderNo1);
        asserterror ProductionOrder.Get(ProductionOrder.Status::Released, ProdOrderNo2);
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProdOrderNo2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifyReverseItemLedgerEntryShouldBeCreatedForConsumptionWhenReverseIsExecuted()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 327365] Verify Reverse Entry should be created of Item Ledger Entry for Entry Type "Consumption" when Reverse action is executed.
        Initialize();

        // [GIVEN] Create Production Order With Component.
        CreateProdOrderAddNewComponentAndCreateConsumptionLine(ProdOrderComponent, 0);

        // [GIVEN] Post Consumption Journal Line for this Component.
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        // [GIVEN] OpenEdit Item Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Document No.", ProdOrderComponent."Prod. Order No.");
        ItemLedgerEntries.Filter.SetFilter("Entry Type", Format(ItemLedgerEntry."Entry Type"::Consumption));

        // [WHEN] Invoke "Reverse" action.
        ItemLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reverse Entry should be created of Item Ledger Entry.
        FindLastItemLedgerEntry(ItemLedgerEntry, "Inventory Order Type"::Production, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.", "Item Ledger Entry Type"::Consumption);
        Assert.AreEqual(
            -ItemLedgerEntries.Quantity.AsInteger(),
            ItemLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ItemLedgerEntry.FieldCaption(Quantity), -ItemLedgerEntries.Quantity.AsInteger(), ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifyReverseItemLedgerEntryShouldBeCreatedForOutputWhenReverseIsExecuted()
    var
        ProdOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 327365] Verify Reverse Entry should be created of Item Ledger Entry for Entry Type "Output" when Reverse action is executed.
        Initialize();

        // [GIVEN] Create Production Order With Component.
        ProdOrder := PostJournalsForReleasedProductionOrderWithLocationAndBin(true);

        // [GIVEN] OpenEdit Item Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Document No.", ProdOrder."No.");
        ItemLedgerEntries.Filter.SetFilter("Entry Type", Format(ItemLedgerEntry."Entry Type"::Output));

        // [WHEN] Invoke "Reverse" action.
        ItemLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reverse Entry should be created of Item Ledger Entry for Entry Type "Output".
        ItemLedgerEntry.Get(ItemLedgerEntries."Entry No.".AsInteger());
        FindLastItemLedgerEntry(ItemLedgerEntry, "Inventory Order Type"::Production, ProdOrder."No.", ItemLedgerEntry."Order Line No.", "Item Ledger Entry Type"::Output);
        Assert.AreEqual(
            -ItemLedgerEntries.Quantity.AsInteger(),
            ItemLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ItemLedgerEntry.FieldCaption(Quantity), -ItemLedgerEntries.Quantity.AsInteger(), ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure VerifyReverseCapacityLedgerEntryShouldNotBeCreatedWhenReverseIsExecuted()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        ItemLedgEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
        RunTime: Decimal;
        UnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify a Reverse Entry should not be created for the last operation of the capacity ledger entry when the reverse action is executed.
        Initialize();

        // [GIVEN] Create Production item with routing.
        CreateProductionItem(Item, '');
        CreateRoutingAndUpdateItem(Item, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandDec(10, 2);
        UnitCost := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, UnitCost);

        // [GIVEN] OpenEdit Capacity Ledger Entries.
        CapacityLedgerEntries.OpenEdit();
        CapacityLedgerEntries.Filter.SetFilter("Order No.", ProductionOrder."No.");

        // [WHEN] Invoke "Reverse" action.
        asserterror CapacityLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reverse Entry should not be created for last operation of Capacity Ledger Entry.
        Assert.ExpectedError(StrSubstNo(CannotReverseLastOperationErr, CapacityLedgerEntry.FieldCaption("Entry No."), CapacityLedgerEntries."Entry No.", CapacityLedgerEntries."Order No.", ItemLedgEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure VerifyReverseItemLedgerEntryShouldNotBeCreatedForFinishedProductionOrder()
    var
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 327365] Verify Reverse Item Ledger Entry should not be created When Status is changed from Released to Finished.
        Initialize();

        // [GIVEN] Create Production Order With Component.
        ProductionOrder := PostJournalsForReleasedProductionOrderWithLocationAndBin(true);

        // [GIVEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [GIVEN] OpenEdit Item Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Document No.", ProductionOrder."No.");
        ItemLedgerEntries.Filter.SetFilter("Entry Type", Format(ItemLedgerEntry."Entry Type"::Output));

        // [WHEN] Invoke "Reverse" action.
        asserterror ItemLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reverse Item Ledger Entry should not be created When Status is changed from Released to Finished.
        Assert.ExpectedError(StrSubstNo(MissingReleasedProductionErr, ProductionOrder."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure VerifyReverseItemLedgerEntryShouldNotBeCreatedForPositiveAdjmt()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 327365] Verify Reverse Item Ledger Entry should not be created for Entry Type "Positive Adjmt.".
        Initialize();

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));

        // [GIVEN] Update Flushing Method.
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandDec(10, 2) + 100, '', '');

        // [GIVEN] OpenEdit Item Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Item No.", ChildItem."No.");
        ItemLedgerEntries.Filter.SetFilter("Entry Type", Format(ItemLedgerEntry."Entry Type"::"Positive Adjmt."));

        // [WHEN] Invoke "Reverse" action.
        asserterror ItemLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Verify Reverse Item Ledger Entry should not be created for Entry Type "Positive Adjmt.".
        Assert.ExpectedError(StrSubstNo(CannotHandleEntryTypeErr, ItemLedgerEntry."Entry Type"::"Positive Adjmt."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ChangeStatusOnProdOrderPageHandler,ErrorMessagesPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderChangeStatusBulkErrorHandling()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenter: Record "Work Center";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        ProdOrderNo1, ProdOrderNo2 : Code[20];
        ItemQty: Decimal;
    begin
        // [SCENARIO 557246] Change status bulk action for production orders does not stop execution on error but collects errors and shows them all in the end 
        Initialize();

        // [GIVEN] One production order with status firm planned
        CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        ItemQty := LibraryRandom.RandIntInRange(1, 100);
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.", ItemQty);
        ProdOrderNo1 := ProductionOrder."No.";

        // [GIVEN] Production order component with large quantity and flushing method set to forward
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', '', ItemQty);
        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent."Item No." := Item."No.";
        ProdOrderComponent."Quantity per" := LibraryRandom.RandIntInRange(1000, 10000);
        ProdOrderComponent."Flushing Method" := Enum::"Flushing Method"::Forward;
        ProdOrderComponent.Modify();

        // [GIVEN] Second production order with status firm planned, no component
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(1, 100));
        ProdOrderNo2 := ProductionOrder."No.";

        // [WHEN] Using the new action
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned"); // Simulating the user selection
        ProductionOrder.SetFilter("No.", '%1|%2', ProdOrderNo1, ProdOrderNo2);
        Commit();
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(Enum::"Production Order Status"::Released);
        ProdOrderStatusMgt.ChangeStatusWithSelectionFilter(ProductionOrder);

        // [THEN] The status of the first order has not changed
        asserterror ProductionOrder.Get(ProductionOrder.Status::Released, ProdOrderNo1);
        ProductionOrder.Get(ProductionOrder.Status::"Firm Planned", ProdOrderNo1);
        // [THEN] The status of the second order has changed
        asserterror ProductionOrder.Get(ProductionOrder.Status::"Firm Planned", ProdOrderNo2);
        // [THEN] There is one error in the error messages page (checked in the page handler)

    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ItemTrackingHandler,MessageHandlerWithoutValidation')]
    procedure CheckReservationEntryStatusWhenPlannedProdOrderConvertToReleasedProdOrder()
    var
        Item: Record Item;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionOrder: Record "Production Order";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        PlannedProdOrder: TestPage "Planned Production Order";
        TotalQuantity: Decimal;
    begin
        // [SCENARIO 523992] Change the reservation entry status from prospect to surplus when planned prod. order convert to the released prod. order.
        Initialize();

        // [GIVEN] Set location code in Manufacturing Setup.
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Components at Location", LocationBlue.Code);
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create Item with Lot Tracking.
        CreateItemWithLotTracking(Item);

        // [GIVEN] Create a Sales Order.
        TotalQuantity := CreateSalesOrderOnManufacturingLocation(SalesHeader, Item."No.", LibraryRandom.RandInt(5), LocationBlue.Code);

        // [GIVEN] Create Production Order.
        CreateProdOrderOnManufacturingLocation(ProductionOrder, Item."No.", TotalQuantity, LocationBlue.Code);

        // [WHEN] Refreshing released production order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Open Planned Prod. Order page.
        PlannedProdOrder.OpenEdit();
        PlannedProdOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Enqueue the Lot No. and Quantity value.
        OpenItemTrackingLinesSetValueInProdOrderLine(LibraryUtility.GenerateGUID(), '', TotalQuantity);

        // [WHEN] Invoke the Item Tracking Page and assign the values.
        PlannedProdOrder.ProdOrderLines."Item &Tracking Lines".Invoke();

        // [WHEN] Change the Production Order Status.
        LibraryManufacturing.ChangeProuctionOrderStatus(ProductionOrder."No.", ProductionOrder.Status::Planned, ProductionOrder.Status::Released);

        // [THEN] Check Reservation Entry Status.
        VerifyReservationEntry(Item."No.", ProductionOrder.Quantity, ReservationEntry."Reservation Status"::Surplus, LocationBlue.Code);
    end;

    [Test]
    procedure VerifyReverseProductionOrderActionShouldNotBeVisibleOnItemLedgerEntries()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 560194] Verify "Reverse Production Order" action should not be visible on "Item Ledger Entries" Page from general overview.
        Initialize();

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(5));

        // [GIVEN] Update Flushing Method.
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandDec(10, 2) + 100, '', '');

        // [WHEN] OpenEdit Item Ledger Entries.
        ItemLedgerEntries.OpenEdit();

        // [THEN] Verify "Reverse Production Order" action should not be visible on Item Ledger Entries from general overview.
        Assert.AreEqual(
            false,
            ItemLedgerEntries.Reverse.Visible(),
            StrSubstNo(ActionShouldNotBeVisibleErr, ItemLedgerEntries.Caption()));
    end;

    [Test]
    procedure VerifyReverseProductionOrderActionShouldBeVisibleOnReleasedProductionOrders()
    var
        ProductionOrder: Record "Production Order";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
        ReleasedProductionOrders: TestPage "Released Production Orders";
    begin
        // [SCENARIO 560194] Verify "Reverse Production Order" action should be visible on "Item Ledger Entries" Page When "Item Ledger E&ntries" action is executed from "Released Production Orders".
        Initialize();

        // [GIVEN] Create Production Order With Component.
        ProductionOrder := PostJournalsForReleasedProductionOrderWithLocationAndBin(true);

        // [GIVEN] Trap "Item Ledger Entries" page.
        ItemLedgerEntries.Trap();

        // [GIVEN] Open "Released Production Orders" page.
        ReleasedProductionOrders.OpenEdit();
        ReleasedProductionOrders.GoToRecord(ProductionOrder);

        // [WHEN] Invoke "Item Ledger E&ntries" action.
        ReleasedProductionOrders."Item Ledger E&ntries".Invoke();

        // [THEN] Verify "Reverse Production Order" action should be visible on "Item Ledger Entries" Page When "Item Ledger E&ntries" action is executed from "Released Production Orders".
        Assert.AreEqual(
            true,
            ItemLedgerEntries.Reverse.Visible(),
            StrSubstNo(ActionShouldBeVisibleErr, ItemLedgerEntries.Caption()));
    end;

    [Test]
    procedure VerifyReverseProductionOrderActionShouldBeVisibleOnReleasedProductionOrder()
    var
        ProductionOrder: Record "Production Order";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 560194] Verify "Reverse Production Order" action should be visible on "Item Ledger Entries" Page When "Item Ledger E&ntries" action is executed from "Released Production Order".
        Initialize();

        // [GIVEN] Create Production Order With Component.
        ProductionOrder := PostJournalsForReleasedProductionOrderWithLocationAndBin(true);

        // [GIVEN] Trap "Item Ledger Entries" page.
        ItemLedgerEntries.Trap();

        // [GIVEN] Open "Released Production Order" page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [WHEN] Invoke "Item Ledger E&ntries" action.
        ReleasedProductionOrder."Item Ledger E&ntries".Invoke();

        // [THEN] Verify "Reverse Production Order" action should be visible on "Item Ledger Entries" Page When "Item Ledger E&ntries" action is executed from "Released Production Order".
        Assert.AreEqual(
            true,
            ItemLedgerEntries.Reverse.Visible(),
            StrSubstNo(ActionShouldBeVisibleErr, ItemLedgerEntries.Caption()));
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,ConfirmHandler,MessageHandlerWithoutValidation,ReleasedProdOrderPageHandler')]
    procedure VerifyProductionOrderMovedFromFinishedToReleasedUsingReopenFinishProdOrder()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ManufacturingSetup: Record "Manufacturing Setup";
        FinishedProductionorder: TestPage "Finished Production Order";
    begin
        // [SCENARIO 358674] Verify Production Order is moved from Finished to Released using "ReopenFinishProdOrder" action on "Finished Production Order" page.
        Initialize();

        // [GIVEN] Set location code in Manufacturing Setup.
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Components at Location", '');
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create an Item with BOM and Routing.
        CreateItemWithBOMAndRouting(Item, ChildItem, LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandDec(10, 2) + 100, '', '');

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Find Released Production Order Line.
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");

        // [GIVEN] Open and Post Production Journal.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [GIVEN] Get Finished Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [WHEN] Execute "ReopenFinishProdOrder" action.
        FinishedProductionorder.OpenEdit();
        FinishedProductionorder.GoToRecord(ProductionOrder);
        FinishedProductionorder.ReopenFinishedProdOrder.Invoke();

        // [THEN] Verify Production Order is moved from Finished to Released and Finished Production Order gets deleted.
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrder."No.");
        asserterror ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,ConfirmHandler,MessageHandlerWithoutValidation,ReleasedProdOrderPageHandler')]
    procedure VerifyFinishedProductionOrderCannotBeReopenedMoreThanOnce()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        FinishedProductionorder: TestPage "Finished Production Order";
    begin
        // [SCENARIO 358674] Verify Finished Production Order cannot be Reopened more than once using "ReopenFinishProdOrder" action on "Finished Production Order" page.
        Initialize();

        // [GIVEN] Create an Item with BOM and Routing.
        CreateItemWithBOMAndRouting(Item, ChildItem, LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandDec(10, 2) + 100, '', '');

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Find Released Production Order Line.
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");

        // [GIVEN] Open and Post Production Journal.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [GIVEN] Get Finished Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [GIVEN] Execute "ReopenFinishProdOrder" action.
        FinishedProductionorder.OpenEdit();
        FinishedProductionorder.GoToRecord(ProductionOrder);
        FinishedProductionorder.ReopenFinishedProdOrder.Invoke();

        // [GIVEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [GIVEN] Get Finished Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [WHEN] Execute "ReopenFinishProdOrder" action.
        FinishedProductionorder.OpenEdit();
        FinishedProductionorder.GoToRecord(ProductionOrder);
        asserterror FinishedProductionorder.ReopenFinishedProdOrder.Invoke();

        // [THEN] Verify Finished Production Order cannot be Reopened more than once.
        Assert.ExpectedError(ProductionOrderHasAlreadyBeenReopenedErr);
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifyOnlyFinishedProductionOrderCanBeReopened()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
    begin
        // [SCENARIO 358674] Verify only Finished Production Order can be reopened.
        Initialize();

        // [GIVEN] Create an Item with BOM and Routing.
        CreateItemWithBOMAndRouting(Item, ChildItem, LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandDec(10, 2) + 100, '', '');

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Find Released Production Order Line.
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");

        // [GIVEN] Open and Post Production Journal.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [WHEN] Reopen Finished Production Order.
        asserterror ProdOrderStatusMgt.ReopenFinishedProdOrder(ProductionOrder);

        // [THEN] Verify only Finished Production Order can be reopened.
        Assert.ExpectedTestFieldError(ProductionOrder.FieldCaption(Status), Format(ProductionOrder.Status::Finished));
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,ConfirmHandler,MessageHandlerWithoutValidation,ReleasedProdOrderPageHandler')]
    procedure VerifyProductionOrderMovedFromFinishedToReleasedUsingReopenFinishProdOrderWithRelatedRecords()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderComponent: Record "Prod. Order Component";
        FinishedProductionorder: TestPage "Finished Production Order";
    begin
        // [SCENARIO 358674] Verify Production Order is moved from Finished to Released using "ReopenFinishProdOrder" action on "Finished Production Order" page with Related records.
        Initialize();

        // [GIVEN] Create an Item with BOM and Routing.
        CreateItemWithBOMAndRouting(Item, ChildItem, LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandDec(10, 2) + 100, '', '');

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Find Released Production Order Line.
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");

        // [GIVEN] Open and Post Production Journal.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [GIVEN] Get Finished Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [WHEN] Execute "ReopenFinishProdOrder" action.
        FinishedProductionorder.OpenEdit();
        FinishedProductionorder.GoToRecord(ProductionOrder);
        FinishedProductionorder.ReopenFinishedProdOrder.Invoke();

        // [THEN] Verify Production Order is moved from Finished to Released with related records and Finished Production Order gets deleted.
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrder."No.");
        Assert.AreEqual(
            true,
            ProductionOrder."Reopened",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Reopened"), true, ProductionOrder.TableCaption()));

        ProdOrderRtngLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordCount(ProdOrderRtngLine, 1);

        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordCount(ProdOrderComponent, 1);
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,ConfirmHandler,MessageHandlerWithoutValidation,ReleasedProdOrderPageHandler')]
    procedure VerifyCostIsAdjustedAndIsFinishedChangedToFalseInInventoryAdjustmentUsingReopenFinishProdOrder()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        FinishedProductionorder: TestPage "Finished Production Order";
    begin
        // [SCENARIO 358674] Verify "Is Finished" changed to false in Inventory Adjmt. Entry (Order) using "ReopenFinishProdOrder" action.
        Initialize();

        // [GIVEN] Create an Item with BOM and Routing.
        CreateItemWithBOMAndRouting(Item, ChildItem, LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandDec(10, 2) + 100, '', '');

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Find Released Production Order Line.
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");

        // [GIVEN] Open and Post Production Journal.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Change Status From Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [GIVEN] Get Finished Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [WHEN] Execute "ReopenFinishProdOrder" action.
        FinishedProductionorder.OpenEdit();
        FinishedProductionorder.GoToRecord(ProductionOrder);
        FinishedProductionorder.ReopenFinishedProdOrder.Invoke();

        // [THEN] Verify "Is Finished" and "Cost is Adjusted" is changed to false in Inventory Adjmt. Entry (Order).
        InvtAdjmtEntryOrder.Get(InvtAdjmtEntryOrder."Order Type"::Production, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        Assert.AreEqual(
            false,
            InvtAdjmtEntryOrder."Is Finished",
            StrSubstNo(ValueMustBeEqualErr, InvtAdjmtEntryOrder.FieldCaption("Is Finished"), false, InvtAdjmtEntryOrder.TableCaption()));
        Assert.AreEqual(
            false,
            InvtAdjmtEntryOrder."Cost is Adjusted",
            StrSubstNo(ValueMustBeEqualErr, InvtAdjmtEntryOrder.FieldCaption("Cost is Adjusted"), false, InvtAdjmtEntryOrder.TableCaption()));
    end;

    [Test]
    procedure VerifyValueEntryShouldBeCreatedWithCostEntryTypeDirectCostNonInventoryWhenStatusIsChangedFromReleasedToFinished()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify Value Entry should be created with "Cost Entry Type" - "Direct Cost - Non Inventory" for Output item When Production Order status is changed from Released to Finished.
        // Cost of Non-Inventory item must be updated in "Cost Amount(Actual)" in Item Ledger Entry for "Entry Type" Output.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Set Automatic Cost Adjustment Always.
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Production Item, Non-Inventory Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(OutputItem, NonInvItem, ProductionBOMHeader);

        // [GIVEN] Save Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", Quantity, '', '');

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", NonInvItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [WHEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [THEN] Verify "Cost Amount (Non-Invtbl.)" must be updated for "Entry Type" Consumption and "Cost Amount (Expected)" ,"Cost Amount (Actual)" must be zero for "Entry Type" Output in Value Entry.
        VerifyCostAmountNonInventoryForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Consumption, "Cost Entry Type"::"Direct Cost", NonInvItem, -Quantity, -Quantity * NonInvUnitCost);
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost", OutputItem, Quantity, 0, 0);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify Value Entry should be created with "Cost Entry Type" - "Direct Cost - Non Inventory" for Output item and "Cost Amount (Actual)" must be updated for "Entry Type" Output in Value Entry.
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost", OutputItem, 0, 0, 0);
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost - Non Inventory", OutputItem, 0, 0, NonInvUnitCost * Quantity);
        VerifyCostAmountExpectedAndActualForItemLedgerEntry(ProductionOrder, "Item Ledger Entry Type"::Output, OutputItem, 0, NonInvUnitCost * Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure VerifyValueEntryShouldBeCreatedWithCostEntryTypeDirectCostNonInventoryWithPartialConsumption()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        ConsumptionQuantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify Value Entry should be created with "Cost Entry Type" - "Direct Cost - Non Inventory" for Output item When Production Order status is changed from Released to Finished with partial Consumption.
        // Cost of Non-Inventory item must be updated in "Cost Amount(Actual)" in Item Ledger Entry for "Entry Type" Output.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Set Automatic Cost Adjustment Always.
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Production Item, Non-Inventory Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(OutputItem, NonInvItem, ProductionBOMHeader);

        // [GIVEN] Save Quantity,ConsumptionQuantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        ConsumptionQuantity := LibraryRandom.RandIntInRange(5, 5);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, ConsumptionQuantity, NonInvUnitCost);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", Quantity, '', '');

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", NonInvItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, ConsumptionQuantity);

        // [WHEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [THEN] Verify "Cost Amount (Non-Invtbl.)" must be updated for "Entry Type" Consumption and "Cost Amount (Expected)" ,"Cost Amount (Actual)" must be zero for "Entry Type" Output in Value Entry.
        VerifyCostAmountNonInventoryForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Consumption, "Cost Entry Type"::"Direct Cost", NonInvItem, -ConsumptionQuantity, -ConsumptionQuantity * NonInvUnitCost);
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost", OutputItem, Quantity, 0, 0);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify Value Entry should be created with "Cost Entry Type" - "Direct Cost - Non Inventory" for Output item and "Cost Amount (Actual)" must be updated for "Entry Type" Output in Value Entry with partial consumption.
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost", OutputItem, 0, 0, 0);
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost - Non Inventory", OutputItem, 0, 0, NonInvUnitCost * ConsumptionQuantity);
        VerifyCostAmountExpectedAndActualForItemLedgerEntry(ProductionOrder, "Item Ledger Entry Type"::Output, OutputItem, 0, NonInvUnitCost * ConsumptionQuantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerWithoutValidation')]
    procedure VerifyCostMustBeUpdatedInNonInvAppliedAccountWhenPostInvtCostToGLIsExecutedForFinishedProductionOrder()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ValueEntry: Record "Value Entry";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        GeneralPostingSetup: Record "General Posting Setup";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify "Direct Cost Non-Inv. App. Acc." must be updated for "Direct Cost - Non Inventory" Value Entry with Automatic Cost Posting is not enabled.
        // PostInvtCostToGL is executed for Finished Production Order.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Set Automatic Cost Adjustment Always.
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Production Item, Non-Inventory Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(OutputItem, NonInvItem, ProductionBOMHeader);

        // [GIVEN] Update "Direct Cost Non-Inv. App. Acc." in General Posting Setup.
        GeneralPostingSetup.Get('', OutputItem."Gen. Prod. Posting Group");
        LibraryERM.UpdateDirectCostNonInventoryAppliedAccountInGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Save Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", Quantity, '', '');

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", NonInvItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "Cost Posted to G/L" must be zero for "Direct Cost - Non Inventory" in Value Entry.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost - Non Inventory", OutputItem."No.", 0);
        Assert.AreEqual(
            0,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), 0, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [WHEN] Run "Post Inventory Cost to G/L".
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify "Direct Cost Non-Inv. App. Acc." must be updated for "Direct Cost - Non Inventory" and "Cost Posted to G/L" must be updated in Value Entry.
        VerifyGLEntriesForNonInventoryAppliedAccount(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost - Non Inventory", OutputItem, NonInvUnitCost * Quantity);
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost - Non Inventory", OutputItem."No.", 0);
        Assert.AreEqual(
            NonInvUnitCost * Quantity,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), NonInvUnitCost * Quantity, ValueEntry."Entry No.", ValueEntry.TableCaption()));
    end;

    [Test]
    procedure VerifyCostMustBeUpdatedInNonInventoryAppliedAccountWithAutomaticCostPostingForFinishedProductionOrder()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ValueEntry: Record "Value Entry";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        GeneralPostingSetup: Record "General Posting Setup";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify "Direct Cost Non-Inv. App. Acc." must be updated for "Direct Cost - Non Inventory" Value Entry with Automatic Cost Posting is enabled.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Set Automatic Cost Adjustment Always.
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Production Item, Non-Inventory Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(OutputItem, NonInvItem, ProductionBOMHeader);

        // [GIVEN] Update "Direct Cost Non-Inv. App. Acc." in General Posting Setup.
        GeneralPostingSetup.Get('', OutputItem."Gen. Prod. Posting Group");
        LibraryERM.UpdateDirectCostNonInventoryAppliedAccountInGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Save Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", Quantity, '', '');

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", NonInvItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "Direct Cost Non-Inv. App. Acc." must be updated for "Direct Cost - Non Inventory" and "Cost Posted to G/L" must be updated in Value Entry With Automatic Cost Posting.
        VerifyGLEntriesForNonInventoryAppliedAccount(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost - Non Inventory", OutputItem, NonInvUnitCost * Quantity);
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost - Non Inventory", OutputItem."No.", 0);
        Assert.AreEqual(
            NonInvUnitCost * Quantity,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), NonInvUnitCost * Quantity, ValueEntry."Entry No.", ValueEntry.TableCaption()));
    end;

    [Test]
    procedure VerifyDirectCostNonInventoryAppliedAccountIsMissingWhenStatusIsChanged()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        GeneralPostingSetup: Record "General Posting Setup";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify user should not be able to change the status When "Direct Cost Non-Inv. App. Acc." is missing in General Posting Setup.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Set Automatic Cost Adjustment Always.
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Production Item, Non-Inventory Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(OutputItem, NonInvItem, ProductionBOMHeader);

        // [GIVEN] Update "Direct Cost Non-Inv. App. Acc." in General Posting Setup.
        GeneralPostingSetup.Get('', OutputItem."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Direct Cost Non-Inv. App. Acc.", '');
        GeneralPostingSetup.Modify();

        // [GIVEN] Save Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", Quantity, '', '');

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", NonInvItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [WHEN] Change Prod Order Status from Released to Finished.
        asserterror ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify user should not be able to change the status When "Direct Cost Non-Inv. App. Acc." is missing in General Posting Setup.
        GeneralPostingSetup.SetRange("Gen. Bus. Posting Group", '');
        GeneralPostingSetup.SetRange("Gen. Prod. Posting Group", OutputItem."Gen. Prod. Posting Group");
        GeneralPostingSetup.FindFirst();
        Assert.ExpectedError(
            StrSubstNo(MissingAccountTxt, GeneralPostingSetup.FieldCaption("Direct Cost Non-Inv. App. Acc."), GeneralPostingSetup.TableCaption() + ' ' + GeneralPostingSetup.GetFilters()));
    end;

    [Test]
    procedure VerifyCostAmountActualShouldBeUpdatedBasedOnComponentAndNonInventoryItemInProductionItem()
    var
        OutputItem: Record Item;
        CompItem: Record Item;
        NonInvItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        CompUnitCost: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify Value Entry should be created with "Cost Entry Type" - "Direct Cost - Non Inventory" for Output item When Production Order status is changed from Released to Finished.
        // Cost of Non-Inventory and Inventory item must be updated in "Cost Amount(Actual)" in Item Ledger Entry for "Entry Type" Output.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Set Automatic Cost Adjustment Always.
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Production Item, Non-Inventory Item , Component Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(OutputItem, NonInvItem, CompItem, ProductionBOMHeader);

        // [GIVEN] Save Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := LibraryRandom.RandIntInRange(20, 20);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);

        // [GIVEN] Create and Post Purchase Document for Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem, Quantity, CompUnitCost);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", Quantity, '', '');

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", NonInvItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [WHEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [THEN] Verify "Cost Amount (Non-Invtbl.)" must be updated for "Entry Type" Consumption and "Cost Amount (Actual)" ,"Cost Amount (Expected)" must be zero for "Entry Type" Output in Value Entry.
        VerifyCostAmountNonInventoryForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Consumption, "Cost Entry Type"::"Direct Cost", NonInvItem, -Quantity, -Quantity * NonInvUnitCost);
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost", OutputItem, Quantity, 0, 0);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify Value Entry should be created with "Cost Entry Type" - "Direct Cost - Non Inventory" for Output item and "Cost Amount (Actual)" must be updated for "Entry Type" Output in Value Entry.
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost", OutputItem, 0, 0, Quantity * CompUnitCost);
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost - Non Inventory", OutputItem, 0, 0, NonInvUnitCost * Quantity);
        VerifyCostAmountExpectedAndActualForItemLedgerEntry(ProductionOrder, "Item Ledger Entry Type"::Output, OutputItem, 0, (NonInvUnitCost * Quantity) + (Quantity * CompUnitCost));
    end;

    [Test]
    procedure VerifyStandardCostMustBeUpdatedInProductionItem()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify Standard Cost must be updated in production item When Non-Inventory item exist in Production BOM.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Production Item, Non-Inventory Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(OutputItem, NonInvItem, ProductionBOMHeader);

        // [GIVEN] Save Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Modify();

        // [WHEN] Update "Standard Cost" in Item.
        OutputItem.Validate("Standard Cost", LibraryRandom.RandIntInRange(10, 10));

        // [THEN] Verify Standard Cost must be updated in production item.
        VerifyCostFieldsInItem(OutputItem, NonInvUnitCost, NonInvUnitCost, NonInvUnitCost, 0, 0, 0, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifySingleLvlMaterialNonInventoryCostMustBeUpdatedInProductionItem()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify "Single-Lvl Mat. Non-Invt. Cost" must be updated in production item When Non-Inventory item exist in Production BOM.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Production Item, Non-Inventory Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(OutputItem, NonInvItem, ProductionBOMHeader);

        // [GIVEN] Save Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Modify();

        // [WHEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [THEN] Verify "Single-Lvl Mat. Non-Invt. Cost" must be updated in production item.
        OutputItem.Get(OutputItem."No.");
        Assert.AreEqual(
            NonInvUnitCost,
            OutputItem."Single-Lvl Mat. Non-Invt. Cost",
            StrSubstNo(ValueMustBeEqualErr, OutputItem.FieldCaption("Single-Lvl Mat. Non-Invt. Cost"), NonInvUnitCost, OutputItem.TableCaption()));
    end;

    [Test]
    procedure VerifyValueEntryShouldBeCreatedWithVarianceTypeMaterialNonInventoryWhenStatusIsChangedFromReleasedToFinished()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify Value Entry should be created with "Variance Type" - "Material - Non Inventory" for Output item When Production Order status is changed from Released to Finished.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Set Automatic Cost Adjustment Always.
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Save Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create Item with Costing Method Standard and Standard Cost.
        LibraryInventory.CreateItem(OutputItem);
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Standard Cost", LibraryRandom.RandIntInRange(30, 30));
        OutputItem.Modify();

        // [GIVEN] Create Non-Inventory Item.
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        // [GIVEN] Create Certified Production BOM with Non-Inventory item.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, NonInvItem."No.", LibraryRandom.RandIntInRange(1, 1));
        OutputItem.Validate("Replenishment System", OutputItem."Replenishment System"::"Prod. Order");
        OutputItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        OutputItem.Modify();

        // [GIVEN] Create and Post Purchase Document for Non-Inventory Item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", Quantity, '', '');

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", NonInvItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [WHEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [THEN] Verify "Cost Amount (Non-Invtbl.)" must be updated for "Entry Type" Consumption and "Cost Amount (Expected)" must be updated for "Entry Type" Output in Value Entry.
        VerifyCostAmountNonInventoryForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Consumption, "Cost Entry Type"::"Direct Cost", NonInvItem, -Quantity, -Quantity * NonInvUnitCost);
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost", OutputItem, Quantity, Quantity * OutputItem."Standard Cost", 0);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify Value Entry should be created with "Variance Type" - "Material - Non Inventory" for Output item.
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost", OutputItem, 0, -OutputItem."Standard Cost" * Quantity, 0);
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost - Non Inventory", OutputItem, 0, 0, NonInvUnitCost * Quantity);
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::Variance, OutputItem, 0, 0, -(NonInvUnitCost * Quantity));
        VerifyCostAmountExpectedAndActualForItemLedgerEntry(ProductionOrder, "Item Ledger Entry Type"::Output, OutputItem, 0, OutputItem."Standard Cost" * Quantity);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    procedure VerifyValueEntryShouldBeCreatedWithVarianceTypeMaterialNonInventoryWhenStatusIsChangedForPartialConsumptionQuantity()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        Quantity: Decimal;
        ConsumptionQuantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify Value Entry should be created with "Variance Type" - "Material - Non Inventory" for Output item When Production Order is posted with partial consumption quantity.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Set Automatic Cost Adjustment Always.
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Save Quantity, Consumption Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        ConsumptionQuantity := LibraryRandom.RandIntInRange(5, 5);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create Item with Costing Method Standard and Standard Cost.
        LibraryInventory.CreateItem(OutputItem);
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Standard Cost", LibraryRandom.RandIntInRange(30, 30));
        OutputItem.Modify();

        // [GIVEN] Update "Mat. Non-Inv. Variance Acc." in Inventory Posting Setup.
        InventoryPostingSetup.Get('', OutputItem."Inventory Posting Group");
        LibraryInventory.UpdateMaterialNonInvVarianceAccountInInventoryPostingSetup(InventoryPostingSetup);

        // [GIVEN] Create Non-Inventory Item.
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        // [GIVEN] Create Certified Production BOM with Non-Inventory item.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, NonInvItem."No.", LibraryRandom.RandIntInRange(1, 1));
        OutputItem.Validate("Replenishment System", OutputItem."Replenishment System"::"Prod. Order");
        OutputItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        OutputItem.Modify();

        // [GIVEN] Create and Post Purchase Document for Non-Inventory Item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, ConsumptionQuantity, NonInvUnitCost);

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", Quantity, '', '');

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", NonInvItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal with partial quantity.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, ConsumptionQuantity);

        // [WHEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [THEN] Verify "Cost Amount (Non-Invtbl.)" must be updated for "Entry Type" Consumption and "Cost Amount (Expected)" must be updated for "Entry Type" Output in Value Entry.
        VerifyCostAmountNonInventoryForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Consumption, "Cost Entry Type"::"Direct Cost", NonInvItem, -ConsumptionQuantity, -ConsumptionQuantity * NonInvUnitCost);
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost", OutputItem, Quantity, Quantity * NonInvUnitCost, 0);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify Value Entry should be created with "Variance Type" - "Material - Non Inventory" for Output item When Production Order is posted with partial consumption quantity.
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost", OutputItem, 0, -NonInvUnitCost * Quantity, 0);
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::"Direct Cost - Non Inventory", OutputItem, 0, 0, NonInvUnitCost * ConsumptionQuantity);
        VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::Variance, OutputItem, 0, 0, (NonInvUnitCost * ConsumptionQuantity));
        VerifyCostAmountExpectedAndActualForItemLedgerEntry(ProductionOrder, "Item Ledger Entry Type"::Output, OutputItem, 0, NonInvUnitCost * Quantity);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifyValueEntryShouldBeCreatedWithVarianceTypeMaterialNonInventoryWhenPostInvtCostToGLIsExecutedForFinishedProdOrder()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ValueEntry: Record "Value Entry";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        Quantity: Decimal;
        ConsumptionQuantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify Value Entry should be created with "Variance Type" - "Material - Non Inventory" for Output item.
        // PostInvtCostToGL is executed for Finished Production Order.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Set Automatic Cost Adjustment Always.
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Save Quantity, Consumption Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        ConsumptionQuantity := LibraryRandom.RandIntInRange(5, 5);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create Item with Costing Method Standard and Standard Cost.
        LibraryInventory.CreateItem(OutputItem);
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Standard Cost", LibraryRandom.RandIntInRange(30, 30));
        OutputItem.Modify();

        // [GIVEN] Update "Mat. Non-Inv. Variance Acc." in Inventory Posting Setup.
        InventoryPostingSetup.Get('', OutputItem."Inventory Posting Group");
        LibraryInventory.UpdateMaterialNonInvVarianceAccountInInventoryPostingSetup(InventoryPostingSetup);

        // [GIVEN] Update "Direct Cost Non-Inv. App. Acc." in General Posting Setup.
        GeneralPostingSetup.Get('', OutputItem."Gen. Prod. Posting Group");
        LibraryERM.UpdateDirectCostNonInventoryAppliedAccountInGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Create Non-Inventory Item.
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        // [GIVEN] Create Certified Production BOM with Non-Inventory item.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, NonInvItem."No.", LibraryRandom.RandIntInRange(1, 1));
        OutputItem.Validate("Replenishment System", OutputItem."Replenishment System"::"Prod. Order");
        OutputItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        OutputItem.Modify();

        // [GIVEN] Create and Post Purchase Document for Non-Inventory Item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, ConsumptionQuantity, NonInvUnitCost);

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", Quantity, '', '');

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", NonInvItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal with partial quantity.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, ConsumptionQuantity);

        // [GIVEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "Cost Posted to G/L" must be zero for "Variance Type"-"Material - Non Inventory" in Value Entry.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Output, "Cost Entry Type"::Variance, OutputItem."No.", 0);
        Assert.AreEqual(
            0,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), 0, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [WHEN] Run "Post Inventory Cost to G/L".
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify "Mat. Non-Inv. Variance Acc." must be updated for "Variance Type"-"Material - Non Inventory" and "Cost Posted to G/L" must be updated in Value Entry.
        VerifyGLEntriesForNonInventoryVarianceAccount(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::Variance, OutputItem, NonInvUnitCost * ConsumptionQuantity);
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Output, "Cost Entry Type"::Variance, OutputItem."No.", 0);
        Assert.AreEqual(
            NonInvUnitCost * ConsumptionQuantity,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), NonInvUnitCost * ConsumptionQuantity, ValueEntry."Entry No.", ValueEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    procedure VerifyValueEntryShouldBeCreatedWithVarianceTypeMaterialNonInventoryWithAutomaticCostPostingIsEnabled()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ValueEntry: Record "Value Entry";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        Quantity: Decimal;
        ConsumptionQuantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify Value Entry should be created with "Variance Type" - "Material - Non Inventory" for Output item with Automatic Cost Posting is enabled.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Set Automatic Cost Adjustment Always.
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Save Quantity, Consumption Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        ConsumptionQuantity := LibraryRandom.RandIntInRange(5, 5);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create Item with Costing Method Standard and Standard Cost.
        LibraryInventory.CreateItem(OutputItem);
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Standard Cost", LibraryRandom.RandIntInRange(30, 30));
        OutputItem.Modify();

        // [GIVEN] Update "Mat. Non-Inv. Variance Acc." in Inventory Posting Setup.
        InventoryPostingSetup.Get('', OutputItem."Inventory Posting Group");
        LibraryInventory.UpdateMaterialNonInvVarianceAccountInInventoryPostingSetup(InventoryPostingSetup);

        // [GIVEN] Update "Direct Cost Non-Inv. App. Acc." in General Posting Setup.
        GeneralPostingSetup.Get('', OutputItem."Gen. Prod. Posting Group");
        LibraryERM.UpdateDirectCostNonInventoryAppliedAccountInGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Create Non-Inventory Item.
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        // [GIVEN] Create Certified Production BOM with Non-Inventory item.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, NonInvItem."No.", LibraryRandom.RandIntInRange(1, 1));
        OutputItem.Validate("Replenishment System", OutputItem."Replenishment System"::"Prod. Order");
        OutputItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        OutputItem.Modify();

        // [GIVEN] Create and Post Purchase Document for Non-Inventory Item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, ConsumptionQuantity, NonInvUnitCost);

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", Quantity, '', '');

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", NonInvItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal with partial quantity.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, ConsumptionQuantity);

        // [GIVEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "Mat. Non-Inv. Variance Acc." must be updated for "Variance Type"-"Material - Non Inventory" and "Cost Posted to G/L" must be updated in Value Entry.
        VerifyGLEntriesForNonInventoryVarianceAccount(ProductionOrder, "Item Ledger Entry Type"::Output, "Cost Entry Type"::Variance, OutputItem, NonInvUnitCost * ConsumptionQuantity);
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Output, "Cost Entry Type"::Variance, OutputItem."No.", 0);
        Assert.AreEqual(
            NonInvUnitCost * ConsumptionQuantity,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), NonInvUnitCost * ConsumptionQuantity, ValueEntry."Entry No.", ValueEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ConfirmHandler')]
    procedure VerifyMaterialNonInventoryVarianceAccountIsMissingWhenStatusIsChanged()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        Quantity: Decimal;
        ConsumptionQuantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify user should not be able to change the status When "Mat. Non-Inv. Variance Acc." is missing in Inventory Posting Setup.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Set Automatic Cost Adjustment Always.
        LibraryInventory.SetAutomaticCostAdjmtAlways();

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Save Quantity, Consumption Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        ConsumptionQuantity := LibraryRandom.RandIntInRange(5, 5);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create Item with Costing Method Standard and Standard Cost.
        LibraryInventory.CreateItem(OutputItem);
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Standard Cost", LibraryRandom.RandIntInRange(30, 30));
        OutputItem.Modify();

        // [GIVEN] Update "Direct Cost Non-Inv. App. Acc." in General Posting Setup.
        GeneralPostingSetup.Get('', OutputItem."Gen. Prod. Posting Group");
        LibraryERM.UpdateDirectCostNonInventoryAppliedAccountInGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Update "Mat. Non-Inv. Variance Acc." in Inventory Posting Setup.
        InventoryPostingSetup.Get('', OutputItem."Inventory Posting Group");
        InventoryPostingSetup.Validate("Mat. Non-Inv. Variance Acc.", '');
        InventoryPostingSetup.Modify();

        // [GIVEN] Create Non-Inventory Item.
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        // [GIVEN] Create Certified Production BOM with Non-Inventory item.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, NonInvItem."No.", LibraryRandom.RandIntInRange(1, 1));
        OutputItem.Validate("Replenishment System", OutputItem."Replenishment System"::"Prod. Order");
        OutputItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        OutputItem.Modify();

        // [GIVEN] Create and Post Purchase Document for Non-Inventory Item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, ConsumptionQuantity, NonInvUnitCost);

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, OutputItem."No.", Quantity, '', '');

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", NonInvItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal with partial quantity.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, ConsumptionQuantity);

        // [GIVEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, 0, 0);

        // [WHEN] Change Prod Order Status from Released to Finished.
        asserterror ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify user should not be able to change the status when "Mat. Non-Inv. Variance Acc." is missing in Inventory Posting Setup.
        InventoryPostingSetup.SetRange("Location Code", '');
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", OutputItem."Inventory Posting Group");
        InventoryPostingSetup.FindFirst();
        Assert.ExpectedError(
            StrSubstNo(MissingAccountTxt, InventoryPostingSetup.FieldCaption("Mat. Non-Inv. Variance Acc."), InventoryPostingSetup.TableCaption() + ' ' + InventoryPostingSetup.GetFilters()));
    end;

    [Test]
    [HandlerFunctions('SourceDocumentsPageHandler')]
    procedure WarehouseShipmentGetSourceDocumentsNotShowProdConsumptionLine()
    var
        Item: array[2] of Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipment: TestPage "Warehouse Shipment";
    begin
        // [SCENARIO 563482] The production order component line should not be displayed when retrieving source documents from a warehouse shipment.
        Initialize();

        // [GIVEN] Create Production BOM.
        CreateItemsSetup(Item[1], Item[2], LibraryRandom.RandInt(2));

        // [GIVEN] Modify Green Location.
        ModifyLocation(LocationBlue);

        // [GIVEN] Post Postive Adjustment.
        CreateAndPostItemJournalLine(Item[2]."No.", LibraryRandom.RandIntInRange(5, 10), LocationBlue.Code, '');

        // [GIVEN] Create Released Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item[1]."No.", 1, LocationBlue.Code, '');

        // [GIVEN] Create Warehouse Shipment Header.
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", LocationBlue.Code);
        WarehouseShipmentHeader.Modify(true);

        // [WHEN] Open Warehouse Shipment Page.
        WarehouseShipment.OpenEdit();
        WarehouseShipment.GoToRecord(WarehouseShipmentHeader);

        // [THEN] verify production order component line should not be displayed When 'Get Source Documents' was invoke.
        WarehouseShipment."Get Source Documents".Invoke();
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler2,ItemTrackingHandler,ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifySalesOrderShippedSucessfullyWhenItemWasLotTrackedAndPlannedProdOrderCreatedFromSalesOrder()
    var
        Item: Record Item;
        PlannedProductionOrder: Record "Production Order";
        ReleasedProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        CreateProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
        NewOrderType: Enum "Create Production Order Type";
    begin
        // [SCENARIO 565684] Verify if the sales order was successfully shipped if the item was lot-tracked and a planned production order was created from the sales order."
        Initialize();

        // [GIVEN] Create Item with Lot Tracking.
        CreateItemWithLotTracking(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::" ");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Modify(true);

        // [GIVEN] Create Sales Order and Released.
        CreateSalesOrderAndReleased(SalesHeader, SalesLine, Item."No.");

        // [GIVEN] Create Planned Production Order From Sales Order.
        CreateProdOrderFromSale.SetHideValidationDialog(false);
        CreateProdOrderFromSale.CreateProductionOrder(
            SalesLine, PlannedProductionOrder.Status::Planned, NewOrderType::ItemOrder);

        // [GIVEN] Verify Planned Production Order Was Created.
        PlannedProductionOrder.SetRange("Source No.", Item."No.");
        PlannedProductionOrder.SetRange(Status, PlannedProductionOrder.Status::Planned);
        PlannedProductionOrder.FindFirst();

        // [GIVEN] Convert Planned Production Order into Released Production Order.
        LibraryManufacturing.ChangeProuctionOrderStatus(
            PlannedProductionOrder."No.",
            PlannedProductionOrder.Status::Planned, PlannedProductionOrder.Status::Released);

        // [WHEN] Verify Released Production Order Was Created.
        ReleasedProductionOrder.SetRange(Status, ReleasedProductionOrder.Status::Released);
        ReleasedProductionOrder.SetRange("Planned Order No.", PlannedProductionOrder."No.");
        ReleasedProductionOrder.FindFirst();

        // [THEN] Verify that the reservation entry status has not been changed.
        VerifyReservationEntry(Item, Database::"Prod. Order Line", ReservationEntry."Reservation Status"::Reservation);
        VerifyReservationEntry(Item, Database::"Sales Line", ReservationEntry."Reservation Status"::Reservation);

        // [GIVEN] Enqueue Multiple Item Tracking Values. 
        OpenItemTrackingLinesSetValueInProdOrderLine(LibraryUtility.GenerateGUID(), '', SalesLine.Quantity);

        // [WHEN] Post Producton Journal.
        CreateAndPostProductionJnlWithLotNo(ReleasedProductionOrder, SalesLine."Line No.");

        // [THEN] Verify that the sales document was shipped successfully.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifyReverseCapacityLedgerEntryShouldBeCreatedWhenReverseIsExecutedWithOutputQuantity()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        CapacityLedgerEntry1: Record "Capacity Ledger Entry";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 569192] Verify Reverse production order transaction action in the capacity ledger entry revert the output quantity.
        Initialize();

        // [GIVEN] Create item with routing.
        Item.Get(CreateItemSerialRoutingSeveralLines(LibraryRandom.RandIntInRange(3, 10)));

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", ProductionOrder.Quantity, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2), 0, ProductionOrder.Quantity, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Find Capacity Ledger Entry.
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.FindFirst();

        // [GIVEN] OpenEdit Capacity Ledger Entries.
        CapacityLedgerEntries.OpenEdit();
        CapacityLedgerEntries.Filter.SetFilter("Entry No.", Format(CapacityLedgerEntry."Entry No."));

        // [WHEN] Invoke "Reverse" action.
        CapacityLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reverse production order transaction action in the capacity ledger entry revert the output quantity.
        CapacityLedgerEntry1.Get(CapacityLedgerEntries."Entry No.".AsInteger());
        FindLastCapacityLedgerEntry(CapacityLedgerEntry, "Inventory Order Type"::Production, CapacityLedgerEntry1."Order No.", CapacityLedgerEntry1."Order Line No.");
        Assert.AreEqual(
            -CapacityLedgerEntry1.Quantity,
            CapacityLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption(Quantity), -CapacityLedgerEntry1.Quantity, CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry1."Setup Time",
            CapacityLedgerEntry."Setup Time",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Setup Time"), -CapacityLedgerEntry1."Setup Time", CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry1."Run Time",
            CapacityLedgerEntry."Run Time",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Run Time"), -CapacityLedgerEntry1."Run Time", CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry1."Output Quantity",
            CapacityLedgerEntry."Output Quantity",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Output Quantity"), -CapacityLedgerEntry1."Output Quantity", CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry1."Scrap Quantity",
            CapacityLedgerEntry."Scrap Quantity",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Scrap Quantity"), -CapacityLedgerEntry1."Scrap Quantity", CapacityLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifyReverseCapacityLedgerEntryShouldBeCreatedWhenReverseIsExecutedFromItemLedgerEntries()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CapacityLedgerEntry: array[2] of Record "Capacity Ledger Entry";
        ItemLedgerEntry: array[2] of Record "Item Ledger Entry";
        CapacityLedgerEntry1: Record "Capacity Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 569192] Verify a reverse entry should be created for the last operation of the capacity ledger entry when the reverse action is executed from Item Ledger Entries.
        Initialize();

        // [GIVEN] Create item with routing.
        Item.Get(CreateItemSerialRoutingSeveralLines(LibraryRandom.RandIntInRange(3, 10)));

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandIntInRange(10, 20), '', '');

        // [GIVEN] Find Production Order Line.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithOutputQuantityAndUnitCost(
            ProductionOrder."No.",
            ProductionOrder.Quantity - 1,
            ProductionOrder.Quantity - 1,
            LibraryRandom.RandDec(10, 2));

        // [GIVEN] Find Last Capacity Ledger Entry.
        FindLastCapacityLedgerEntry(CapacityLedgerEntry[1], "Inventory Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");

        // [GIVEN] Find Last Item Ledger Entry.
        FindLastItemLedgerEntry(ItemLedgerEntry[1], "Inventory Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.", "Item Ledger Entry Type"::Output);

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithOutputQuantityAndUnitCost(
            ProductionOrder."No.",
            ProductionOrder.Quantity + LibraryRandom.RandInt(10),
            ProductionOrder.Quantity + LibraryRandom.RandInt(10),
            LibraryRandom.RandDec(10, 2));

        // [GIVEN] Find Last Capacity Ledger Entry.
        FindLastCapacityLedgerEntry(CapacityLedgerEntry[2], "Inventory Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");

        // [GIVEN] Find Last Item Ledger Entry.
        FindLastItemLedgerEntry(ItemLedgerEntry[2], "Inventory Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.", "Item Ledger Entry Type"::Output);

        // [GIVEN] OpenEdit Capacity Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Entry No.", Format(ItemLedgerEntry[1]."Entry No."));

        // [WHEN] Invoke "Reverse" action.
        ItemLedgerEntries.Reverse.Invoke();
        ItemLedgerEntries.Close();

        // [THEN] Verify Reverse production order transaction action in the capacity ledger entry revert the output quantity from Item Ledger Entry.
        FindLastCapacityLedgerEntry(CapacityLedgerEntry1, "Inventory Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");
        Assert.AreEqual(
            -CapacityLedgerEntry[1].Quantity,
            CapacityLedgerEntry1.Quantity,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption(Quantity), -CapacityLedgerEntry[1].Quantity, CapacityLedgerEntry[1].TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry[1]."Setup Time",
            CapacityLedgerEntry1."Setup Time",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption("Setup Time"), -CapacityLedgerEntry[1]."Setup Time", CapacityLedgerEntry[1].TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry[1]."Run Time",
            CapacityLedgerEntry1."Run Time",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption("Run Time"), -CapacityLedgerEntry[1]."Run Time", CapacityLedgerEntry[1].TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry[1]."Output Quantity",
            CapacityLedgerEntry1."Output Quantity",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption("Output Quantity"), -CapacityLedgerEntry[1]."Output Quantity", CapacityLedgerEntry[1].TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry[1]."Scrap Quantity",
            CapacityLedgerEntry1."Scrap Quantity",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption("Scrap Quantity"), -CapacityLedgerEntry[1]."Scrap Quantity", CapacityLedgerEntry[1].TableCaption()));

        // [GIVEN] OpenEdit Capacity Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Entry No.", Format(ItemLedgerEntry[2]."Entry No."));

        // [WHEN] Invoke "Reverse" action.
        ItemLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reverse production order transaction action in the capacity ledger entry revert the output quantity from Item Ledger Entry.
        FindLastCapacityLedgerEntry(CapacityLedgerEntry1, "Inventory Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");
        Assert.AreEqual(
            -CapacityLedgerEntry[2].Quantity,
            CapacityLedgerEntry1.Quantity,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption(Quantity), -CapacityLedgerEntry[2].Quantity, CapacityLedgerEntry[1].TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry[2]."Setup Time",
            CapacityLedgerEntry1."Setup Time",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption("Setup Time"), -CapacityLedgerEntry[2]."Setup Time", CapacityLedgerEntry[1].TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry[2]."Run Time",
            CapacityLedgerEntry1."Run Time",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption("Run Time"), -CapacityLedgerEntry[2]."Run Time", CapacityLedgerEntry[1].TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry[2]."Output Quantity",
            CapacityLedgerEntry1."Output Quantity",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption("Output Quantity"), -CapacityLedgerEntry[2]."Output Quantity", CapacityLedgerEntry[1].TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry[2]."Scrap Quantity",
            CapacityLedgerEntry1."Scrap Quantity",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption("Scrap Quantity"), -CapacityLedgerEntry[2]."Scrap Quantity", CapacityLedgerEntry[1].TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler3,ItemTrackingHandler,ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifyReversalConsumptionWithLotTrackingShouldBeAppliedCorrectly()
    var
        ProdItem: Record Item;
        ChildItem: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemTrackingCode: Record "Item Tracking Code";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
        Quantity: Integer;
        LotNo: array[3] of Code[50];
        UnitCost: array[3] of Decimal;
    begin
        // [SCENARIO 573819] Verify Reversal of consumption with lot tracking is applied correctly to original consumption.
        Initialize();

        // // [GIVEN] Create Item with Lot Tracking.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(ChildItem, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Generate Random Quantity, Lot No., Unit Cost.
        Quantity := LibraryRandom.RandInt(100);
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        LotNo[3] := LibraryUtility.GenerateGUID();
        UnitCost[1] := LibraryRandom.RandInt(100);
        UnitCost[2] := LibraryRandom.RandInt(100);
        UnitCost[3] := LibraryRandom.RandInt(100);

        // [GIVEN] Create and Post Item with Lot No.
        CreateAndPostInvtAdjustmentOfItemWithLot(ChildItem."No.", UnitCost[1], LotNo[1], Quantity);
        CreateAndPostInvtAdjustmentOfItemWithLot(ChildItem."No.", UnitCost[2], LotNo[2], Quantity);
        CreateAndPostInvtAdjustmentOfItemWithLot(ChildItem."No.", UnitCost[3], LotNo[3], Quantity);

        // [GIVEN] Create a Prod item.
        LibraryInventory.CreateItem(ProdItem);

        // [GIVEN] Create Released Production Order.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item,
            '',
            0);

        // [GIVEN] Create Released Production Order Line with Prod Item.
        LibraryManufacturing.CreateProdOrderLine(ProductionOrderLine, ProductionOrder.Status, ProductionOrder."No.", ProdItem."No.", '', '', LibraryRandom.RandInt(1));

        // [GIVEN] Create Released Production Order Component with Child Item.
        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProductionOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ChildItem."No.");
        ProdOrderComponent.Validate("Quantity per", Quantity * 2);
        ProdOrderComponent.Modify();

        // [GIVEN] Create Item Tracking Lines for Prod Order Component with Lot 2 ,3.
        OpenItemTrackingLinesSetValue(ProdOrderComponent, LotNo[2], '', Quantity);
        OpenItemTrackingLinesSetValue(ProdOrderComponent, LotNo[3], '', Quantity);

        // [GIVEN] Post Producton Journal.
        CreateAndPostProductionJnlWithLotNo(ProductionOrder, ProductionOrderLine."Line No.");

        // [GIVEN] Execute Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(ChildItem."No.", '');

        // [GIVEN] OpenEdit Capacity Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Item No.", ChildItem."No.");
        ItemLedgerEntries.Filter.SetFilter("Entry Type", Format(ItemLedgerEntry."Entry Type"::Consumption));
        ItemLedgerEntries.Filter.SetFilter("Lot No.", LotNo[2]);

        // [WHEN] Invoke "Reverse" action.
        ItemLedgerEntries.Reverse.Invoke();
        LibraryCosting.AdjustCostItemEntries(ChildItem."No.", '');

        // [THEN] Verify Reversal of consumption with lot tracking is applied correctly to original consumption.
        FindLastItemLedgerEntry(ItemLedgerEntry, "Inventory Order Type"::Production, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.", "Item Ledger Entry Type"::Consumption);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreEqual(
            -ItemLedgerEntries.Quantity.AsInteger(),
            ItemLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ItemLedgerEntry.FieldCaption(Quantity), -ItemLedgerEntries.Quantity.AsInteger(), ItemLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -ItemLedgerEntries."Cost Amount (Actual)".AsDecimal(),
            ItemLedgerEntry."Cost Amount (Actual)",
            StrSubstNo(ValueMustBeEqualErr, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), -ItemLedgerEntries."Cost Amount (Actual)".AsDecimal(), ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifyReverseCapacityLedgerEntryShouldBeCreatedWhenReverseIsExecutedWithStopTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        CapacityLedgerEntry1: Record "Capacity Ledger Entry";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 574924] Verify Reverse production order transaction action in the capacity ledger entry revert the Stop time.
        Initialize();

        // [GIVEN] Create item with routing.
        Item.Get(CreateItemSerialRoutingSeveralLines(LibraryRandom.RandIntInRange(3, 10)));

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", ProductionOrder.Quantity, 0, 0, LibraryRandom.RandDec(10, 2), 0, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Find Capacity Ledger Entry.
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.FindFirst();

        // [GIVEN] OpenEdit Capacity Ledger Entries.
        CapacityLedgerEntries.OpenEdit();
        CapacityLedgerEntries.Filter.SetFilter("Entry No.", Format(CapacityLedgerEntry."Entry No."));

        // [WHEN] Invoke "Reverse" action.
        CapacityLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reverse production order transaction action in the capacity ledger entry revert the Stop Time.
        CapacityLedgerEntry1.Get(CapacityLedgerEntries."Entry No.".AsInteger());
        FindLastCapacityLedgerEntry(CapacityLedgerEntry, "Inventory Order Type"::Production, CapacityLedgerEntry1."Order No.", CapacityLedgerEntry1."Order Line No.");
        Assert.AreEqual(
            -CapacityLedgerEntry1.Quantity,
            CapacityLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption(Quantity), -CapacityLedgerEntry1.Quantity, CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry1."Setup Time",
            CapacityLedgerEntry."Setup Time",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Setup Time"), -CapacityLedgerEntry1."Setup Time", CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry1."Stop Time",
            CapacityLedgerEntry."Stop Time",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Stop Time"), -CapacityLedgerEntry1."Stop Time", CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry1."Run Time",
            CapacityLedgerEntry."Run Time",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Run Time"), -CapacityLedgerEntry1."Run Time", CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry1."Output Quantity",
            CapacityLedgerEntry."Output Quantity",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Output Quantity"), -CapacityLedgerEntry1."Output Quantity", CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            -CapacityLedgerEntry1."Scrap Quantity",
            CapacityLedgerEntry."Scrap Quantity",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Scrap Quantity"), -CapacityLedgerEntry1."Scrap Quantity", CapacityLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure RegisterPartialPutAwayAfterSortingWhseActivityLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        QtyToHandle: Decimal;
        WareHouseActionType: Enum "Warehouse Action Type";
    begin
        // [SCENARIO 598381] Regiter partial Whse Put-away successfully when sorting set on Qty. to Handle
        Initialize();

        // [GIVEN] Create an Item
        CreateItem(Item);

        // [GIVEN] Create Whse. Receipt form Purchase Order
        CreateWhseReceiptFromPurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, LibraryRandom.RandInt(20));

        // [GIVEN] Post Warehouse Receipt
        PostWarehouseReceipt(PurchaseHeader."No.");

        // [WHEN] Update Qty. to Handle, sort the Wharehouse Activity Line on Qty. to Handle and register Warehouse Activity
        QtyToHandle := LibraryRandom.RandInt(5);
        UpdateQuantityToHandleAndRegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away", QtyToHandle);

        // [THEN] Verify registered Warehouse Activity Lines
        VerifyRegisteredWhseActivityLine(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away", WareHouseActionType::Take, QtyToHandle);
        VerifyRegisteredWhseActivityLine(PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away", WareHouseActionType::Place, QtyToHandle);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifyReverseItemLedgerEntryShouldBeCreatedForConsumptionWithSamePostedValue()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 591598] Reversal of production consumption in alternative UoM - verify reverted quantity
        Initialize();

        // [GIVEN] Create Production Order With Component.
        CreateProdOrderAddNewComponentAndCreateConsumptionLineWithDifferentUOM(ProdOrderComponent, 1);

        // [GIVEN] Post Consumption Journal Line for this Component.
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        // [GIVEN] OpenEdit Item Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Document No.", ProdOrderComponent."Prod. Order No.");
        ItemLedgerEntries.Filter.SetFilter("Entry Type", Format(ItemLedgerEntry."Entry Type"::Consumption));

        // [WHEN] Invoke "Reverse" action.
        ItemLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reverse Entry should be created of Item Ledger Entry.
        FindLastItemLedgerEntry(ItemLedgerEntry, "Inventory Order Type"::Production, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.", "Item Ledger Entry Type"::Consumption);
        Assert.AreEqual(
            -ItemLedgerEntries.Quantity.AsDecimal(),
            ItemLedgerEntry.Quantity,
            StrSubstNo(ValueMustBeEqualErr, ItemLedgerEntry.FieldCaption(Quantity), -ItemLedgerEntries.Quantity.AsInteger(), ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifyReverseCapacityLedgerEntryShouldBeCreatedWhenReverseIsExecuted()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        CapacityLedgerEntry1: Record "Capacity Ledger Entry";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 574825] Verify that the "Reversed", "Reversed Entry No.", and "Reversed by Entry No." fields in the Capacity Ledger Entry are correctly updated when the Reverse Production Order Transaction action is executed.
        Initialize();

        // [GIVEN] Create item with routing.
        Item.Get(CreateItemSerialRoutingSeveralLines(LibraryRandom.RandIntInRange(3, 10)));

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", ProductionOrder.Quantity, 0, 0, LibraryRandom.RandDec(10, 2), 0, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Find Capacity Ledger Entry.
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.FindFirst();

        // [GIVEN] OpenEdit Capacity Ledger Entries.
        CapacityLedgerEntries.OpenEdit();
        CapacityLedgerEntries.Filter.SetFilter("Entry No.", Format(CapacityLedgerEntry."Entry No."));

        // [WHEN] Invoke "Reverse" action.
        CapacityLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reversed, "Reversed Entry No.", "Reversed by Entry No." fields in the capacity ledger entry when Reverse production order transaction action is executed.
        CapacityLedgerEntry1.Get(CapacityLedgerEntries."Entry No.".AsInteger());
        FindLastCapacityLedgerEntry(CapacityLedgerEntry, "Inventory Order Type"::Production, CapacityLedgerEntry1."Order No.", CapacityLedgerEntry1."Order Line No.");
        Assert.AreEqual(
            CapacityLedgerEntry1."Entry No.",
            CapacityLedgerEntry."Reversed Entry No.",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Reversed Entry No."), CapacityLedgerEntry1."Entry No.", CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            0,
            CapacityLedgerEntry."Reversed by Entry No.",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Reversed by Entry No."), 0, CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            true,
            CapacityLedgerEntry.Reversed,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption(Reversed), true, CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            CapacityLedgerEntry1.Description,
            CapacityLedgerEntry.Description,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption(Description), CapacityLedgerEntry1.Description, CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            0,
            CapacityLedgerEntry1."Reversed Entry No.",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Reversed Entry No."), 0, CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            CapacityLedgerEntry."Entry No.",
            CapacityLedgerEntry1."Reversed by Entry No.",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption("Reversed by Entry No."), CapacityLedgerEntry."Entry No.", CapacityLedgerEntry.TableCaption()));
        Assert.AreEqual(
            true,
            CapacityLedgerEntry1.Reversed,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry.FieldCaption(Reversed), true, CapacityLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifyReverseCapacityLedgerEntryCannotBeReversedMultipleTime()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 574825] Verify that a Capacity Ledger Entry cannot be reversed more than once.
        Initialize();

        // [GIVEN] Create item with routing.
        Item.Get(CreateItemSerialRoutingSeveralLines(LibraryRandom.RandIntInRange(3, 10)));

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", ProductionOrder.Quantity, 0, 0, LibraryRandom.RandDec(10, 2), 0, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Find Capacity Ledger Entry.
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.FindFirst();

        // [GIVEN] OpenEdit Capacity Ledger Entries.
        CapacityLedgerEntries.OpenEdit();
        CapacityLedgerEntries.Filter.SetFilter("Entry No.", Format(CapacityLedgerEntry."Entry No."));

        // [GIVEN] Invoke "Reverse" action.
        CapacityLedgerEntries.Reverse.Invoke();

        // [WHEN] Invoke "Reverse" action.
        asserterror CapacityLedgerEntries.Reverse.Invoke();

        // [THEN] Verify that a Capacity Ledger Entry cannot be reversed more than once.
        Assert.ExpectedError(StrSubstNo(CannotReverseCapacityLedgerEntryErr, CapacityLedgerEntry.TableCaption(), CapacityLedgerEntry."Entry No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandlerWithoutValidation')]
    procedure VerifyReverseCapacityLedgerEntryShouldBeUpdatedWhenReverseIsExecutedFromItemLedgerEntries()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CapacityLedgerEntry: array[2] of Record "Capacity Ledger Entry";
        ItemLedgerEntry: array[2] of Record "Item Ledger Entry";
        CapacityLedgerEntry1: Record "Capacity Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 560186] Verify a reverse entry should be created and updated for the last operation of the capacity ledger entry when the reverse action is executed from Item Ledger Entries.
        Initialize();

        // [GIVEN] Create item with routing.
        Item.Get(CreateItemSerialRoutingSeveralLines(LibraryRandom.RandIntInRange(3, 10)));

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandIntInRange(10, 20), '', '');

        // [GIVEN] Find Production Order Line.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithOutputQuantityAndUnitCost(
            ProductionOrder."No.",
            ProductionOrder.Quantity - 1,
            ProductionOrder.Quantity - 1,
            LibraryRandom.RandDec(10, 2));

        // [GIVEN] Find Last Capacity Ledger Entry.
        FindLastCapacityLedgerEntry(CapacityLedgerEntry[1], "Inventory Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");

        // [GIVEN] Find Last Item Ledger Entry.
        FindLastItemLedgerEntry(ItemLedgerEntry[1], "Inventory Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.", "Item Ledger Entry Type"::Output);

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournalWithOutputQuantityAndUnitCost(
            ProductionOrder."No.",
            ProductionOrder.Quantity + LibraryRandom.RandInt(10),
            ProductionOrder.Quantity + LibraryRandom.RandInt(10),
            LibraryRandom.RandDec(10, 2));

        // [GIVEN] Find Last Capacity Ledger Entry.
        FindLastCapacityLedgerEntry(CapacityLedgerEntry[2], "Inventory Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");

        // [GIVEN] Find Last Item Ledger Entry.
        FindLastItemLedgerEntry(ItemLedgerEntry[2], "Inventory Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.", "Item Ledger Entry Type"::Output);

        // [GIVEN] OpenEdit Capacity Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Entry No.", Format(ItemLedgerEntry[1]."Entry No."));

        // [WHEN] Invoke "Reverse" action.
        ItemLedgerEntries.Reverse.Invoke();
        ItemLedgerEntries.Close();

        // [THEN] Verify Reverse production order transaction action in the capacity ledger entry.
        FindLastCapacityLedgerEntry(CapacityLedgerEntry1, "Inventory Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");
        CapacityLedgerEntry[1].Get(CapacityLedgerEntry[1]."Entry No.");
        Assert.AreEqual(
            CapacityLedgerEntry[1]."Entry No.",
            CapacityLedgerEntry1."Reversed Entry No.",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption("Reversed Entry No."), CapacityLedgerEntry[1]."Entry No.", CapacityLedgerEntry[1].TableCaption()));
        Assert.AreEqual(
            0,
            CapacityLedgerEntry1."Reversed by Entry No.",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry1.FieldCaption("Reversed by Entry No."), 0, CapacityLedgerEntry1.TableCaption()));
        Assert.AreEqual(
            true,
            CapacityLedgerEntry1.Reversed,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry1.FieldCaption(Reversed), true, CapacityLedgerEntry1.TableCaption()));
        Assert.AreEqual(
            CapacityLedgerEntry[1].Description,
            CapacityLedgerEntry1.Description,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry1.FieldCaption(Description), CapacityLedgerEntry[1].Description, CapacityLedgerEntry1.TableCaption()));
        Assert.AreEqual(
            0,
            CapacityLedgerEntry[1]."Reversed Entry No.",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption("Reversed Entry No."), 0, CapacityLedgerEntry[1].TableCaption()));
        Assert.AreEqual(
            CapacityLedgerEntry1."Entry No.",
            CapacityLedgerEntry[1]."Reversed by Entry No.",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry1.FieldCaption("Reversed by Entry No."), CapacityLedgerEntry1."Entry No.", CapacityLedgerEntry1.TableCaption()));
        Assert.AreEqual(
            true,
            CapacityLedgerEntry[1].Reversed,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption(Reversed), true, CapacityLedgerEntry[1].TableCaption()));

        // [GIVEN] OpenEdit Capacity Ledger Entries.
        ItemLedgerEntries.OpenEdit();
        ItemLedgerEntries.Filter.SetFilter("Entry No.", Format(ItemLedgerEntry[2]."Entry No."));

        // [WHEN] Invoke "Reverse" action.
        ItemLedgerEntries.Reverse.Invoke();

        // [THEN] Verify Reverse production order transaction action in the capacity ledger entry.
        FindLastCapacityLedgerEntry(CapacityLedgerEntry1, "Inventory Order Type"::Production, ProductionOrder."No.", ProdOrderLine."Line No.");
        CapacityLedgerEntry[2].Get(CapacityLedgerEntry[2]."Entry No.");
        Assert.AreEqual(
            CapacityLedgerEntry[2]."Entry No.",
            CapacityLedgerEntry1."Reversed Entry No.",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption("Reversed Entry No."), CapacityLedgerEntry[2]."Entry No.", CapacityLedgerEntry[1].TableCaption()));
        Assert.AreEqual(
            0,
            CapacityLedgerEntry1."Reversed by Entry No.",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry1.FieldCaption("Reversed by Entry No."), 0, CapacityLedgerEntry1.TableCaption()));
        Assert.AreEqual(
            true,
            CapacityLedgerEntry1.Reversed,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry1.FieldCaption(Reversed), true, CapacityLedgerEntry1.TableCaption()));
        Assert.AreEqual(
            CapacityLedgerEntry[2].Description,
            CapacityLedgerEntry1.Description,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry1.FieldCaption(Description), CapacityLedgerEntry[2].Description, CapacityLedgerEntry1.TableCaption()));
        Assert.AreEqual(
            0,
            CapacityLedgerEntry[2]."Reversed Entry No.",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption("Reversed Entry No."), 0, CapacityLedgerEntry[1].TableCaption()));
        Assert.AreEqual(
            CapacityLedgerEntry1."Entry No.",
            CapacityLedgerEntry[2]."Reversed by Entry No.",
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry1.FieldCaption("Reversed by Entry No."), CapacityLedgerEntry1."Entry No.", CapacityLedgerEntry1.TableCaption()));
        Assert.AreEqual(
            true,
            CapacityLedgerEntry[2].Reversed,
            StrSubstNo(ValueMustBeEqualErr, CapacityLedgerEntry[1].FieldCaption(Reversed), true, CapacityLedgerEntry[1].TableCaption()));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Production Order III");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Production Order III");

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
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Production Order III");
    end;

    local procedure InitSetupForProdBOMWithMultipleUOM(var Item: Record Item; var ChildItem: Record Item; var QuantityPer: Decimal; var QtyPerUnitOfMeasure: Decimal; var AvailableQty: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        QuantityPer := LibraryRandom.RandIntInRange(2, 5);
        QtyPerUnitOfMeasure := LibraryRandom.RandIntInRange(2, 5);
        AvailableQty := LibraryRandom.RandIntInRange(50, 100);

        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem, QuantityPer);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ChildItem."No.", QtyPerUnitOfMeasure);
        UpdateBOMHeaderWithLineUOM(Item."Production BOM No.", ChildItem."No.", ItemUnitOfMeasure.Code);
        CreateAndPostItemJournalLine(ChildItem."No.", AvailableQty, '', '');
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
        LibraryWarehouse.CreateNumberOfBins(LocationRed.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value  required for number of Bins.

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

    local procedure AcceptActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    local procedure AcceptAndCarryOutActionMessageForPlanningWorksheet(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CalculateWhseAdjustmentAndPostCreatedItemJournalLine(Item: Record Item; ItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
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

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10])
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

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

    local procedure CreateItemWithBOMAndRouting(var Item: Record Item; var ChildItem: Record Item; QuantityPer: Decimal)
    var
        WorkCenter: Record "Work Center";
    begin
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::"Pick + Backward");
        UpdateBOMHeader(Item."Production BOM No.", ChildItem."No.", CreateRoutingAndUpdateItem(Item, WorkCenter));
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify();
    end;

    local procedure CreateItemWithRouting(): Code[20]
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
    begin
        CreateItem(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify();
        exit(Item."No.");
    end;

    local procedure CreateSimpleItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateItemSubstitution(ItemNo: array[10] of Code[20]; ItemIndex: Integer)
    var
        ItemSubstitution: Record "Item Substitution";
        i: Integer;
    begin
        ItemSubstitution.Init();
        ItemSubstitution.Type := ItemSubstitution.Type::Item;
        ItemSubstitution."No." := ItemNo[ItemIndex];
        ItemSubstitution."Substitute Type" := ItemSubstitution."Substitute Type"::Item;
        for i := 0 to ArrayLen(ItemNo) - 2 do begin
            ItemSubstitution."Substitute No." := ItemNo[1 + ((ItemIndex + i) mod ArrayLen(ItemNo))];
            // all ItemNo except ItemIndex
            ItemSubstitution.Insert();
        end;
    end;

    local procedure CreateProdItemWithScrapAndFlushingMethod(var Item: Record Item; var ChildItemNo: Code[20]; FlushingMethod: Enum "Flushing Method"; QtyPer: Decimal; MultipleRoutingLine: Boolean; ScrapFactor: Decimal; FixedScrapQuantity: Decimal; Tracking: Boolean)
    var
        ChildItem: Record Item;
    begin
        CreateItemsSetup(Item, ChildItem, QtyPer);
        ChildItemNo := ChildItem."No.";
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);

        // Create Routing with 2 routing lines, set Scrap % and Fixed Scrap Quantity in Routing Line, set flushing method for work center bound to the routing line
        if Tracking then
            UpdateItemForLotTrackingAndFlushingMethod(ChildItem, ChildItem."Flushing Method"::Backward);
        CreateRoutingWithScrapAndFlushingMethod(Item, FlushingMethod, MultipleRoutingLine, ScrapFactor, FixedScrapQuantity);
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

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, SourceNo, Quantity, LocationCode, BinCode);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLineWithTracking(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, '', '');
        OpenItemTrackingLines(ItemJournalLine, ItemTrackingMode::AssignLotNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostInvtAdjustmentOfItemWithLot(ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, '', '', Qty);
        OpenItemTrackingLinesSetValue(ItemJournalLine, LotNo, '', ItemJournalLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrderNo: Code[20]; OutputQuantity: Decimal; RunTime: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure AcceptAndCarryOutActionMessageForRequisitionWorksheet(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure AssignTrackingOnProdOrderLine(ProdOrderNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.OpenItemTrackingLines();  // Invokes ItemTrackingPageHandler.
    end;

    local procedure CalculateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CreateAndPostConsumptionJournal(
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Consumption, ProdOrderComponent."Item No.", Quantity);
        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Validate("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CalculateAndPostConsumptionJournalWithItemTracking(ProductionOrderNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        ItemJournalLine.Validate(Quantity, Qty);
        ItemJournalLine.Modify(true);
        OpenItemTrackingLines(ItemJournalLine, ItemTrackingMode::SelectEntries);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CreateAndPostOutputJournalWithExplodeRouting(ProductionOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrderNo);
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateLinkedProdBOMLineAndRoutingLine(var ProductionBOMHeader: Record "Production BOM Header"; var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        RoutingLine: Record "Routing Line";
    begin
        CreateRoutingLineWithRoutingLink(RoutingLine, RoutingHeader, WorkCenterNo);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        ProductionBOMLine.Validate("Routing Link Code", RoutingLine."Routing Link Code");
        ProductionBOMLine.Modify(true);
    end;

    local procedure CreateOutputJournalWithExplodeRouting(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20])
    begin
        CreateOutputJournal(ItemJournalLine, ProductionOrderNo, '');
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
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

    local procedure CreateOutputCorrectionWithLocationAndItemTracking(var Item: Record Item; var ProductionOrder: Record "Production Order"; LocationCode: Code[10]; ApplyToItemEntry: Boolean)
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // Setup: Create Production Item, create a Require-Pick Location
        Initialize();
        CreateItemWithItemTrackingCode(Item);
        CreateRoutingAndUpdateItem(Item, WorkCenter); // Set Routing No. for Item
        FindLastRoutingLine(RoutingLine, Item."Routing No."); // The Operation No. for last routing line is needed when posting output with negative quantity

        // Create and refresh release Production Order with setting Location code
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), LocationCode, '');
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", ProductionOrder.Quantity);

        // Create Output Correction Journal with Location and Item Tracking.
        CreateOutputJournalWithApplyEntryAndItemTracking(
            Item."No.", -ProductionOrder.Quantity, RoutingLine."Operation No.", ApplyToItemEntry);
    end;

    local procedure CreateAndPostOutputJournalWithItemTracking(ProductionOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrderNo);
        OpenItemTrackingLines(ItemJournalLine, ItemTrackingMode::AssignLotNo);

        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Modify(true);
        UpdateInventoryAccountInterim(ItemJournalLine."Location Code", ItemJournalLine."Inventory Posting Group");
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournalWithApplyEntryAndOperationNo(ItemNo: Code[20]; OutputQuantity: Decimal; OperationNo: Code[10]; SetAppliesToEntry: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemJournalLine."Entry Type"::Output, ItemNo);
        CreateOutputJournal(ItemJournalLine, ItemLedgerEntry."Document No.", ItemNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Validate("Operation No.", OperationNo);

        if SetAppliesToEntry then
            ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateOutputJournalWithApplyEntryAndItemTracking(ItemNo: Code[20]; OutputQuantity: Decimal; OperationNo: Code[10]; ApplyToItemEntry: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemJournalLine."Entry Type"::Output, ItemNo);
        CreateOutputJournal(ItemJournalLine, ItemLedgerEntry."Document No.", ItemNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);

        if ApplyToItemEntry then
            OpenItemTrackingLinesSelectAndApply(ItemJournalLine, ItemLedgerEntry."Entry No.")
        else
            OpenItemTrackingLines(ItemJournalLine, ItemTrackingMode::SelectEntries);

        ItemJournalLine.Validate("Operation No.", OperationNo);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; MultipleLines: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        if MultipleLines then
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesOrderOnLocation(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        UpdateLocationOnSalesLine(SalesLine."Document No.", LocationCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithMultipleLines(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateSalesOrder(SalesHeader, ItemNo, Quantity, true);  // Multiple Sales Lines TRUE.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name"; Type: Enum "Req. Worksheet Template Type")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateAndPostSalesOrderAsShip(var Item: Record Item; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, Item."No.", Quantity, false);  // Multiple Sales Lines FALSE.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship only.
    end;

    local procedure CalculatePlanForRequisitionWorksheet(var Item: Record Item)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName, RequisitionWkshName."Template Type"::"Req.");
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate(), WorkDate());
    end;

    local procedure CreateMaximumQtyItem(var Item: Record Item; MaximumInventory: Decimal)
    begin
        CreateItem(Item);
        UpdateItemParametersForPlanning(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Maximum Qty.");
        Item.Validate("Reorder Point", LibraryRandom.RandDec(10, 2) + 10);  // Large Random Value required for test.
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Minimum Order Quantity", LibraryRandom.RandDec(10, 2));  // Minimum Order Quantity less than Reorder Point Quantity.
        Item.Validate("Maximum Order Quantity", MaximumInventory + LibraryRandom.RandDec(100, 2));  // Maximum Order Quantity more than Maximum Inventory.
        Item.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrderAsReceive(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateSalesOrderFromBlanketOrder(var SalesHeader: Record "Sales Header"; var SalesOrderHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        BlanketSalesOrderToOrder: Codeunit "Blanket Sales Order to Order";
    begin
        CreateBlanketOrder(SalesHeader, ItemNo, Quantity, LocationCode);
        BlanketSalesOrderToOrder.Run(SalesHeader);
        BlanketSalesOrderToOrder.GetSalesOrderHeader(SalesOrderHeader);
    end;

    local procedure CreateBlanketOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
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

    local procedure CalculateSubcontractOrder(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.SetRange("No.", WorkCenter."No.");
        LibraryManufacturing.CalculateSubcontractOrder(WorkCenter);
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

    local procedure CreateRouting(WorkCenterNo: Code[20]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(10)), RoutingLine.Type::"Work Center", WorkCenterNo);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        exit(RoutingHeader."No.");
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

    local procedure CreateRoutingLineWithRoutingLink(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20])
    var
        RoutingLink: Record "Routing Link";
    begin
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo);
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);
    end;

    local procedure CreateRoutingAndUpdateItem(var Item: Record Item; var WorkCenter: Record "Work Center"): Code[10]
    begin
        exit(CreateRoutingAndUpdateItemSubc(Item, WorkCenter, false));
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

        exit(RoutingLink.Code);
    end;

    local procedure CreateItemSerialRoutingSeveralLines(LinesCount: Integer): Code[20]
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        I: Integer;
    begin
        LibraryInventory.CreateItem(Item);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for I := 1 to LinesCount do begin
            CreateWorkCenter(WorkCenter, false);
            CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        end;

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateFamily(var Family: Record Family; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    var
        FamilyLine: Record "Family Line";
    begin
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo, Quantity);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo2, Quantity);
    end;

    local procedure CreateItemHierarchyForFamily(var ParentItem: Record Item; var ParentItem2: Record Item; var ChildItem: Record Item; var ChildItem2: Record Item; QuantityPer: Decimal)
    begin
        CreateItemsSetup(ParentItem, ChildItem, QuantityPer);
        CreateItemsSetup(ParentItem2, ChildItem2, QuantityPer);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandInt(100), '', '');
        CreateAndPostItemJournalLine(ChildItem2."No.", LibraryRandom.RandInt(100), '', '');
    end;

    local procedure CreateAndRefreshProductionOrderWithSourceTypeFamily(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Family, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateRequisitionLineWithPlanningRouting(var RequisitionLine: Record "Requisition Line"; var WorkCenter: Record "Work Center"; var ItemNo: Code[20])
    var
        Item: Record Item;
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        CreateWorkCenterWithLocationAndBin(WorkCenter, LocationRed.Code);
        CreateSalesOrderWithItem(Item);
        CreateRequisitionLineWithWorkCenter(RequisitionLine, WorkCenter, Item);
        CreatePlanningRoutingLineWithWorkCenter(PlanningRoutingLine, RequisitionLine, WorkCenter);
        ItemNo := Item."No.";
    end;

    local procedure CreateRequisitionLineWithWorkCenter(var RequisitionLine: Record "Requisition Line"; WorkCenter: Record "Work Center"; Item: Record Item)
    begin
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());  // Calculate Regenerative Plan on WORKDATE.
        FindRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.Validate("Location Code", WorkCenter."Location Code");
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify();
    end;

    local procedure CreateWorkCenterWithLocationAndBin(var WorkCenter: Record "Work Center"; LocationCode: Code[10])
    var
        BinFrom: Record Bin;
        BinTo: Record Bin;
        BinOpenShopFloor: Record Bin;
    begin
        LibraryWarehouse.FindBin(BinFrom, LocationCode, '', 1);  // Find Bin of Index 1.
        LibraryWarehouse.FindBin(BinTo, LocationCode, '', 2);
        LibraryWarehouse.FindBin(BinOpenShopFloor, LocationCode, '', 3);

        CreateWorkCenter(WorkCenter, false);
        WorkCenter.Validate("Location Code", LocationCode);
        WorkCenter.Validate("From-Production Bin Code", BinFrom.Code);
        WorkCenter.Validate("To-Production Bin Code", BinTo.Code);
        WorkCenter.Validate("Open Shop Floor Bin Code", BinOpenShopFloor.Code);
        WorkCenter.Modify();
    end;

    local procedure CreateWorkCenterWithNewToProductionBin(var WorkCenter: Record "Work Center"; LocationCode: Code[10])
    var
        Bin: Record Bin;
    begin
        CreateWorkCenterWithLocationAndBin(WorkCenter, LocationCode);
        LibraryWarehouse.CreateBin(Bin, LocationCode, '', '', '');
        WorkCenter.Validate("To-Production Bin Code", Bin.Code);
        WorkCenter.Modify(true);
    end;

    local procedure CreateWorkCenterWithFromProductionBinCode(var WorkCenter: Record "Work Center"; LocationCode: Code[10]; FromProductionBinCode: Code[20])
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Location Code", LocationCode);
        WorkCenter.Validate("From-Production Bin Code", FromProductionBinCode);
        WorkCenter.Modify(true);
    end;

    local procedure CreateSalesOrderWithItem(var Item: Record Item)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify();

        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandInt(10), false);  // Multiple Sales Lines FALSE.
    end;

    local procedure CreatePlanningRoutingLineWithWorkCenter(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line"; WorkCenter: Record "Work Center")
    begin
        CreatePlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
        PlanningRoutingLine.Validate("No.", WorkCenter."No.");
        PlanningRoutingLine.Modify();
    end;

    local procedure CreateMultipleItemUnitOfMeasureSetup(var Item: Record Item; var PurchItemUnitOfMeasure: Record "Item Unit of Measure"; var PutawayItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        QtyPerUnitOfMeasure: Integer;
    begin
        QtyPerUnitOfMeasure := LibraryRandom.RandInt(10);
        LibraryInventory.CreateItemUnitOfMeasureCode(PurchItemUnitOfMeasure, Item."No.", QtyPerUnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasureCode(PutawayItemUnitOfMeasure, Item."No.", 2 * QtyPerUnitOfMeasure);
        Item.Validate("Purch. Unit of Measure", PurchItemUnitOfMeasure.Code);
        Item.Validate("Put-away Unit of Measure Code", PutawayItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateWhseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, ItemNo, LocationCode, Quantity);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateWarehouseJournalLine(var Item: Record Item; var WarehouseJournalLine: Record "Warehouse Journal Line"; Location: Record Location; Quantity: Decimal)
    var
        Bin: Record Bin;
    begin
        Bin.Get(Location.Code, Location."Cross-Dock Bin Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, Bin."Zone Code",
          Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
    end;

    local procedure CreateAndCertifyProdBOMWithMultipleComponent(var Item: Record Item; var Item2: Record Item; var Item3: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItem(Item);  // Parent Item.
        // Create Component Items.
        CreateItem(Item2);
        CreateItem(Item3);
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
          ProductionBOMHeader, Item2."No.", Item3."No.", LibraryRandom.RandInt(5));
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateAndPostOutputJournalWithApplyEntry(ItemNo: Code[20]; OutputQuantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemJournalLine."Entry Type"::Output, ItemNo);
        CreateOutputJournal(ItemJournalLine, ItemLedgerEntry."Document No.", ItemNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndPostOutputJournalWithApplyEntryAndOperationNo(ItemNo: Code[20]; OutputQuantity: Decimal; OperationNo: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemJournalLine."Entry Type"::Output, ItemNo);
        CreateOutputJournal(ItemJournalLine, ItemLedgerEntry."Document No.", ItemNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Validate("Operation No.", OperationNo);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournal(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ItemNo, ProductionOrderNo);
    end;

    local procedure CreateReversedOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; ItemNo: Code[20]; RoutingOperationNo: Code[10]; Qty: Decimal)
    begin
        CreateOutputJournal(ItemJournalLine, ProdOrderNo, ItemNo);
        ItemJournalLine.Validate("Output Quantity", Qty);
        ItemJournalLine.Validate("Operation No.", RoutingOperationNo);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateProdOrderItemSetupWithOutputJournalAndExplodeRouting(
        var Item: Record Item; var ChildItem: Record Item; var ProductionOrder: Record "Production Order"; ProdQty: Decimal; BOMQtyPer: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateItemsSetup(Item, ChildItem, BOMQtyPer);
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::Backward);
        CreateAndPostPurchaseOrderAsReceive(PurchaseHeader, ChildItem."No.", ProdQty * BOMQtyPer);
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", ProdQty, '', '');
        CreateAndPostOutputJournalWithExplodeRouting(ProductionOrder."No.", ProductionOrder.Quantity);  // Create and post Output Journal for the Production Order.
    end;

    local procedure CreateProdOrderComponent(ProductionOrder: Record "Production Order"; var NewProdOrderComponent: Record "Prod. Order Component"; QuantityPer: Decimal)
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndInitNewProdOrderComponent(NewProdOrderComponent, ProdOrderComponent, ProductionOrder);
        NewProdOrderComponent.Validate("Item No.", Item."No.");
        NewProdOrderComponent.Validate("Quantity per", QuantityPer);
        NewProdOrderComponent.Insert(true);
    end;

    local procedure CreatePlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; var RequisitionLine: Record "Requisition Line")
    begin
        PlanningRoutingLine.Init();
        PlanningRoutingLine.Validate("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.Validate("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRoutingLine.Validate("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.Validate("Operation No.", LibraryUtility.GenerateGUID());
        PlanningRoutingLine.Insert(true);
    end;

    local procedure CreateCertifiedProductionBOMVersionWithCopyBOM(ProductionBOMNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        ProductionBOMHeader.Get(ProductionBOMNo);
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMNo,
          LibraryUtility.GenerateRandomCode(ProductionBOMVersion.FieldNo("Version Code"), DATABASE::"Production BOM Version"),
          UnitOfMeasureCode);
        ProductionBOMCopy.CopyBOM(ProductionBOMNo, '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        ProductionBOMVersion.Validate(Status, ProductionBOMVersion.Status::Certified);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrderWithDirectUnitCostAsReceive(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateRoutingWithScrapAndFlushingMethod(var Item: Record Item; FlushingMethod: Enum "Flushing Method"; MultipleRoutingLine: Boolean; ScrapFactor: Decimal; FixedScrapQuantity: Decimal)
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        CreateRoutingAndUpdateItem(Item, WorkCenter);
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify();
        UpdateFlushingMethodOnWorkCenter(WorkCenter, FlushingMethod); // The flushing method on work center will be copied to Prod. Order Routing Line
        RoutingHeader.Get(Item."Routing No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");

        // Set Scrap on Routing Line
        RoutingLine.SetRange("Routing No.", Item."Routing No.");
        RoutingLine.FindFirst();
        UpdateScrapOnRoutingLine(RoutingLine, ScrapFactor, FixedScrapQuantity);

        if MultipleRoutingLine then begin
            CreateWorkCenter(WorkCenter, false);
            UpdateFlushingMethodOnWorkCenter(WorkCenter, FlushingMethod); // The flushing method on work center will be copied to Prod. Order Routing Line
            CreateRoutingLineWithRoutingLink(RoutingLine, RoutingHeader, WorkCenter."No.");
            UpdateScrapOnRoutingLine(RoutingLine, LibraryRandom.RandDec(10, 2), LibraryRandom.RandInt(5));
        end;
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateAndInitNewProdOrderComponent(var NewProdOrderComponent: Record "Prod. Order Component"; var LastProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        FindLastProductionOrderCompLine(LastProdOrderComponent, ProdOrderLine);
        InitProdOrderComponent(NewProdOrderComponent, LastProdOrderComponent);
    end;

    local procedure CreateAddProdOrderLine(var NewProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        NewProdOrderLine.Status := ProdOrderLine.Status;
        NewProdOrderLine."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        NewProdOrderLine."Line No." := ProdOrderLine."Line No." + 10000;
        NewProdOrderLine.Validate("Item No.", ItemNo);
        NewProdOrderLine.Insert(true);
    end;

    local procedure CreateProdOrderLineWithDates(ProductionOrder: Record "Production Order"; StartingDate: Date; StartingTime: Time; DueDate: Date)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        LibraryManufacturing.CreateProdOrderLine(
            ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.",
            LibraryInventory.CreateItemNo(), '', '', LibraryRandom.RandInt(10));
        ProdOrderLine."Starting Date" := StartingDate;
        ProdOrderLine."Starting Time" := StartingTime;
        ProdOrderLine."Ending Date" := ProdOrderLine."Starting Date";
        ProdOrderLine."Ending Time" := ProdOrderLine."Starting Time";
        ProdOrderLine."Due Date" := DueDate;
        ProdOrderLine.UpdateDatetime();
        ProdOrderLine.Modify();
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

    local procedure CreateProdOrderAddNewComponentAndCreateConsumptionLine(var ProdOrderComponent: Record "Prod. Order Component"; CompLineQtyPer: Decimal)
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        ChildItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryWarehouse.CreateLocation(Location);
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(10));
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), Location.Code, '');

        CreateProdOrderComponent(ProductionOrder, ProdOrderComponent, CompLineQtyPer);
        CreateAndPostItemJournalLine(ProdOrderComponent."Item No.", LibraryRandom.RandIntInRange(10, 100), '', '');

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name, ItemJournalLine."Entry Type"::Consumption,
          ProdOrderComponent."Item No.", LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateProdOrderAddNewComponentAndCreateConsumptionLineWithDifferentUOM(var ProdOrderComponent: Record "Prod. Order Component"; CompLineQtyPer: Decimal)
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        ChildItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        QuantityPer: Decimal;
    begin
        QuantityPer := 0.005;
        LibraryWarehouse.CreateLocation(Location);
        CreateItemsSetup(Item, ChildItem, LibraryRandom.RandInt(10));
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandInt(10), Location.Code, '');

        CreateProdOrderComponent(ProductionOrder, ProdOrderComponent, CompLineQtyPer);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ProdOrderComponent."Item No.", QuantityPer);
        ProdOrderComponent.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProdOrderComponent.Modify();
        CreateAndPostItemJournalLine(ProdOrderComponent."Item No.", LibraryRandom.RandIntInRange(10, 100), '', '');

        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name, ItemJournalLine."Entry Type"::Consumption,
          ProdOrderComponent."Item No.", LibraryRandom.RandInt(10));
        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateFinishedProdOrder(ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        FindReleasedProdOrderLine(ProdOrderLine, ItemNo);
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        exit(ProductionOrder."No.");
    end;

    local procedure DeleteReservationEntry(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.DeleteAll(true);
    end;

    local procedure EnqueueVariablesForItemAvailByBOMPage(ChildItemNo: Code[20]; AbleToMakeParentQty: Decimal; AbleToMakeTopItemQty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ChildItemNo);
        LibraryVariableStorage.Enqueue(AbleToMakeParentQty);
        LibraryVariableStorage.Enqueue(AbleToMakeTopItemQty);
    end;

    local procedure UpdateComponentsInventory(ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        CreateAndPostItemJournalLine(ItemNo, Quantity, LocationCode, BinCode);
        CreateAndPostItemJournalLine(ItemNo2, Quantity, LocationCode, BinCode);
    end;

    local procedure OpenProductionJournalPage(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; EntryType: Enum "Item Ledger Document Type")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Enqueue values for use in ProductionJournalPageHandler.
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(EntryType);
        FindReleasedProdOrderLine(ProdOrderLine, ItemNo2);
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
    end;

    local procedure FindFirmPlannedProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::"Firm Planned");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure FindPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptNo(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
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
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();

        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
        exit(PurchRcptLine."Document No.");
    end;

    local procedure FindProductionOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrderNo: Code[20])
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure FindLastProductionOrderCompLine(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.FindLast();
    end;

    local procedure FindReleasedProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, ActivityType);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindRegisteredWhseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; ActivityType: Enum "Warehouse Activity Type")
    begin
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationCode, SourceNo, ActionType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type"::"Invt. Pick", WarehouseActivityLine."No.");
    end;

    local procedure FindAndRegisterWhseActivity(LocationCode: Code[10]; ProdOrderNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, ProdOrderNo, "Warehouse Action Type"::" ");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindLastRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20])
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindLast();
    end;

    local procedure FindFirstRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20])
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindFirst();
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure FindProdOrderRoutingLineWithSpecifiedOperationNo(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ItemNo: Code[20]; OperationNo: Code[10])
    begin
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ItemNo);
    end;

    local procedure FindProdOrderCapacityNeed(var ProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        ProdOrderCapacityNeed.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderCapacityNeed.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderCapacityNeed.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderCapacityNeed.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        ProdOrderCapacityNeed.SetRange("Time Type", ProdOrderCapacityNeed."Time Type"::"Run Time");
        ProdOrderCapacityNeed.FindFirst();
    end;

    local procedure FindProdBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMHeaderNo: Code[20]; ItemNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeaderNo);
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", ItemNo);
        ProductionBOMLine.FindFirst();
    end;

    local procedure FinishProdOrderWhenBackFlushingConsumptionAndManualFlushingOutputWithScrap(Verification: Option VerifyErr,VerifyItemLedgerEntry)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        ItemJournalLine: Record "Item Journal Line";
        ChildItemNo: Code[20];
        Quantity: Decimal;
        QtyPer: Decimal;
        FixedScrapQuantity: Decimal;
    begin
        // Setup: Create a Product Item for Manual Flushing and scrap Routing
        // Create Child Item for Backward Flushing and Lot Tracking
        Initialize();
        Quantity := LibraryRandom.RandInt(100);
        QtyPer := 0.01 * LibraryRandom.RandInt(99); // Qty per need less than 1
        FixedScrapQuantity := LibraryRandom.RandInt(10);
        CreateProdItemWithScrapAndFlushingMethod(
          Item, ChildItemNo, WorkCenter."Flushing Method"::Manual, QtyPer, false, 0, FixedScrapQuantity, true);

        // Update Inventory for Component Item
        CreateAndPostItemJournalLineWithTracking(ChildItemNo, Quantity); // Invoke ItemTrackingHandlerWithoutApplyToItemEntry

        // Create and Refresh Production Order and Assign Lot Item Tracking for Component Item
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Quantity, '', '');
        SelectItemTrackingForProdOrderComponents(ChildItemNo); // Invoke ItemTrackingHandlerWithoutApplyToItemEntry

        // Open Production Journal Page, update Output Quantity and Post Production Journal on PostProductionJournalHandlerWithUpdateQuantity
        OpenProductionJournalPage(ProductionOrder, Item."No.", Item."No.", Quantity, ItemJournalLine."Entry Type"::Output);

        case Verification of
            Verification::VerifyErr:
                begin
                    // Exercise: Change Status to Finished
                    // Verify: Error message pops up and error info is correct.
                    asserterror LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
                    Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(QtyToHandleBaseInTrackingErr, Quantity * QtyPer)) > 0, GetLastErrorText);
                end;
            Verification::VerifyItemLedgerEntry:
                begin
                    // Update Quantity (Base) in Item Tracking for Prod. Order Components.
                    // Exercise: Change Status to Finished
                    UpdateQuantityBaseInTrackingForProdOrderComponents(ChildItemNo, Quantity * QtyPer); // Invoke ItemTrackingHandlerWithoutApplyToItemEntry
                    LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

                    // Verify:  There is no error pops up when change status
                    // Verify Item Ledger Entries are correct for Consumption and Output Quantity
                    VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Consumption, ChildItemNo, -Quantity * QtyPer, '');
                    VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, Item."No.", Quantity, '');
                end;
        end;
    end;

    local procedure FilterValueEntry(var ValueEntry: Record "Value Entry"; DocumentNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Document Type")
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Document No.", DocumentNo);
    end;

    local procedure MockItemLedgerEntryForConsumption(var ProdOrderComponent: Record "Prod. Order Component")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        RecRef: RecordRef;
    begin
        ItemLedgerEntry.Init();
        RecRef.GetTable(ItemLedgerEntry);
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Consumption;
        ItemLedgerEntry."Order Type" := ItemLedgerEntry."Order Type"::Production;
        ItemLedgerEntry."Order No." := ProdOrderComponent."Prod. Order No.";
        ItemLedgerEntry."Prod. Order Comp. Line No." := ProdOrderComponent."Line No.";
        ItemLedgerEntry.Quantity := LibraryRandom.RandInt(10);
        ItemLedgerEntry.Insert();
    end;

    local procedure MockProductionOrder(var ProductionOrder: Record "Production Order"; ProdOrderStatus: Enum "Production Order Status")
    begin
        ProductionOrder.Init();
        ProductionOrder.Status := ProdOrderStatus;
        ProductionOrder."No." := LibraryUtility.GenerateGUID();
        ProductionOrder."Starting Date-Time" := CreateDateTime(WorkDate(), 120000T);
        ProductionOrder."Ending Date-Time" := CreateDateTime(WorkDate() + 30, 120000T);
        ProductionOrder.Insert();
    end;

    local procedure MockProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component")
    begin
        ProdOrderComponent.Init();
        ProdOrderComponent.Status := ProdOrderComponent.Status::Released;
        ProdOrderComponent."Prod. Order No." := LibraryUtility.GenerateGUID();
        ProdOrderComponent."Line No." := LibraryRandom.RandInt(10);
        ProdOrderComponent."Item No." := LibraryUtility.GenerateGUID();
        ProdOrderComponent."Qty. per Unit of Measure" := LibraryRandom.RandInt(10);
        ProdOrderComponent.Insert();

        ProdOrderComponent.BlockDynamicTracking(true); // prevents calling of VerifyQuantity function
    end;

    local procedure OpenItemTrackingLines(var ItemJournalLine: Record "Item Journal Line"; TrackingMode: Option)
    begin
        LibraryVariableStorage.Enqueue(TrackingMode);

        if TrackingMode = ItemTrackingMode::SelectEntries then
            LibraryVariableStorage.Enqueue(false);

        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure OpenItemTrackingLinesSelectAndApply(var ItemJournalLine: Record "Item Journal Line"; ApplyToEntryNo: Integer)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(ApplyToEntryNo);
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure OpenItemTrackingLinesSetValue(var ItemJournalLine: Record "Item Journal Line"; LotNo: Code[50]; SerialNo: Code[50]; Quantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SetValue);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure OpenReleasedProductionOrderStatisticsPage(var ProductionOrderStatistics: TestPage "Production Order Statistics"; ProductionOrderNo: Code[20])
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", ProductionOrderNo);
        ProductionOrderStatistics.Trap();
        ReleasedProductionOrder.Statistics.Invoke();
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; Type: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, Type);
        WarehouseActivityHeader.Get(Type, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RunItemAvailByBOMLevelPage(var Item: Record Item)
    var
        ItemAvailabilityByBOMLevel: Page "Item Availability by BOM Level";
    begin
        ItemAvailabilityByBOMLevel.InitItem(Item);
        ItemAvailabilityByBOMLevel.Run();
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure SelectSalesOrderLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.FindFirst();
    end;

    local procedure SelectItemTrackingForProdOrderComponents(ItemNo: Code[20])
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponents.OpenEdit();
        ProdOrderComponents.FILTER.SetFilter("Item No.", ItemNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        LibraryVariableStorage.Enqueue(false);

        ProdOrderComponents.ItemTrackingLines.Invoke();
    end;

    local procedure UpdateBlanketOrderNoAndLocationOnSalesLine(var SalesLine: Record "Sales Line"; SalesLineBlanket: Record "Sales Line"; LocationCode: Code[10])
    begin
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Blanket Order No.", SalesLineBlanket."Document No.");
        SalesLine."Blanket Order Line No." := SalesLineBlanket."Line No.";
        SalesLine.Modify(true);
    end;

    local procedure UpdateManufacturingSetupComponentsAtLocation(NewComponentsAtLocation: Code[10]) ComponentsAtLocation: Code[10]
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ComponentsAtLocation := ManufacturingSetup."Components at Location";
        ManufacturingSetup.Validate("Components at Location", NewComponentsAtLocation);
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateOrderTrackingPolicyOnItem(var Item: Record Item; OrderTrackingPolicy: Enum "Order Tracking Policy")
    begin
        LibraryVariableStorage.Enqueue(TrackingMsg);  // Enqueue variable for use in MessageHandler.
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
    end;

    local procedure UpdateItemParametersForPlanning(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy")
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(var OldStockoutWarning: Boolean; var OldCreditWarnings: Option; NewStockoutWarning: Boolean; NewCreditWarnings: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldStockoutWarning := SalesReceivablesSetup."Stockout Warning";
        OldCreditWarnings := SalesReceivablesSetup."Credit Warnings";
        SalesReceivablesSetup.Validate("Stockout Warning", NewStockoutWarning);
        SalesReceivablesSetup.Validate("Credit Warnings", NewCreditWarnings);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateLocationSetup(var Location: Record Location; NewAlwaysCreatePickLine: Boolean) AlwaysCreatePickLine: Boolean
    begin
        AlwaysCreatePickLine := Location."Always Create Pick Line";
        Location.Validate("Always Create Pick Line", NewAlwaysCreatePickLine);
        Location.Modify(true);
    end;

    local procedure UpdateInventoryWithWhseItemJournal(var Item: Record Item; Location: Record Location; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Create and register the Warehouse Item Journal Line.
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        CreateWarehouseJournalLine(Item, WarehouseJournalLine, Location, Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);

        // Calculate Warehouse adjustment and post Item Journal.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        CalculateWhseAdjustmentAndPostCreatedItemJournalLine(Item, ItemJournalBatch);
    end;

    local procedure UpdateQuantityOnWarehouseActivityLine(SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; Quantity: Decimal; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", LocationCode, SourceNo, ActionType);
        WarehouseActivityLine.Validate(Quantity, Quantity);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateFlushingMethodOnItem(var Item: Record Item; FlushingMethod: Enum "Flushing Method")
    begin
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
    end;

    local procedure UpdateFlushingMethodOnProdOrderRoutingLine(ProductionOrder: Record "Production Order")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.Validate("Flushing Method", ProdOrderRoutingLine."Flushing Method"::Backward);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure UpdateProdBOMVersionCodeOnProdOrderLine(Item: Record Item)
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMVersion.FindFirst();
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");
        ProdOrderLine.Validate("Production BOM Version Code", ProductionBOMVersion."Version Code");
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateItemFlushingMethodPickAndBackward(var Item: Record Item)
    begin
        Item.Validate("Flushing Method", Item."Flushing Method"::"Pick + Backward");
        Item.Modify(true);
    end;

    local procedure UpdateItemForLotTrackingAndFlushingMethod(var Item: Record Item; FlushingMethod: Enum "Flushing Method")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        Item.Validate("Item Tracking Code", CreateItemTrackingCode());
        Item.Validate("Lot Nos.", LibraryERM.CreateNoSeriesCode());
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Validate("Rounding Precision", GeneralLedgerSetup."Amount Rounding Precision");
        Item.Modify(true);
    end;

    local procedure UpdateItemManufacturingProperties(var Item: Record Item; ProdBOMNo: Code[20]; RoutingNo: Code[20])
    begin
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Production BOM No.", ProdBOMNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure UpdateSKUManufacturingProperties(var StockkeepingUnit: Record "Stockkeeping Unit"; ProdBOMNo: Code[20]; RoutingNo: Code[20])
    begin
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::"Prod. Order");
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::"Lot-for-Lot");
        StockkeepingUnit.Validate("Production BOM No.", ProdBOMNo);
        StockkeepingUnit.Validate("Routing No.", RoutingNo);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateInventorySetup(var InventorySetup: Record "Inventory Setup")
    var
        InventorySetup2: Record "Inventory Setup";
    begin
        // Enqueue values for use in MessageHandler.
        LibraryVariableStorage.Enqueue(ChangeExpectedCostPostingToGLMsg);
        LibraryVariableStorage.Enqueue(ExpectedCostPostingChangedMsg);
        LibraryVariableStorage.Enqueue(UnadjustedValueEntriesNotCoveredMsg);
        InventorySetup.Get();  // To maintain the original state of setup.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup2, true, true, InventorySetup2."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");  // Update few parameters to effect restore.
    end;

    local procedure UpdateItemOverheadRate(var Item: Record Item)
    begin
        Item.Validate("Overhead Rate", LibraryRandom.RandInt(5));
        Item.Modify(true);
    end;

    local procedure UpdateItemInventoryForLocation(Item: Record Item; Location: Record Location; Quantity: Decimal)
    var
        Bin: Record Bin;
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        Zone: Record Zone;
    begin
        SelectItemJournalBatch(ItemJournalBatch);
        Bin.Get(Location.Code, Location."Open Shop Floor Bin Code");
        Zone.Get(Location.Code, Bin."Zone Code");
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, Zone.Code,
          Location."Open Shop Floor Bin Code", WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);
        CalculateWhseAdjustmentAndPostCreatedItemJournalLine(Item, ItemJournalBatch);
    end;

    local procedure UpdateLocationAndBins(var Location: Record Location)
    var
        Bin2: Record Bin;
        Bin3: Record Bin;
    begin
        LibraryWarehouse.FindBin(Bin2, Location.Code, '', 2); // Find Bin of Index 2.
        LibraryWarehouse.FindBin(Bin3, Location.Code, '', 3);
        // Find Bin of Index 3.
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Put-away", false);
        Location.Validate("To-Production Bin Code", Bin2.Code);
        Location.Validate("From-Production Bin Code", Bin3.Code);
        if Location."Require Pick" then
            if Location."Require Shipment" then
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)"
            else
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";

        if Location."Require Put-away" then
            Location."Prod. Output Whse. Handling" := Location."Prod. Output Whse. Handling"::"Inventory Put-away";
        Location.Modify(true);
    end;

    local procedure UpdateBOMHeader(ProductionBOMNo: Code[20]; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Update Routing link Code on specified BOM component Lines.
        ProductionBOMHeader.SetRange("No.", ProductionBOMNo);
        ProductionBOMHeader.FindFirst();
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMHeader.Modify(true);
        UpdateBOMLineRoutingLinkCode(ProductionBOMNo, ItemNo, RoutingLinkCode);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateBOMLineRoutingLinkCode(ProductionBOMHeaderNo: Code[20]; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        FindProdBOMLine(ProductionBOMLine, ProductionBOMHeaderNo, ItemNo);
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
    end;

    local procedure UpdateBOMHeaderWithLineUOM(ProductionBOMNo: Code[20]; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Update Unit of Measure Code on specified BOM component Line.
        ProductionBOMHeader.SetRange("No.", ProductionBOMNo);
        ProductionBOMHeader.FindFirst();
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMHeader.Modify(true);
        UpdateBOMLineUOM(ProductionBOMNo, ItemNo, UnitOfMeasureCode);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateBOMLineUOM(ProductionBOMHeaderNo: Code[20]; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        FindProdBOMLine(ProductionBOMLine, ProductionBOMHeaderNo, ItemNo);
        ProductionBOMLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProductionBOMLine.Modify(true);
    end;

    local procedure UpdateLocationOnSalesLine(DocumentNo: Code[20]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SelectSalesOrderLine(SalesLine, DocumentNo);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVariantCodeInProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; ItemVariantCode: Code[10])
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Variant Code", ItemVariantCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateQuantityBaseInTrackingForProdOrderComponents(ItemNo: Code[20]; Qty: Decimal)
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponents.OpenEdit();
        ProdOrderComponents.FILTER.SetFilter("Item No.", ItemNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::UpdateQuantityBase);
        LibraryVariableStorage.Enqueue(Qty);

        ProdOrderComponents.ItemTrackingLines.Invoke();
    end;

    local procedure UpdateScrapOnRoutingLine(var RoutingLine: Record "Routing Line"; ScrapFactor: Decimal; FixedScrapQuantity: Decimal)
    begin
        RoutingLine.Validate("Scrap Factor %", ScrapFactor);
        RoutingLine.Validate("Fixed Scrap Quantity", FixedScrapQuantity);
        RoutingLine.Modify(true);
    end;

    local procedure UpdateFlushingMethodOnWorkCenter(var WorkCenter: Record "Work Center"; FlushingMethod: Enum "Flushing Method")
    begin
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Modify(true);
    end;

    local procedure UpdateProdOrderLineUnitOfMeasureCode(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        FindReleasedProdOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProdOrderLine.Modify(true);
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

    local procedure InitProdOrderComponent(var NewProdOrderComponent: Record "Prod. Order Component"; OldProdOrderComponent: Record "Prod. Order Component")
    begin
        NewProdOrderComponent.Init();
        NewProdOrderComponent.Status := OldProdOrderComponent.Status;
        NewProdOrderComponent."Prod. Order No." := OldProdOrderComponent."Prod. Order No.";
        NewProdOrderComponent."Prod. Order Line No." := OldProdOrderComponent."Prod. Order Line No.";
        NewProdOrderComponent."Line No." := OldProdOrderComponent."Line No." + 10000;
        NewProdOrderComponent.Validate("Item No.", OldProdOrderComponent."Item No.");
        NewProdOrderComponent.Validate("Location Code", OldProdOrderComponent."Location Code");
    end;

    local procedure VerifyValueEntryForEntryType(EntryType: Enum "Cost Entry Type"; DocumentNo: Code[20]; ItemLedgerEntryQuantity: Decimal; CostPostedToGL: Decimal; InvoicedQuantity: Decimal; CostPerUnit: Decimal; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntry(ValueEntry, DocumentNo, ValueEntry."Item Ledger Entry Type"::Output);
        ValueEntry.SetRange("Entry Type", EntryType);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Item Ledger Entry Quantity", ItemLedgerEntryQuantity);
        ValueEntry.TestField("Cost Posted to G/L", CostPostedToGL);
        ValueEntry.TestField("Invoiced Quantity", InvoicedQuantity);
        ValueEntry.TestField("Cost per Unit", CostPerUnit);
        ValueEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    local procedure VerifyUOMOnWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Integer)
    begin
        WarehouseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseActivityLine.TestField("Qty. per Unit of Measure", QtyPerUnitOfMeasure);
    end;

    local procedure VerifyProdOrderLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; DueDate: Date)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindFirmPlannedProdOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField("Location Code", LocationCode);
        ProdOrderLine.TestField(Quantity, Quantity);
        ProdOrderLine.TestField("Due Date", DueDate);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Location Code", LocationCode)
    end;

    local procedure VerifyWarehouseEntry(EntryType: Option; SourceNo: Code[20]; ItemNo: Code[20]; BinCode: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Source No.", SourceNo);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Location Code", LocationCode);
        WarehouseEntry.TestField("Bin Code", BinCode);
        WarehouseEntry.TestField(Quantity, Qty);
    end;

    local procedure VerifyOrderTrackingForProductionOrder(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        OrderTracking: Page "Order Tracking";
        OrderTracking2: TestPage "Order Tracking";
    begin
        FindFirmPlannedProdOrderLine(ProdOrderLine, ItemNo);
        OrderTracking.SetVariantRec(
            ProdOrderLine, ProdOrderLine."Item No.", ProdOrderLine."Remaining Qty. (Base)",
            ProdOrderLine."Starting Date", ProdOrderLine."Ending Date");
        OrderTracking2.Trap();
        OrderTracking.Run();
        repeat
            OrderTracking2."Item No.".AssertEquals(ItemNo);
            OrderTracking2.Quantity.AssertEquals(Quantity);
        until not OrderTracking2.Next();
    end;

    local procedure VerifyPlanningComponentBin(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.SetRange("Item No.", ItemNo);
        PlanningComponent.FindFirst();
        PlanningComponent.TestField("Location Code", LocationCode);
        PlanningComponent.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyProdOrderLineBinCode(ItemNo: Code[20]; WorkCenterBinCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        Assert.AreEqual(WorkCenterBinCode, ProdOrderLine."Bin Code", ProdOrderLineBinCodeErr);
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

    local procedure VerifyRecreatedPurchaseLine(PurchaseLine: Record "Purchase Line"; VATBusPostingGroupCode: Code[20])
    var
        RecreatedPurchaseLine: Record "Purchase Line";
    begin
        RecreatedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        RecreatedPurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
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

    local procedure VerifyRequisitionLine(No: Code[20]; ActionMessage: Enum "Action Message Type"; Quantity: Decimal; DueDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, No);
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Action Message", ActionMessage);
        RequisitionLine.TestField("Due Date", DueDate);
    end;

    local procedure VerifyRequisitionLineWithLocation(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ActionMessage: Enum "Action Message Type")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Action Message", ActionMessage);
        RequisitionLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyCostAmountActualOnFinishedProductionOrderStatisticsPage(ProductionOrderNo: Code[20]; ActualCost: Decimal)
    var
        FinishedProductionOrder: TestPage "Finished Production Order";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
    begin
        FinishedProductionOrder.OpenEdit();
        FinishedProductionOrder.FILTER.SetFilter("No.", ProductionOrderNo);
        ProductionOrderStatistics.Trap();
        FinishedProductionOrder.Statistics.Invoke();
        ProductionOrderStatistics.MaterialCost_ActualCost.AssertEquals(ActualCost);
    end;

    local procedure VerifyTotalActualCostOnFinishedProductionOrderStatisticsPage(ProductionOrderNo: Code[20]; ActualCost: Decimal)
    var
        FinishedProductionOrder: TestPage "Finished Production Order";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
    begin
        FinishedProductionOrder.OpenEdit();
        FinishedProductionOrder.FILTER.SetFilter("No.", ProductionOrderNo);
        ProductionOrderStatistics.Trap();
        FinishedProductionOrder.Statistics.Invoke();
        ProductionOrderStatistics.TotalCost_ActualCost.AssertEquals(ActualCost);
    end;

    local procedure VerifyCostAmountActualOnReleasedProductionOrderStatisticsPage(ProductionOrderNo: Code[20]; ActualCost: Decimal)
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
    begin
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", ProductionOrderNo);
        ProductionOrderStatistics.Trap();
        ReleasedProductionOrder.Statistics.Invoke();
        ProductionOrderStatistics.MaterialCost_ActualCost.AssertEquals(ActualCost);
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

    local procedure VerifyRegisteredWhseActivityLine(RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; UnitOfMeasureCode: Code[10]; QtyPerUnitOfMeasure: Integer; Quantity: Decimal)
    begin
        RegisteredWhseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        RegisteredWhseActivityLine.TestField("Qty. per Unit of Measure", QtyPerUnitOfMeasure);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyFinishedProdOrderLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Finished);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.TestField(Quantity, Quantity);
        ProdOrderLine.TestField("Finished Quantity", Quantity);
    end;

    local procedure VerifyPostedInventoryPickLine(SourceNo: Code[20]; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.SetRange("Item No.", ItemNo);
        PostedInvtPickLine.FindSet();
        repeat
            PostedInvtPickLine.TestField("Bin Code", BinCode);
            PostedInvtPickLine.TestField(Quantity, Quantity);
            PostedInvtPickLine.TestField("Location Code", LocationCode);
        until PostedInvtPickLine.Next() = 0;
    end;

    local procedure VerifyWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, Quantity);
        WarehouseActivityLine.TestField("Qty. (Base)", Quantity);
    end;

    local procedure VerifyValueEntry(ItemNo: Code[20]; DocumentNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Document Type"; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntry(ValueEntry, DocumentNo, ItemLedgerEntryType);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Actual)", CostAmountActual);
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

    local procedure VerifyProdOrderComponent(ProdOrderNo: Code[20]; Status: Enum "Production Order Status"; ItemNo: Code[20]; QtyPicked: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.TestField(Status, Status);
        ProdOrderComponent.TestField("Qty. Picked", QtyPicked);
        ProdOrderComponent.TestField("Qty. Picked (Base)", QtyPicked);
    end;

    local procedure VerifyProductionOrderIsEmpty(ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.SetRange("No.", ProductionOrderNo);
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        Assert.RecordIsEmpty(ProductionOrder);
    end;

    local procedure VerifyOutputItemLedgerEntry(ItemNo: Code[20]; Location: Code[10]; Qty: Decimal; Qty2: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
        ItemLedgerEntry.TestField(Quantity, Qty);
        ItemLedgerEntry.TestField("Location Code", Location);
        ItemLedgerEntry.Next();
        ItemLedgerEntry.TestField(Quantity, Qty2);
        ItemLedgerEntry.TestField("Location Code", Location);
    end;

    local procedure VerifyReversedOutputItemLedgerEntry(ItemNo: Code[20])
    var
        PositiveItemLedgerEntry: Record "Item Ledger Entry";
        NegativeItemLedgerEntry: Record "Item Ledger Entry";
    begin
        PositiveItemLedgerEntry.SetRange(Positive, true);
        FindItemLedgerEntry(PositiveItemLedgerEntry, PositiveItemLedgerEntry."Entry Type"::Output, ItemNo);

        NegativeItemLedgerEntry.SetRange(Positive, false);
        FindItemLedgerEntry(NegativeItemLedgerEntry, NegativeItemLedgerEntry."Entry Type"::Output, ItemNo);
        NegativeItemLedgerEntry.TestField("Applies-to Entry", PositiveItemLedgerEntry."Entry No.");
        NegativeItemLedgerEntry.TestField("Lot No.", PositiveItemLedgerEntry."Lot No.");
        NegativeItemLedgerEntry.TestField("Serial No.", PositiveItemLedgerEntry."Serial No.");
    end;

    local procedure VerifyBinCodeInProductionOrderLine(ItemNo: Code[20]; BinCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindFirmPlannedProdOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyItemAvailabilityByBOMPage(var ItemAvailByBOMLevel: TestPage "Item Availability by BOM Level")
    var
        ChildItemNo: Variant;
        AbleToMakeParentQty: Variant;
        AbleToMakeTopItemQty: Variant;
    begin
        LibraryVariableStorage.Dequeue(ChildItemNo);
        LibraryVariableStorage.Dequeue(AbleToMakeParentQty);
        LibraryVariableStorage.Dequeue(AbleToMakeTopItemQty);

        ItemAvailByBOMLevel."No.".AssertEquals(ChildItemNo);
        ItemAvailByBOMLevel."Able to Make Parent".AssertEquals(AbleToMakeParentQty);
        ItemAvailByBOMLevel."Able to Make Top Item".AssertEquals(AbleToMakeTopItemQty);
    end;

    local procedure VerifyWhseRequestExist(DocumentNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Source Type", DATABASE::"Prod. Order Component");
        WarehouseRequest.SetRange("Source Subtype", 3); // Released
        WarehouseRequest.SetRange("Source No.", DocumentNo);
        WarehouseRequest.SetRange("Location Code", LocationCode);
        Assert.RecordIsNotEmpty(WarehouseRequest);
    end;

    local procedure VerifyWhsePickRequestExist(DocumentNo: Code[20]; LocationCode: Code[10])
    var
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Production);
        WhsePickRequest.SetRange("Document Subtype", 3); // Released
        WhsePickRequest.SetRange("Document No.", DocumentNo);
        WhsePickRequest.SetRange("Location Code", LocationCode);
        Assert.RecordIsNotEmpty(WhsePickRequest);
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
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

    local procedure CreateProdOrderComponentForUoMTest(
        var ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
        Item: Record Item;
        UoM: Record "Unit of Measure")
    begin
        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComponent,
                                                            ProdOrderComponent.Status::Released,
                                                            ProductionOrder."No.",
                                                            ProductionOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", Item."No.");
        ProdOrderComponent.Validate("Unit of Measure Code", UoM.Code);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateAndPostItemJournal(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item Journal to populate Item Quantity.
        ClearJournal(ItemJournalBatch);  // Clear Item Journal Template and Journal Batch.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
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

    local procedure CreateRoutingLineWithWorkCenter(RoutingHeader: Record "Routing Header"; WorkCenter: Record "Work Center"; OperationNo: Code[10]; SetupTime: Integer; RunTime: Integer)
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Modify(true);
    end;

    local procedure VerifyProdOrderCapacity(ProductionOrder: Record "Production Order"; WorkCenter: Record "Work Center"; NoOfRecords: Integer)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.Reset();
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderCapacityNeed.SetRange("Work Center No.", WorkCenter."No.");
        Assert.RecordCount(ProdOrderCapacityNeed, NoOfRecords);
    end;

    local procedure FindLastItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; InventoryOrderType: Enum "Inventory Order Type"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; ItemLedgerEntryType: Enum "Item Ledger Entry Type")
    begin
        ItemLedgerEntry.SetRange("Order Type", InventoryOrderType);
        ItemLedgerEntry.SetRange("Order No.", ProdOrderNo);
        ItemLedgerEntry.SetRange("Order Line No.", ProdOrderLineNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntryType);
        ItemLedgerEntry.FindLast();
    end;

    local procedure FindLastCapacityLedgerEntry(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; InventoryOrderType: Enum "Inventory Order Type"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer)
    begin
        CapacityLedgerEntry.SetRange("Order Type", InventoryOrderType);
        CapacityLedgerEntry.SetRange("Order No.", ProdOrderNo);
        CapacityLedgerEntry.SetRange("Order Line No.", ProdOrderLineNo);
        CapacityLedgerEntry.FindLast();
    end;

    local procedure CreateItemWithLotTracking(Var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItem(Item);

        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
    end;

    local procedure CreateSalesOrderOnManufacturingLocation(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]): Decimal;
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(
            SalesHeader,
            SalesHeader."Document Type"::Order,
            LibrarySales.CreateCustomerNo());

        SalesHeader.Validate("Shipment Date", Today);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::Item,
            ItemNo,
            Quantity);
        UpdateLocationOnSalesLine(SalesLine."Document No.", LocationCode);

        exit(SalesLine.Quantity);
    end;

    local procedure CreateProdOrderOnManufacturingLocation(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Planned,
            ProductionOrder."Source Type"::Item,
            ItemNo,
            Quantity);

        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Due Date", Today);
        ProductionOrder.Modify(true);
    end;

    local procedure OpenItemTrackingLinesSetValueInProdOrderLine(LotNo: Code[50]; SerialNo: Code[50]; Quantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SetValue);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(Quantity);
    end;

    local procedure CreateProductionItemWithNonInvItemAndProductionBOM(var ProdItem: Record Item; var NonInvItem: Record Item; var ProductionBOMHeader: Record "Production BOM Header")
    begin
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, NonInvItem."No.", LibraryRandom.RandIntInRange(1, 1));
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify();
    end;

    local procedure CreateProductionItemWithNonInvItemAndProductionBOM(var ProdItem: Record Item; var NonInvItem: Record Item; var CompItem: Record Item; var ProductionBOMHeader: Record "Production BOM Header")
    begin
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, NonInvItem."No.", CompItem."No.", LibraryRandom.RandIntInRange(1, 1));
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify();
    end;

    local procedure CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem: Record Item; Quantity: Decimal; UnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorNo(), NonInvItem."No.", Quantity, '', WorkDate());

        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify();

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure FilterValueEntryWithItemLedgerEntryType(var ValueEntry: Record "Value Entry"; ProdOrderNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; EntryType: Enum "Cost Entry Type"; ItemNo: Code[20]; ItemLedgerEntryQuantity: Decimal)
    begin
        ValueEntry.SetRange("Document No.", ProdOrderNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Entry Type", EntryType);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Quantity", ItemLedgerEntryQuantity);
        ValueEntry.FindFirst();
    end;

    local procedure FilterItemLedgerEntryWithItemLedgerEntryType(var ItemLedgerEntry: Record "Item Ledger Entry"; ProdOrderNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Document No.", ProdOrderNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure VerifyCostAmountNonInventoryForValueEntry(ProductionOrder: Record "Production Order"; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; CostEntryType: Enum "Cost Entry Type"; Item: Record Item; Quantity: Decimal; CostAmountNonInv: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", ItemLedgerEntryType, CostEntryType, Item."No.", Quantity);
        Assert.AreEqual(
            CostAmountNonInv,
            ValueEntry."Cost Amount (Non-Invtbl.)",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Amount (Non-Invtbl.)"), CostAmountNonInv, ValueEntry."Entry No.", ValueEntry.TableCaption()));
    end;

    local procedure VerifyCostAmountExpectedAndActualForValueEntry(ProductionOrder: Record "Production Order"; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; CostEntryType: Enum "Cost Entry Type"; Item: Record Item; Quantity: Decimal; CostAmountExpected: Decimal; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        if CostEntryType = CostEntryType::Variance then
            ValueEntry.SetRange("Variance Type", ValueEntry."Variance Type"::"Material - Non Inventory");

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", ItemLedgerEntryType, CostEntryType, Item."No.", Quantity);
        Assert.AreEqual(
            CostAmountExpected,
            ValueEntry."Cost Amount (Expected)",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Amount (Expected)"), CostAmountExpected, ValueEntry."Entry No.", ValueEntry.TableCaption()));
        Assert.AreEqual(
            CostAmountActual,
            ValueEntry."Cost Amount (Actual)",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual, ValueEntry."Entry No.", ValueEntry.TableCaption()));
    end;

    local procedure VerifyCostAmountExpectedAndActualForItemLedgerEntry(ProductionOrder: Record "Production Order"; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; Item: Record Item; CostAmountExpected: Decimal; CostAmountActual: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FilterItemLedgerEntryWithItemLedgerEntryType(ItemLedgerEntry, ProductionOrder."No.", ItemLedgerEntryType, Item."No.");
        ItemLedgerEntry.CalcFields("Cost Amount (Expected)", "Cost Amount (Actual)");
        Assert.AreEqual(
            CostAmountExpected,
            ItemLedgerEntry."Cost Amount (Expected)",
            StrSubstNo(EntryMustBeEqualErr, ItemLedgerEntry.FieldCaption("Cost Amount (Expected)"), CostAmountExpected, ItemLedgerEntry."Entry No.", ItemLedgerEntry.TableCaption()));
        Assert.AreEqual(
            CostAmountActual,
            ItemLedgerEntry."Cost Amount (Actual)",
            StrSubstNo(EntryMustBeEqualErr, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual, ItemLedgerEntry."Entry No.", ItemLedgerEntry.TableCaption()));
    end;

    local procedure VerifyGLEntriesForNonInventoryAppliedAccount(ProductionOrder: Record "Production Order"; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; CostEntryType: Enum "Cost Entry Type"; Item: Record Item; ExpectedValue: Decimal)
    var
        TempGLEntry: Record "G/L Entry" temporary;
        GenPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", ItemLedgerEntryType, CostEntryType, Item."No.", 0);
        GetRelatedGLEntriesFromValueEntry(TempGLEntry, ValueEntry);
        Assert.RecordCount(TempGLEntry, 2);

        GenPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        InventoryPostingSetup.Get(ValueEntry."Location Code", ValueEntry."Inventory Posting Group");
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, GenPostingSetup."Direct Cost Non-Inv. App. Acc.", -ExpectedValue);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."Inventory Account", ExpectedValue);
    end;

    local procedure VerifyGLEntriesForNonInventoryVarianceAccount(ProductionOrder: Record "Production Order"; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; CostEntryType: Enum "Cost Entry Type"; Item: Record Item; ExpectedValue: Decimal)
    var
        TempGLEntry: Record "G/L Entry" temporary;
        GenPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", ItemLedgerEntryType, CostEntryType, Item."No.", 0);
        GetRelatedGLEntriesFromValueEntry(TempGLEntry, ValueEntry);
        Assert.RecordCount(TempGLEntry, 2);

        GenPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        InventoryPostingSetup.Get(ValueEntry."Location Code", ValueEntry."Inventory Posting Group");
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."Mat. Non-Inv. Variance Acc.", -ExpectedValue);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."Inventory Account", ExpectedValue);
    end;

    local procedure GetRelatedGLEntriesFromValueEntry(var TempGLEntry: Record "G/L Entry" temporary; ValueEntry: Record "Value Entry")
    var
        GLEntry: Record "G/L Entry";
        GLItemLedgRelation: Record "G/L - Item Ledger Relation";
    begin
        GLItemLedgRelation.SetCurrentKey("Value Entry No.");
        GLItemLedgRelation.SetRange("Value Entry No.", ValueEntry."Entry No.");
        if GLItemLedgRelation.FindSet() then
            repeat
                GLEntry.Get(GLItemLedgRelation."G/L Entry No.");
                TempGLEntry.Init();
                TempGLEntry := GLEntry;
                TempGLEntry.Insert();
            until GLItemLedgRelation.Next() = 0;
    end;

    local procedure VerifyGLEntriesWithAccountNoAndExpectedAmount(var TempGLEntry: Record "G/L Entry" temporary; AccountNo: Code[20]; ExpectedAmount: Decimal)
    begin
        TempGLEntry.Reset();
        TempGLEntry.SetLoadFields("G/L Account No.", Amount);
        TempGLEntry.SetRange("G/L Account No.", AccountNo);
        TempGLEntry.FindFirst();
        TempGLEntry.CalcSums(Amount);

        Assert.AreEqual(
            AccountNo,
            TempGLEntry."G/L Account No.",
            StrSubstNo(ValueMustBeEqualErr, TempGLEntry.FieldCaption("G/L Account No."), AccountNo, TempGLEntry.TableCaption()));
        Assert.AreEqual(
            ExpectedAmount,
            TempGLEntry.Amount,
            StrSubstNo(EntryMustBeEqualErr, TempGLEntry.FieldCaption(Amount), ExpectedAmount, TempGLEntry."Entry No.", TempGLEntry.TableCaption()));
    end;

    local procedure ModifyLocation(Location: Record Location)
    begin
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");
        Location.Validate("Asm. Consump. Whse. Handling", Location."Asm. Consump. Whse. Handling"::"No Warehouse Handling");
        Location.Validate("Job Consump. Whse. Handling", Location."Job Consump. Whse. Handling"::"No Warehouse Handling");
        Location.Modify(true);
    end;

    local procedure VerifyCostFieldsInItem(Item: Record Item; StandardCost: Decimal; SLMatCost: Decimal; RUMatCost: Decimal; SLNonInvMatCost: Decimal; RUNonInvMatCost: Decimal; SLMfgOvhdCost: Decimal; RUMfgOvhdCost: Decimal)
    begin
        Assert.AreEqual(
            StandardCost,
            Item."Standard Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Standard Cost"), StandardCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            SLNonInvMatCost,
            Item."Single-Lvl Mat. Non-Invt. Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Single-Lvl Mat. Non-Invt. Cost"), SLNonInvMatCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            RUNonInvMatCost,
            Item."Rolled-up Mat. Non-Invt. Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Rolled-up Mat. Non-Invt. Cost"), RUNonInvMatCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            SLMatCost,
            Item."Single-Level Material Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Single-Level Material Cost"), SLMatCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            RUMatCost,
            Item."Rolled-up Material Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Rolled-up Material Cost"), RUMatCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            SLMfgOvhdCost,
            Item."Single-Level Mfg. Ovhd Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Single-Level Mfg. Ovhd Cost"), SLMfgOvhdCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            RUMfgOvhdCost,
            Item."Rolled-up Mfg. Ovhd Cost",
            StrSubstNo(ItemMustBeEqualErr, Item.FieldCaption("Rolled-up Mfg. Ovhd Cost"), RUMfgOvhdCost, Item."No.", Item.TableCaption()));
    end;

    local procedure CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrderNo: Code[20]; OutputQuantity: Decimal; SetupTime: Decimal; RunTime: Decimal; StopTime: Decimal; ScrapQuantity: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Validate("Setup Time", SetupTime);
        ItemJournalLine.Validate("Scrap Quantity", ScrapQuantity);
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Validate("Stop Time", StopTime);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndPostOutputJournalWithOutputQuantityAndUnitCost(ProductionOrderNo: Code[20]; OutputQuantity: Decimal; ScrapQuantity: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, ProductionOrderNo);
        if ItemJournalLine.FindFirst() then
            repeat
                ItemJournalLine.Validate("Output Quantity", OutputQuantity);
                ItemJournalLine.Validate("Setup Time", LibraryRandom.RandInt(100));
                ItemJournalLine.Validate("Scrap Quantity", ScrapQuantity);
                ItemJournalLine.Validate("Run Time", LibraryRandom.RandInt(100));
                ItemJournalLine.Validate("Unit Cost", UnitCost);
                ItemJournalLine.Modify(true);
            until ItemJournalLine.Next() = 0;
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndPostInvtAdjustmentOfItemWithLot(ItemNo: Code[20]; UnitCost: Decimal; LotNo: Code[50]; Quantity: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item."Unit Cost" := UnitCost;
        Item.Modify();

        CreateAndPostInvtAdjustmentOfItemWithLot(Item."No.", LotNo, Quantity);
    end;

    local procedure OpenItemTrackingLinesSetValue(var ProdOrderComponent: Record "Prod. Order Component"; LotNo: Code[50]; SerialNo: Code[50]; Quantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SetNewValue);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(Quantity);
        ProdOrderComponent.OpenItemTrackingLines();
    end;

    local procedure VerifyRegisteredWhseActivityLine(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; QtyToHandle: Decimal)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWhseActivityLine(RegisteredWhseActivityLine, SourceNo, ActionType, ActivityType);
        Assert.IsTrue((QtyToHandle = RegisteredWhseActivityLine.Quantity),
        StrSubstNo(ValueMustBeEqualErr, RegisteredWhseActivityLine.FieldCaption(Quantity), RegisteredWhseActivityLine.Quantity, RegisteredWhseActivityLine.TableCaption()));
    end;

    local procedure UpdateQuantityToHandleAndRegisterWarehouseActivity(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; QtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PutAwayPage: TestPage "Warehouse Put-away";
    begin
        WarehouseActivityLine.SetCurrentKey("Qty. to Handle");
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        WarehouseActivityLine.SetAscending("Qty. to Handle", true);

        PutAwayPage.OpenEdit();
        PutAwayPage.FILTER.SetFilter("No.", WarehouseActivityLine."No.");
        PutAwayPage.WhseActivityLines.GoToRecord(WarehouseActivityLine);
        PutAwayPage."&Register Put-away".Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(Message, ExpectedMessage), Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerWithoutValidation(Message: Text[1024])
    begin
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
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ApplToItemEntryNo: Integer;
        LotNo: Code[50];
        SerialNo: Code[50];
        Quantity: Decimal;
        ApplyToItemEntry: Boolean;
    begin
        ItemTrackingMode := LibraryVariableStorage.DequeueInteger();

        case ItemTrackingMode of
            ItemTrackingMode::AssignLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
                    LotNo := CopyStr(ItemTrackingLines."Lot No.".Value, 1, MaxStrLen(LotNo));
                end;
            ItemTrackingMode::AssignSerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();  // Assign Serial No.
                    SerialNo := CopyStr(ItemTrackingLines."Serial No.".Value, 1, MaxStrLen(SerialNo));
                end;
            ItemTrackingMode::SelectEntries:
                begin
                    ItemTrackingLines."Select Entries".Invoke();  // Item Tracking Summary Page is handled in 'ItemTrackingSummaryPageHandler'.
                    ApplyToItemEntry := LibraryVariableStorage.DequeueBoolean();
                    if ApplyToItemEntry then begin
                        ApplToItemEntryNo := LibraryVariableStorage.DequeueInteger();
                        ItemTrackingLines."Appl.-to Item Entry".SetValue(ApplToItemEntryNo);
                    end;
                end;
            ItemTrackingMode::SetValue:
                begin
                    LotNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo));
                    SerialNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(SerialNo));
                    Quantity := LibraryVariableStorage.DequeueDecimal();

                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."Serial No.".SetValue(SerialNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                end;
            ItemTrackingMode::SetNewValue:
                begin
                    ItemTrackingLines.New();
                    LotNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo));
                    SerialNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(SerialNo));
                    Quantity := LibraryVariableStorage.DequeueDecimal();

                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."Serial No.".SetValue(SerialNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                end;
            ItemTrackingMode::UpdateQuantityBase:
                ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
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
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    var
        ItemNo: Variant;
        Quantity: Variant;
        EntryType: Variant;
        EntryType2: Option;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(Quantity);
        LibraryVariableStorage.Dequeue(EntryType);
        EntryType2 := EntryType;
        ProductionJournal.FILTER.SetFilter("Item No.", ItemNo);
        ProductionJournal.FILTER.SetFilter("Entry Type", Format(EntryType2));
        ProductionJournal.Quantity.AssertEquals(Quantity);
        ProductionJournal."Output Quantity".AssertEquals(Quantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        LibraryVariableStorage.Enqueue(PostJournalLinesConfirmationMsg);  // Required inside ConfirmHandlerTRUE.
        LibraryVariableStorage.Enqueue(JournalLinesPostedMsg);  // Required inside MessageHandler.
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostProductionJournalHandlerWithUpdateQuantity(var ProductionJournal: TestPage "Production Journal")
    var
        ItemNo: Variant;
        Quantity: Variant;
        EntryType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(Quantity);
        LibraryVariableStorage.Dequeue(EntryType);
        ProductionJournal.FILTER.SetFilter("Item No.", ItemNo);
        ProductionJournal.FILTER.SetFilter("Entry Type", Format(EntryType));
        ProductionJournal.Last();
        ProductionJournal."Output Quantity".SetValue(Quantity);

        LibraryVariableStorage.Enqueue(PostJournalLinesConfirmationMsg); // Required inside ConfirmHandlerTRUE.
        LibraryVariableStorage.Enqueue(JournalLinesPostedMsg); // Required inside MessageHandler.
        LibraryVariableStorage.Enqueue(LeaveProductionJournalQst); // Required inside MessageHandler.
        ProductionJournal.Post.Invoke();
    end;

    local procedure UpdateInventoryAccountInterim(LocationCode: Code[10]; InventoryPostingGroupCode: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        InventoryPostingSetup.Get(LocationCode, InventoryPostingGroupCode);
        if InventoryPostingSetup."Inventory Account (Interim)" = '' then begin
            InventoryPostingSetup."Inventory Account (Interim)" := InventoryPostingSetup."Inventory Account";
            InventoryPostingSetup.Modify();
        end;
    end;

    local procedure CreateSalesOrderAndReleased(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndPostProductionJnlWithLotNo(ProductionOrder: Record "Production Order"; ProdOrderLineNo: Integer)
    var
        ReleaseProdOrder: TestPage "Released Production Order";
    begin
        ReleaseProdOrder.OpenView();
        ReleaseProdOrder.GoToRecord(ProductionOrder);
        ReleaseProdOrder.ProdOrderLines.Filter.SetFilter("Line No.", Format(ProdOrderLineNo));
        ReleaseProdOrder.ProdOrderLines.ProductionJournal.Invoke();
    end;

    local procedure VerifyReservationEntry(Item: Record Item; SourceType: Integer; ReservationStatus: Enum "Reservation Status")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        Assert.IsFalse(ReservationEntry.IsEmpty(), StrSubstNo(ReservationEntryMustExistErr, ReservationEntry.TableCaption));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByBOMPageHandler(var ItemAvailByBOMLevel: TestPage "Item Availability by BOM Level")
    begin
        ItemAvailByBOMLevel.Expand(true);
        ItemAvailByBOMLevel.Next();
        VerifyItemAvailabilityByBOMPage(ItemAvailByBOMLevel);

        ItemAvailByBOMLevel.Expand(true);
        ItemAvailByBOMLevel.Next();
        VerifyItemAvailabilityByBOMPage(ItemAvailByBOMLevel);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstEntries_MPH(var ItemSubstitutionEntries: TestPage "Item Substitution Entries")
    begin
        ItemSubstitutionEntries.First();
        repeat
            LibraryVariableStorage.Enqueue(ItemSubstitutionEntries."Substitute No.".Value);
        until not ItemSubstitutionEntries.Next();
        ItemSubstitutionEntries.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalSubcontractedPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.First();
        Assert.AreEqual(0, ProductionJournal."Output Quantity".AsDecimal(), ProdJournalOutQtyErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingPageHandler(var ProdOrderRouting: TestPage "Prod. Order Routing")
    begin
        ProdOrderRouting.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ProdOrderRoutingAddOperationPageHandler(var ProdOrderRouting: TestPage "Prod. Order Routing")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        LastOperationNo: Code[10];
    begin
        LastOperationNo := Format(1);
        ProdOrderRouting.Last();
        LastOperationNo := CopyStr(ProdOrderRouting."Operation No.".Value, 1, MaxStrLen(LastOperationNo));
        ProdOrderRouting.New();
        ProdOrderRouting."Operation No.".SetValue(IncStr(LastOperationNo));
        ProdOrderRouting.Type.SetValue(ProdOrderRoutingLine.Type::"Work Center");
        ProdOrderRouting."No.".SetValue(LibraryVariableStorage.DequeueText());
        ProdOrderRouting.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeStatusOnProdOrderPageHandler(var ChangeStatusOnProdOrder: TestPage "Change Status on Prod. Order")
    var
        NewStatus: Variant;
    begin
        LibraryVariableStorage.Dequeue(NewStatus);
        ChangeStatusOnProdOrder.FirmPlannedStatus.SetValue(NewStatus);
        ChangeStatusOnProdOrder.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ErrorMessagesPageHandler(var ErrorMessages: TestPage "Error Messages")
    var
        ErrorMessage: Record "Error Message";
    begin
        Assert.AreEqual(ErrorMessages."Message Type".AsInteger(), ErrorMessage."Message Type"::Error, '');
    end;

    [PageHandler]
    procedure ReleasedProdOrderPageHandler(var ReleasedProductionOrder: TestPage "Released Production Order")
    begin
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    procedure SourceDocumentsPageHandler(var SourceDocuments: TestPage "Source Documents")
    begin
        SourceDocuments.First();
        SourceDocuments."Source No.".AssertEquals('');
    end;

    [ModalPageHandler]
    procedure ProductionJournalPageHandler2(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.ItemTrackingLines.Invoke();
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    procedure ProductionJournalPageHandler3(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;
}
