// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.TestLibraries.Utilities;

codeunit 149913 "Subc SCM Supply Planning"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        LocationBlue: Record Location;
        LocationInTransit: Record Location;
        LocationSilver: Record Location;
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SubcManagementLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryDimension: Codeunit "Library - Dimension";
        isInitialized: Boolean;
        RequisitionLineProdOrderErr: Label '"Prod Order No." should be same as Released Production Order';
        PeriodType: Option Day,Week,Month,Quarter,Year,Period;
        AmountType: Option "Net Change","Balance at Date";
        AppliesToEntryMissingErr: Label 'Applies-to Entry must have a value';
        ItemNoErr: Label 'Item No. must be equal';
        DimSetIDErr: Label 'Dimension set id on Requisition Line does not match the updated dimension set id on production order line.';

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderForReleasedProdOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Exercise: Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Subcontracting Worksheet for Production Order, Quantity and WorkCenter Subcontractor.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        VerifyRequisitionLine(RequisitionLine, ProductionOrder, WorkCenter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderAndCarryOutForReleasedProdOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Calculate Subcontracts from Subcontracting worksheet and Carry Out Action Message.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Exercise: After carry out, Post Purchase Order as Receive and invoice.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PostPurchaseDocument(PurchaseLine, true);

        // Verify: Verify Inventory of Item is updated after Purchase Order posting for Item.
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, PurchaseLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubcontractCreditMemoSkipBaseQtyBalCheck()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        PurchInvoiceHeader: Record "Purch. Inv. Header";
        PurchCreditMemo: Record "Purchase Header";
        ReasonCode: Record "Reason Code";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO] Bug 420029 - Validation for quantity and base quantity balance should be skipped for subcontract credit memo
        // [GIVEN] Item, routing, work center.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");
        LibraryERM.CreateReasonCode(ReasonCode);

        // [GIVEN] Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // [GIVEN] Calculate Subcontracts from Subcontracting worksheet and Carry Out Action Message.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [WHEN] After carry out, Post Purchase Order as Receive and invoice.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PostPurchaseDocument(PurchaseLine, true);

        // [WHEN] Create corrective credit memo
        PurchInvoiceHeader.SetRange("Order No.", PurchaseLine."Document No.");
        PurchInvoiceHeader.FindFirst();
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvoiceHeader, PurchCreditMemo);

        // [THEN] Validation of base qty balanced should not be triggered when Updating Qty. to Invoice in credit memo lines
        // [THEN] Instead, missing applies-to entry error is thrown
        PurchCreditMemo.Validate("Vendor Cr. Memo No.", PurchCreditMemo."No.");
        PurchCreditMemo.Validate("Reason Code", ReasonCode.Code);
        PurchCreditMemo.Modify(true);
        asserterror LibraryPurchase.PostPurchaseDocument(PurchCreditMemo, true, true);
        Assert.ExpectedError(AppliesToEntryMissingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderForReleasedProdOrderWithBinAndCarryOutForPurchase()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order with Location and Bin.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", LocationSilver.Code, Bin.Code);

        // Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Exercise: Carry Out Action Message for Subcontracting worksheet.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Verify: Verify Location and Bin of Released Production order is also updated on Purchase Order created after carry out.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseLine.TestField("Location Code", ProductionOrder."Location Code");
        PurchaseLine.TestField("Bin Code", ProductionOrder."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderAndCarryOutWithNewDueDateAndQuantity()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Calculate Subcontracts from Subcontracting worksheet. Update new Quantity and Due Date on Requisition Line.
        CalculateSubcontractOrder(WorkCenter);
        UpdateRequisitionLineDueDateAndQuantity(
          RequisitionLine, Item."No.", ProductionOrder.Quantity + LibraryRandom.RandDec(10, 2));  // Quantity more than Production Order Quantity.

        // Exercise: Carry Out Action Message for Subcontracting worksheet.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Verify: Verify updated Due Date and quantity of Requisition Line is also updated on Purchase Order created after carry out.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseLine.TestField(Quantity, RequisitionLine.Quantity);
        PurchaseLine.TestField("Expected Receipt Date", RequisitionLine."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderAndCarryOutForReleasedProdOrderWithUpdatedUOM()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // Setup: Create Item. Create Routing and update on Item. Create additional Base Unit of Measure for Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);

        // Create and refresh Released Production Order. Update new Unit Of Measure on Production Order Line.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.
        UpdateProdOrderLineUnitOfMeasureCode(Item."No.", ItemUnitOfMeasure.Code);

        // Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Exercise: Carry Out Action Message for Subcontracting worksheet.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Verify: Verify updated Unit of Measure of Released Production Order is also updated on Purchase Order created after carry out.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseLine.TestField("Unit of Measure", ItemUnitOfMeasure.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderWithProdOrderRoutingLineForReleasedProdOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Exercise: Calculate Subcontracts from Subcontracting worksheet With Production Order Routing Line.
        CalculateSubcontractsWithProdOrderRoutingLine(ProductionOrder."No.", WorkDate());

        // Verify: Verify that no Requisition line is created for Subcontracting Worksheet.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderWithMultiLineRoutingForReleasedProdOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
    begin
        // Setup: Create Item. Create Multi Line Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateAndCertifyMultiLineRoutingSetup(WorkCenter, RoutingHeader, RoutingLine, RoutingLine2);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create and refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // Exercise: Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // Verify: Verify Subcontracting Worksheet for Production Order, Quantity, WorkCenter Subcontractor and Operation No.
        VerifyRequisitionLineWithOperationNoForSubcontractingWorksheet(
          ProductionOrder, WorkCenter, Item."No.", RoutingLine."Operation No.");
        VerifyRequisitionLineWithOperationNoForSubcontractingWorksheet(
          ProductionOrder, WorkCenter, Item."No.", RoutingLine2."Operation No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSubcontractOrderAndCarryOutForReleasedProdOrderWithLocation()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        PurchLine: Record "Purchase Line";
    begin
        // Setup: Create Item. Create Routing and update on Item.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // Create Location, Create and refresh Released Production Order with Location.
        LibraryWarehouse.CreateLocation(Location);
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", Location.Code, '');

        // Exercise: Calculate Subcontracts from Subcontracting worksheet and Carry Out Action Message.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // Re-validate the Quantity on the purchase line created by Subcontracting worksheet.
        FindPurchLine(PurchLine, Item."No.");
        PurchLine.Validate(Quantity, ProductionOrder.Quantity);
        PurchLine.Modify(true);

        // Verify: Verify "Qty. on Purch. Order" on Item Card.
        Item.CalcFields("Qty. on Purch. Order");
        Item.TestField("Qty. on Purch. Order", 0);

        // Verify the value of Projected Available Balance on Item Availability By Location Page.
        VerifyItemAvailabilityByLocation(Item, Location.Code, ProductionOrder.Quantity);

        // Verify Scheduled Receipt and Projected Available Balance on Item Availability By Period Page.
        // the value of Scheduled Receipt equal to 0 on the line that Period Start is a day before WORKDATE
        // and the value of Scheduled Receipt equal to ProductionOrder.Quantity on the line that Period Start is WORKDATE
        // the value of Projected Available Balance equal to ProductionOrder.Quantity on the line that Period Start is WORKDATE
        VerifyItemAvailabilityByPeriod(Item, 0, ProductionOrder.Quantity, ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineIsDeletedWhileCalculatingWorksheetForDifferentBatch()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionWkshName2: Record "Requisition Wksh. Name";
    begin
        // [FEATURE] [Subcontracting Worksheet]
        // [SCENARIO 363390] Requisition Line is deleted in Batch "A" while Calculating Worksheet for same Line for Batch "B"
        Initialize();

        // [GIVEN] Released Production Order for Item with Routing
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');

        // [GIVEN] Requisition Worksheet Batch "A"
        CreateRequisitionWorksheetName(RequisitionWkshName);

        // [GIVEN] Requisition Worksheet Batch "B"
        CreateRequisitionWorksheetName(RequisitionWkshName2);

        // [GIVEN] Calculate Worksheet for Batch "A". Requisition Worksheet Line "X" is created.
        CalculateSubcontractingWorksheetForBatch(RequisitionWkshName, WorkCenter);

        // [WHEN] Calculate Worksheet for Batch "B".
        CalculateSubcontractingWorksheetForBatch(RequisitionWkshName2, WorkCenter);

        // [THEN] Requisition Worksheet Line "Y" = "X" is created. Line "X" is deleted from Batch "A".
        VerifyRequisitionLineForTwoBatches(RequisitionWkshName.Name, RequisitionWkshName2.Name, Item."No.", ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcChangeSubcontractOrderWithExistingPurchase()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RequisitionLine: Record "Requisition Line";
        NewQty: Decimal;
    begin
        // [FEATURE] [Subcontracting Worksheet] [Requisition Line]
        // [SCENARIO] Can change Quantity in Subcontracting Worksheet if replenishment already exists.

        // [GIVEN] Item with subcontracting routing, create Released Production Order.
        Initialize();
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');

        // [GIVEN] Calculate Subcontracts, accept and Carry Out Action.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [GIVEN] Update Quantity, Calculate Subcontracts.
        UpdateProdOrderLineQty(Item."No.", ProductionOrder.Quantity + LibraryRandom.RandIntInRange(1, 5));
        CalculateSubcontractOrder(WorkCenter);

        // [WHEN] In Subcontracting Worksheet, change Quantity.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        NewQty := RequisitionLine.Quantity + LibraryRandom.RandIntInRange(1, 5);
        RequisitionLine.Validate(Quantity, NewQty);

        // [THEN] Quantity changed.
        RequisitionLine.TestField(Quantity, NewQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubcontractPurchHeaderNotSavedWhenLineCreationFails()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Subcontracting Worksheet]
        // [SCENARIO 382090] Purchase header created from the subcontracting worksheet should not be saved when lines cannot be generated due to erroneous setup

        Initialize();

        // [GIVEN] Work center "W" with linked subcontractor, routing "R" includes an operation on the work center "W"
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Work center "W" is not properly configured, because its Gen. Prod. Posting Group does not exist
        WorkCenter."Gen. Prod. Posting Group" := LibraryUtility.GenerateGUID();
        WorkCenter.Modify();

        // [GIVEN] Create a production order involving the usage of the work center "W"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Calculate subcontrat orders
        CalculateSubcontractOrder(WorkCenter);

        // [WHEN] Carry out subcontracting worksheet
        asserterror CarryOutActionMessageSubcontractWksh(Item."No.");

        // [THEN] Creation of a subcontracting purchase order fails, purchase header is not saved
        PurchaseHeader.Init();
        PurchaseHeader.SetRange("Buy-from Vendor No.", WorkCenter."Subcontractor No.");
        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckValueEntryExpectedCostForReceivedNotInvoicedSubcontrPurchaseOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Subcontracting] [Production] [Expected Cost]
        // [SCENARIO 381570] Expected cost of production output posted via purchase order for subcontracting should be calculated as "Unit Cost" on production order line multiplied by output quantity.
        Initialize();

        // [GIVEN] Item "I" with routing with subcontractor "S" for workcenter "W".
        CreateItemWithChildReplenishmentPurchaseAsProdBOM(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Refreshed released production order for "Q" pcs of item "I".
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');

        // [GIVEN] Set "Unit Cost" = "X" on the prod. order line.
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ProdOrderLine.Modify(true);

        // [GIVEN] Calculate subcontracts for "W".
        CalculateSubcontractOrder(WorkCenter);

        // [GIVEN] Update unit cost on subcontracting worksheet line to "Y".
        // [GIVEN] Carry out action messages for Subcontracting Worksheet with creation of purchase order with vendor "S".
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [WHEN] Post the purchase order as Receive but not as Invoice.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PostPurchaseDocument(PurchaseLine, false);

        // [THEN] In related Value Entry expected cost amount is equal to "Q" * "X".
        FindValueEntry(ValueEntry, Item."No.");
        ValueEntry.TestField(
          "Cost Amount (Expected)",
          Round(ProdOrderLine."Unit Cost" * PurchaseLine.Quantity, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderValueEntryRelatedGLProdOrderNo()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        ValueEntry: Record "Value Entry";
        GLItemLedgerRelation: Record "G/L - Item Ledger Relation";
    begin
        // [SCENARIO 415833] G/L entries related to Value Entry should contain 'Prod. Order No.' 
        // [GIVEN] Create Item. Create Routing and update on Item.
        Initialize();
        LibraryInventory.SetAutomaticCostPosting(true);
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN]  Create and refresh Released Production Order. 'Order No.' = 'RPON'
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');  // Without Location and Bin.

        // [GIVEN] Calculate Subcontracts from Subcontracting worksheet and Carry Out Action Message.
        CalculateSubcontractOrder(WorkCenter);
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [WHEN] After carry out, Post Purchase Order as Receive and invoice.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PostPurchaseDocument(PurchaseLine, true);
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
        Assert.IsTrue(not PurchInvHeader.IsEmpty(), 'No purchase invoice header found for Vendor No. = ' + PurchaseLine."Buy-from Vendor No.");

        // [THEN] G/L Entry related to Value Entry have 'Prod. Order No.' = 'RPON'
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ProductionOrder."No.");
        ValueEntry.FindSet();
        repeat
            GLItemLedgerRelation.SetRange("Value Entry No.", ValueEntry."Entry No.");
            if GLItemLedgerRelation.FindSet() then
                repeat
                    GLEntry.Get(GLItemLedgerRelation."G/L Entry No.");
                    GLEntry.TestField("Prod. Order No.", ProductionOrder."No.");
                until GLItemLedgerRelation.Next() = 0;
        until ValueEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNoErrorWhenReceivingSubContractingPurchaseOrder()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
        RoutingHeader: Record "Routing Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO 490899] Receiving a purchase order for Subcontracting results in No error
        Initialize();

        // [GIVEN] Create Item
        CreateItem(Item);

        // [GIVEN] Create Routing Setup
        CreateRoutingSetup(WorkCenter, RoutingHeader);

        // [GIVEN] Update Item Routing
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh Released Production Order with Location and Bin.
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", LocationSilver.Code, Bin.Code);

        // [GIVEN] Calculate Subcontracts from Subcontracting worksheet.
        CalculateSubcontractOrder(WorkCenter);

        // [GIVEN] Carry Out Action Message for Subcontracting worksheet.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [WHEN] Post and Receive Purchase Order
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify Purchase Order is received with warehouse entry.
        VerifyWareHouseEntry(PurchaseLine."No.")
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure UndoReceiptFromPostedPurchaseReceiptForSubcontractPurchaseOrderOnAverageCosting()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        PurchRcptLine: array[2] of Record "Purch. Rcpt. Line";
    begin
        // [SCENARIO 579253] Undoing Receipt from a Posted Purchase Receipt for a Subcontract Purchase Order Using Average Costing.
        Initialize();

        // [GIVEN] Create Item with routing with Subcontractor and Workcenter.
        CreateItemWithChildReplenishmentPurchaseAsProdBOM(Item);

        // [GIVEN] Validate Costing Method into Item.
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify(true);

        // [GIVEN] Create Routing Setup.
        CreateRoutingSetup(WorkCenter, RoutingHeader);

        // [GIVEN] Update an Item Routing No.
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Refreshed released production order for "Q" pcs of item "I".
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');

        // [GIVEN] Set "Unit Cost" = "X" on the Production Order Line.
        ProdOrderLine.SetRange("Item No.", Item."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ProdOrderLine.Modify(true);

        // [GIVEN] Calculate subcontracts for "W".
        CalculateSubcontractOrder(WorkCenter);

        // [GIVEN] Carry out action messages for Subcontracting Worksheet with creation of Purchase Order.
        CarryOutActionMessageSubcontractWksh(Item."No.");

        // [GIVEN] Post the Purchase Order as Receive but not as Invoice.
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PostPurchaseDocument(PurchaseLine, false);

        // [GIVEN] Find Purchase Recipt Line.
        PurchRcptLine[1].SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine[1].FindFirst();

        // [WHEN] Undo Purchase Receipt Line.
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine[1]);

        // [THEN] New Purchase Recipt Line with Negative Quantity is created.
        PurchRcptLine[2].SetRange("Document No.", PurchRcptLine[1]."Document No.");
        PurchRcptLine[2].SetRange(Quantity, -PurchRcptLine[1].Quantity);
        Assert.RecordIsNotEmpty(PurchRcptLine[2]);
    end;

    [Test]
    procedure VerifyDimensionCalcSubcontractOrderForReleasedProdOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        RoutingHeader: Record "Routing Header";
        WorkCenter: Record "Work Center";
        NewDimSetID: Integer;
    begin
        // [SCENARIO 620065] Missing Dimension in Subcontracting Worksheet.
        Initialize();

        // [GIVEN] Create Item with Routing with Subcontractor and Workcenter.
        CreateItem(Item);
        CreateRoutingSetup(WorkCenter, RoutingHeader);
        UpdateItemRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh Released Production Order without Location and Bin.
        CreateAndRefreshReleasedProductionOrderWithLocationAndBin(ProductionOrder, Item."No.", '', '');

        // [GIVEN] Update Dimension on Production Order Line.
        NewDimSetID := UpdateProductionOrderDimension(ProductionOrder."No.");

        // [WHEN] Calculate Subcontracting Worksheet for Work Center.
        CalculateSubcontractOrder(WorkCenter);

        // [THEN] Verify Dimension Set ID on Requisition Line matches updated Dimension Set ID on Production Order Line.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();
        Assert.AreEqual(NewDimSetID, RequisitionLine."Dimension Set ID", DimSetIDErr);
    end;

    local procedure Initialize()
    var
        RequisitionLine: Record "Requisition Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Subc SCM Supply Planning");
        RequisitionLine.DeleteAll();
        ReservationEntry.DeleteAll();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Subc SCM Supply Planning");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        CreateLocationSetup();
        ItemJournalSetup();
        LibrarySetupStorage.Save(Database::"Manufacturing Setup");
        LibrarySetupStorage.Save(Database::"Inventory Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Subc SCM Supply Planning");
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure CreateLocationSetup()
    begin
        CreateAndUpdateLocation(LocationSilver);  // Location Silver: Bin Mandatory TRUE.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Random Integer value required for Number of Bins.
    end;

    local procedure ItemJournalSetup()
    begin
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateItemWithChildReplenishmentPurchaseAsProdBOM(var Item: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ChildItem: Record Item;
    begin
        CreateAndUpdateItem(
          Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::Order,
          Item."Manufacturing Policy"::"Make-to-Order", '');
        CreateChildItemAsProdBOM(ChildItem, ProductionBOMHeader, ChildItem."Replenishment System"::Purchase);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateAndUpdateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; ManufacturingPolicy: Enum "Manufacturing Policy"; VendorNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Validate("Vendor No.", VendorNo);
        Item.Modify(true);
    end;

    local procedure CreateChildItemAsProdBOM(var ChildItem: Record Item; var ProductionBOMHeader: Record "Production BOM Header"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        CreateAndUpdateItem(
          ChildItem, ReplenishmentSystem, ChildItem."Reordering Policy"::Order,
          ChildItem."Manufacturing Policy"::"Make-to-Order", '');
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateProductionBOMNoOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CertifyRouting(var RoutingHeader: Record "Routing Header")
    begin
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateRoutingSetup(var WorkCenter: Record "Work Center"; var RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        CertifyRouting(RoutingHeader);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
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

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        SubcManagementLibrary.CreateSubcontractor(Vendor);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);

        // Calculate calendar.
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
    end;

    local procedure UpdateItemRoutingNo(var Item: Record Item; RoutingNo: Code[20])
    begin
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrderWithLocationAndBin(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LoactionCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate("Location Code", LoactionCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CalculateSubcontractOrder(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.SetRange("No.", WorkCenter."No.");
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenter);
    end;

    local procedure CarryOutActionMessageSubcontractWksh(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    local procedure AcceptActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInDecimalRange(10, 20, 2));
        RequisitionLine.Modify(true);
    end;

    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
    end;

    local procedure SelectPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindPurchLine(var PurchLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange("No.", ItemNo);
        PurchLine.FindFirst();
    end;

    local procedure PostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; ToInvoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, ToInvoice);
    end;

    local procedure UpdateProdOrderLineUnitOfMeasureCode(ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateProdOrderLineQty(ItemNo: Code[20]; NewQty: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate(Quantity, NewQty);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateRequisitionLineDueDateAndQuantity(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        NewDate: Date;
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        NewDate := GetRequiredDate(10, 0, RequisitionLine."Due Date", 1);  // Due Date more than current Due Date on Requisition Line.
        RequisitionLine.Validate("Due Date", NewDate);
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Modify(true);
    end;

    local procedure GetRequiredDate(Days: Integer; IncludeAdditionalPeriod: Integer; RelativeDate: Date; SignFactor: Integer) NewDate: Date
    begin
        // Calculating a New Date relative to WorkDate.
        NewDate :=
          CalcDate('<' + Format(SignFactor * LibraryRandom.RandInt(Days) + IncludeAdditionalPeriod) + 'D>', RelativeDate);
    end;

    local procedure CreateAndCertifyMultiLineRoutingSetup(var WorkCenter: Record "Work Center"; var RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line"; var RoutingLine2: Record "Routing Line")
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        CreateRoutingLine(RoutingLine2, RoutingHeader, WorkCenter."No.");
        CertifyRouting(RoutingHeader);
    end;

    local procedure CalculateSubcontractsWithProdOrderRoutingLine(ProductionOrderNo: Code[20]; StartingDate: Date)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange("Starting Date", StartingDate);
        SubcManagementLibrary.CalculateSubcontractOrderWithProdOrderRoutingLine(ProdOrderRoutingLine);
    end;

    local procedure CalculateSubcontractingWorksheetForBatch(RequisitionWkshName: Record "Requisition Wksh. Name"; WorkCenter: Record "Work Center")
    var
        RequisitionLine: Record "Requisition Line";
        CalculateSubcontracts: Report Microsoft.Manufacturing.Subcontracting."Subc. Calculate Subcontracts";
    begin
        RequisitionLine.Init();
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        Clear(CalculateSubcontracts);
        CalculateSubcontracts.SetWkShLine(RequisitionLine);
        CalculateSubcontracts.SetTableView(WorkCenter);
        CalculateSubcontracts.UseRequestPage(false);
        CalculateSubcontracts.RunModal();
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::Planning);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        Location.Validate("Pick According to FEFO", false);
        Location.Modify(true);
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ItemNo: Code[20])
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
    end;

    local procedure UpdateProductionOrderDimension(ProductionOrderNo: Code[20]) DimensionSetID: Integer
    var
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
    begin
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        ProductionOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProductionOrderLine.FindFirst();
        DimensionSetID := SelectNewDimSetID(ProductionOrderLine."Dimension Set ID");

        ProductionOrderLine.Validate("Dimension Set ID", DimensionSetID);
        ProductionOrderLine.Modify(true);
    end;

    local procedure SelectNewDimSetID(OldDimSetID: Integer): Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        Dimension.Next();
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        exit(LibraryDimension.CreateDimSet(OldDimSetID, Dimension.Code, DimensionValue.Code));
    end;

    local procedure VerifyRequisitionLine(RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order"; WorkCenter: Record "Work Center")
    begin
        RequisitionLine.TestField("Prod. Order No.", ProductionOrder."No.");
        RequisitionLine.TestField(Quantity, ProductionOrder.Quantity);
        RequisitionLine.TestField("Work Center No.", WorkCenter."No.");
        RequisitionLine.TestField("Vendor No.", WorkCenter."Subcontractor No.");
    end;

    local procedure VerifyRequisitionLineWithOperationNoForSubcontractingWorksheet(ProductionOrder: Record "Production Order"; WorkCenter: Record "Work Center"; No: Code[20]; OperationNo: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
#pragma warning disable AA0210
        RequisitionLine.SetRange("Operation No.", OperationNo);
#pragma warning restore AA0210
        RequisitionLine.FindFirst();
        RequisitionLine.TestField("No.", No);
        VerifyRequisitionLine(RequisitionLine, ProductionOrder, WorkCenter);
    end;

    local procedure VerifyItemAvailabilityByPeriod(Item: Record Item; ScheduledRcpt: Decimal; ScheduledRcpt2: Decimal; ProjAvailableBalance: Decimal)
    var
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByPeriod: TestPage "Item Availability by Periods";
    begin
        ItemCard.OpenView();
        ItemCard.Filter.SetFilter("No.", Item."No.");
        ItemAvailabilityByPeriod.Trap();
        ItemCard.Period.Invoke();

        ItemAvailabilityByPeriod.PeriodType.SetValue(PeriodType::Day);
        ItemAvailabilityByPeriod.AmountType.SetValue(AmountType::"Balance at Date");
        ItemAvailabilityByPeriod.ItemAvailLines.Filter.SetFilter("Period Start", StrSubstNo('%1..%2', WorkDate() - 1, WorkDate()));
        ItemAvailabilityByPeriod.ItemAvailLines.First();
        ItemAvailabilityByPeriod.ItemAvailLines.ScheduledRcpt.AssertEquals(ScheduledRcpt);
        ItemAvailabilityByPeriod.ItemAvailLines.Next();
        ItemAvailabilityByPeriod.ItemAvailLines.ScheduledRcpt.AssertEquals(ScheduledRcpt2);
        ItemAvailabilityByPeriod.ItemAvailLines.ProjAvailableBalance.AssertEquals(ProjAvailableBalance);
        ItemAvailabilityByPeriod.Close();
    end;

    local procedure VerifyItemAvailabilityByLocation(Item: Record Item; LocationCode: Code[10]; ProjAvailableBalance: Decimal)
    var
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByLocation: TestPage "Item Availability by Location";
    begin
        // Quantity assertions for the Item availability by location window
        ItemCard.OpenView();
        ItemCard.Filter.SetFilter("No.", Item."No.");
        ItemAvailabilityByLocation.Trap();
        ItemCard.Location.Invoke();

        ItemAvailabilityByLocation.ItemPeriodLength.SetValue(PeriodType::Day);
        ItemAvailabilityByLocation.AmountType.SetValue(AmountType::"Balance at Date");
        ItemAvailabilityByLocation.FILTER.SetFilter("No.", Item."No.");
        ItemAvailabilityByLocation.ItemAvailLocLines.FILTER.SetFilter(Code, LocationCode);
        ItemAvailabilityByLocation.ItemAvailLocLines.First();

        ItemAvailabilityByLocation.ItemAvailLocLines.ProjAvailableBalance.AssertEquals(ProjAvailableBalance);
        ItemAvailabilityByLocation.Close();
    end;

    local procedure VerifyRequisitionLineForTwoBatches(RequisitionWkshName: Code[10]; RequisitionWkshName2: Code[10]; ItemNo: Code[20]; ProductionOrderNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName2);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        Assert.AreEqual(ProductionOrderNo, RequisitionLine."Prod. Order No.", RequisitionLineProdOrderErr);

        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName);
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    local procedure VerifyWareHouseEntry(ItemNo: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.FindLast();
        Assert.AreEqual(WarehouseEntry."Item No.", ItemNo, ItemNoErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}