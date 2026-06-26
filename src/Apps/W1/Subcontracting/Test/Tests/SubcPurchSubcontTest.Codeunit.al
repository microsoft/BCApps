// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 139991 "Subc. Purch. Subcont. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        ItemTrackingWasOpened: Boolean;
        UnitCostCalculation: Option Time,Units;

    [Test]
    procedure VendorLocationWithBinMandatoryThrowsError()
    var
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        // [SCENARIO] Setting a vendor's subcontracting location to a location with "Bin Mandatory" enabled should throw an error with ErrorInfo

        Initialize();

        // [GIVEN] A location with Bin Mandatory enabled
        LibraryWarehouse.CreateLocation(Location);
        Location."Bin Mandatory" := true;
        Location.Modify();

        // [GIVEN] A vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Try to set the vendor's Subc. Location Code to the location with Bin Mandatory
        // [THEN] An error is thrown with ErrorInfo
        asserterror Vendor.Validate("Subc. Location Code", Location.Code);
        Assert.ExpectedError('Location ' + Location.Code + ' cannot be used as a subcontracting location because Bin Mandatory or warehouse handling is enabled on the location.');
    end;

    [Test]
    procedure VendorLocationWithRequirePickThrowsError()
    var
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        // [SCENARIO] Setting a vendor's subcontracting location to a location with "Require Pick" enabled should throw an error

        Initialize();

        // [GIVEN] A location with Require Pick enabled
        LibraryWarehouse.CreateLocation(Location);
        Location."Require Pick" := true;
        Location.Modify();

        // [GIVEN] A vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Try to set the vendor's Subc. Location Code to the location with Require Pick
        // [THEN] An error is thrown
        asserterror Vendor.Validate("Subc. Location Code", Location.Code);
        Assert.ExpectedError('Location ' + Location.Code + ' cannot be used as a subcontracting location because Bin Mandatory or warehouse handling is enabled on the location.');
    end;

    [Test]
    procedure VendorLocationWithoutWarehouseHandlingSucceeds()
    var
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        // [SCENARIO] Setting a vendor's subcontracting location to a valid location should succeed

        Initialize();

        // [GIVEN] A location without warehouse handling
        LibraryWarehouse.CreateLocation(Location);
        Location."Bin Mandatory" := false;
        Location."Require Pick" := false;
        Location."Require Put-away" := false;
        Location."Require Receive" := false;
        Location."Require Shipment" := false;
        Location.Modify();

        // [GIVEN] A vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Set the vendor's Subc. Location Code to the valid location
        // [THEN] The validation succeeds and the field is updated
        Vendor.Validate("Subc. Location Code", Location.Code);
        Assert.AreEqual(Location.Code, Vendor."Subc. Location Code", 'Subc. Location Code should be set to the valid location');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesSimpleHandler')]
    procedure ItemTrackingLinesCanBeOpenedOnNonSubcontractingPurchaseLine()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // [SCENARIO] Opening item tracking lines on a regular (non-subcontracting) purchase line succeeds
        // [FEATURE] Bug 629884 - The subcontracting extension must not intercept OnBeforeOpenItemTrackingLines for non-subcontracting lines

        Initialize();

        // [GIVEN] An item with lot purchase inbound tracking
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Purchase Inbound Tracking", true);
        ItemTrackingCode.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);

        // [GIVEN] A purchase order with a regular (non-subcontracting) purchase line
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 10));

        // [VERIFY] The purchase line has no subcontracting link (Subc. Purchase Line Type = None)
        Assert.AreEqual(
            "Subc. Purchase Line Type"::None, PurchaseLine."Subc. Purchase Line Type",
            'Purchase line must have Subc. Purchase Line Type = None for this test');

        // [WHEN] Open item tracking lines on the non-subcontracting purchase line
        // Before fix: the event subscriber always set IsHandled = true, preventing the standard
        // item tracking page from opening even when the purchase line was not a subcontracting line.
        ItemTrackingWasOpened := false;
        PurchaseLine.OpenItemTrackingLines();

        // [THEN] The standard item tracking lines page was opened
        Assert.IsTrue(
            ItemTrackingWasOpened,
            'Item tracking lines page must open for a non-subcontracting purchase line');
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess')]
    procedure PostSubcontPurchOrder_PurchWithService_BackwardFlush()
    var
        ComponentItem: Record Item;
        FinishedItem: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location, HomeLocation : Record Location;
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        ReleasedProdOrderRtng: TestPage "Prod. Order Routing";
        Qty: Decimal;
    begin
        // [SCENARIO] When posting a subcontracting purchase order where the BOM has a component
        // with Component Supply Method = "Purchase with Service" and Flushing Method = Backward,
        // the component is consumed via backward flushing when the output is posted.
        // BOM: 1 component item (Component Supply Method = Purchase with Service, linked to Routing Line 100).
        // Routing: 1 subcontracting line (Operation 100).
        // Purchase order has 2 lines: Finished Good (output) + Component (Purchase with Service).
        // After posting the purchase order:
        // - Finished good gets positive output ILE.
        // - Component gets positive purchase receipt ILE AND negative consumption ILE (backward flushing).
        // - Net component inventory = 0.
        Initialize();

        // [GIVEN] A subcontracting work center with vendor and location
        CreateAndCalculateNeededWorkCenter(WorkCenter, true);
        Vendor.Get(WorkCenter."Subcontractor No.");
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Subc. Location Code" := Location.Code;
        Vendor.Modify();

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(HomeLocation);

        // [GIVEN] A routing with a single subcontracting line (Operation 100)
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(
            RoutingLine, RoutingHeader, WorkCenter."No.", '100',
            LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));

        // [GIVEN] A routing link connecting BOM component to routing line
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // [GIVEN] A component item with Flushing Method = Backward
        LibraryManufacturing.CreateItemManufacturing(
            ComponentItem, "Costing Method"::FIFO, LibraryRandom.RandInt(10),
            "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::Backward, '', '');

        // [GIVEN] A production BOM with one component, Component Supply Method = Purchase with Service
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", 1);
        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Validate("Component Supply Method", "Component Supply Method"::"Vendor-Supplied");
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] A finished good item with the routing and production BOM
        LibraryManufacturing.CreateItemManufacturing(
            FinishedItem, "Costing Method"::FIFO, LibraryRandom.RandInt(10),
            "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual",
            RoutingHeader."No.", ProductionBOMHeader."No.");

        // [GIVEN] A released production order
        Qty := LibraryRandom.RandInt(10) + 5;
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, FinishedItem."No.", Qty, HomeLocation.Code);

        // [GIVEN] Requisition worksheet template for subcontracting
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        // [WHEN] Create subcontracting purchase order from Prod. Order Routing
        ProdOrderRtngLine.SetRange("Routing No.", RoutingHeader."No.");
        ProdOrderRtngLine.SetRange("Work Center No.", WorkCenter."No.");
        ProdOrderRtngLine.FindFirst();

        ReleasedProdOrderRtng.OpenView();
        ReleasedProdOrderRtng.GoToRecord(ProdOrderRtngLine);
        ReleasedProdOrderRtng.CreateSubcontracting.Invoke();

        // [WHEN] Post the purchase order (receive)
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        if PurchaseLine.FindSet() then
            repeat
                EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
            until PurchaseLine.Next() = 0;

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Finished good has a positive output ILE
        ItemLedgerEntry.SetRange("Item No.", FinishedItem."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, Qty);

        // [THEN] Component has a positive purchase receipt ILE
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", ComponentItem."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, Qty);

        // [THEN] Component has a negative consumption ILE (backward flushing)
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", ComponentItem."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, -Qty);

        // [THEN] Net inventory of component is zero (received and consumed via backward flushing)
        ComponentItem.CalcFields(Inventory);
        Assert.AreEqual(0, ComponentItem.Inventory, 'Component inventory should be zero after backward flushing.');
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess,HandleTransferOrder')]
    procedure CannotModifySubcPurchLineWhenTransferOrderExists()
    var
        Item: Record Item;
        HomeLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
    begin
        // [SCENARIO] Modifying key fields on a subcontracting purchase line must be blocked
        // when a transfer order exists for the linked production order.
        Initialize();

        // [GIVEN] A subcontracting purchase order with a linked transfer order
        SetupSubContractingProdOrder(Item, HomeLocation, WorkCenter, MachineCenter, ProductionOrder, "Component Supply Method"::"Transfer to Vendor", LibraryRandom.RandIntInRange(1, 10));
        CreateSubcontractingPurchaseOrderForProdOrder(PurchaseHeader, PurchaseLine, Item, WorkCenter, ProductionOrder);
        CreateTransferOrderForPurchaseOrder(PurchaseHeader);

        // [WHEN] Attempt to modify key fields on the subcontracting purchase line
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");

        // [THEN] CheckSubcPurchLineCanBeModified blocks modification of Quantity
        asserterror SubcTransferManagement.CheckSubcPurchLineCanBeModified(PurchaseLine, PurchaseLine.FieldCaption(Quantity));
        Assert.ExpectedError('You cannot change Quantity on the subcontracting purchase line');

        // [THEN] CheckSubcPurchLineCanBeModified blocks modification of Location Code
        asserterror SubcTransferManagement.CheckSubcPurchLineCanBeModified(PurchaseLine, PurchaseLine.FieldCaption("Location Code"));
        Assert.ExpectedError('You cannot change Location Code on the subcontracting purchase line');

        // [THEN] CheckSubcPurchLineCanBeModified blocks modification of Variant Code
        asserterror SubcTransferManagement.CheckSubcPurchLineCanBeModified(PurchaseLine, PurchaseLine.FieldCaption("Variant Code"));
        Assert.ExpectedError('You cannot change Variant Code on the subcontracting purchase line');
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess,HandleTransferOrder,MessageHandler')]
    procedure ModifySubcPurchLineAllowedAfterFullConsumptionAtSubcLocation()
    var
        Item: Record Item;
        HomeLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        WorkCenter: array[2] of Record "Work Center";
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
    begin
        // [SCENARIO] After all component stock transferred to the subcontractor location has been
        // consumed, modifying purchase line fields should be allowed because net stock = 0.
        Initialize();

        // [GIVEN] A subcontracting purchase order with a linked transfer order
        SetupSubContractingProdOrder(Item, HomeLocation, WorkCenter, MachineCenter, ProductionOrder, "Component Supply Method"::"Transfer to Vendor", LibraryRandom.RandIntInRange(1, 10));
        CreateSubcontractingPurchaseOrderForProdOrder(PurchaseHeader, PurchaseLine, Item, WorkCenter, ProductionOrder);
        CreateTransferOrderForPurchaseOrder(PurchaseHeader);

        // [VERIFY] Modification is blocked because transfer order exists
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        asserterror SubcTransferManagement.CheckSubcPurchLineCanBeModified(PurchaseLine, PurchaseLine.FieldCaption(Quantity));
        Assert.ExpectedError('transfer orders exist');

        // [WHEN] Transfer order is posted to the subcontractor location
        FindTransferOrderForPurchaseLine(TransferHeader, PurchaseLine);
        PostDirectTransferOrder(TransferHeader);

        // [VERIFY] Modification is blocked because stock exists at the subcontractor location
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        asserterror SubcTransferManagement.CheckSubcPurchLineCanBeModified(PurchaseLine, PurchaseLine.FieldCaption(Quantity));
        Assert.ExpectedError('remaining components or WIP items transferred to the subcontractor');

        // [VERIFY] Purchase Order deletion is blocked because stock was transferred to the subcontractor location
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        asserterror PurchaseHeader.Delete(true);

        // [GIVEN] All transferred stock has been consumed at the subcontractor location
        FindTransferProdOrderComponent(ProdOrderComponent, PurchaseLine);
        LibraryMfgManagement.PostConsumptionForAllComponents(ProdOrderComponent);

        // [VERIFY] Modification is blocked because WIP item remains at the subcontractor location
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        asserterror SubcTransferManagement.CheckSubcPurchLineCanBeModified(PurchaseLine, PurchaseLine.FieldCaption(Quantity));
        Assert.ExpectedError('remaining components or WIP items transferred to the subcontractor');

        // [WHEN] Return transfer order is created and posted to return remaining WIP item from subcontractor location
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        CreateReturnTransferOrderForPurchaseOrder(PurchaseHeader);

        FindTransferOrderForPurchaseLine(TransferHeader, PurchaseLine);
        PostDirectTransferOrder(TransferHeader);

        // [WHEN] CheckSubcPurchLineCanBeModified is called after full consumption
        // [THEN] No error is raised because net stock at the subcontractor location is zero
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        SubcTransferManagement.CheckSubcPurchLineCanBeModified(PurchaseLine, PurchaseLine.FieldCaption(Quantity));
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess,HandleTransferOrder,MessageHandler')]
    procedure SubcTransferPartialConsumptionAndReturnFlow()
    var
        ComponentItem: Record Item;
        Item: Record Item;
        HomeLocation: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnTransferHeader: Record "Transfer Header";
        ReturnTransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseOrderPage: TestPage "Purchase Order";
        TransferredQty: Decimal;
        ConsumedQty: Decimal;
        ReturnQty: Decimal;
    begin
        // [SCENARIO] Full subcontracting transfer lifecycle: create transfer order, post transfer
        // to subcontractor, post partial consumption, create return transfer via purchase order action,
        // adjust return qty to remaining stock, and post the return.
        Initialize();

        // [GIVEN] A subcontracting purchase order with a linked transfer order
        SetupSubContractingProdOrder(Item, HomeLocation, WorkCenter, MachineCenter, ProductionOrder, "Component Supply Method"::"Transfer to Vendor", LibraryRandom.RandIntInRange(1, 10));
        CreateSubcontractingPurchaseOrderForProdOrder(PurchaseHeader, PurchaseLine, Item, WorkCenter, ProductionOrder);
        CreateTransferOrderForPurchaseOrder(PurchaseHeader);

        // [GIVEN] Get transfer order and component for the purchase line
        FindTransferProdOrderComponent(ProdOrderComponent, PurchaseLine);
        ProdOrderComponent.FindFirst();


        FindTransferOrderForPurchaseLine(TransferHeader, PurchaseLine);
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Item No.", ProdOrderComponent."Item No.");
        TransferLine.FindFirst();
        TransferredQty := TransferLine.Quantity;
        ConsumedQty := Round(TransferredQty / 2, 1);
        ReturnQty := TransferredQty - ConsumedQty;

        // [WHEN] Transfer order is posted to the subcontractor location
        PostDirectTransferOrder(TransferHeader);

        // [THEN] Transfer ILE exists at the subcontractor location with correct quantity
        ProdOrderComponent.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.");
        ProdOrderComponent.CalcFields("Subc. Qty. transf. to Subcontr");
        Assert.AreEqual(TransferredQty, ProdOrderComponent."Subc. Qty. transf. to Subcontr",
            'Transferred qty should equal full quantity after posting transfer order.');

        // [WHEN] Partial consumption is posted at the subcontractor location
        ProdOrderLine.Get(ProductionOrder.Status, ProductionOrder."No.", ProdOrderComponent."Prod. Order Line No.");
        ComponentItem.Get(ProdOrderComponent."Item No.");
        LibraryMfgManagement.PostConsumptionForComponent(ProdOrderLine, ProdOrderComponent, ComponentItem, ConsumedQty);

        // [THEN] Consumption ILE exists with negative quantity
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Order Line No.", ProdOrderComponent."Prod. Order Line No.");
        ItemLedgerEntry.SetRange("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        ItemLedgerEntry.SetRange("Location Code", ProdOrderComponent."Location Code");
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(-ConsumedQty, ItemLedgerEntry.Quantity,
            'Consumption ILE quantity should be negative consumed qty.');

        // [WHEN] Return transfer order is created via the purchase order action
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseOrderPage.OpenView();
        PurchaseOrderPage.GoToRecord(PurchaseHeader);
        PurchaseOrderPage.CreateReturnFromSubcontractor.Invoke();
        PurchaseOrderPage.Close();

        // [THEN] Return transfer line is created with correct quantity (only remaining physical stock, not consumed)
        ReturnTransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        ReturnTransferLine.SetRange("Subc. Prod. Ord. Comp Line No.", ProdOrderComponent."Line No.");
        ReturnTransferLine.SetRange("Item No.", ProdOrderComponent."Item No.");
        ReturnTransferLine.SetRange("Subc. Return Order", true);
        ReturnTransferLine.FindFirst();
        Assert.AreEqual(ReturnQty, ReturnTransferLine.Quantity,
            'Return transfer line quantity should equal remaining physical stock (transferred - consumed).');
        ReturnTransferHeader.Get(ReturnTransferLine."Document No.");

        // [THEN] Return transfer order is posted
        PostDirectTransferOrder(ReturnTransferHeader);
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess,HandleTransferOrder,MessageHandler')]
    procedure SecondReturnTransferSucceedsAfterPartialReceiptAndReturn()
    var
        Item: Record Item;
        HomeLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnTransferHeader: Record "Transfer Header";
        ReturnTransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseOrderPage: TestPage "Purchase Order";
        ProductionQty: Decimal;
        FirstReceiptQty: Decimal;
        SecondReceiptQty: Decimal;
    begin
        // [SCENARIO 638694] Creating a second return transfer order after partial receipts must not fail
        // with "Transfer-to Code must have a value" when Subc. Original Location Code was cleared
        // by a previous return cycle.
        Initialize();
        ProductionQty := 10;
        FirstReceiptQty := 4;
        SecondReceiptQty := 3;

        // [GIVEN] A subcontracting purchase order with qty=10 and transfer-to-vendor components
        SetupSubContractingProdOrder(Item, HomeLocation, WorkCenter, MachineCenter, ProductionOrder, "Component Supply Method"::"Transfer to Vendor", ProductionQty);
        CreateSubcontractingPurchaseOrderForProdOrder(PurchaseHeader, PurchaseLine, Item, WorkCenter, ProductionOrder);

        // [GIVEN] Outbound transfer order is created and posted (components sent to subcontractor)
        CreateTransferOrderForPurchaseOrder(PurchaseHeader);
        FindTransferOrderForPurchaseLine(TransferHeader, PurchaseLine);
        PostDirectTransferOrder(TransferHeader);

        // [GIVEN] First partial purchase receipt (4 of 10)
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseLine.Validate("Qty. to Receive", FirstReceiptQty);
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] First return transfer order is created and posted (returns remaining components)
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        CreateReturnTransferOrderForPurchaseOrder(PurchaseHeader);
        ReturnTransferLine.SetRange("Subc. Purch. Order No.", PurchaseLine."Document No.");
        ReturnTransferLine.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        ReturnTransferLine.SetRange("Subc. Return Order", true);
        ReturnTransferLine.FindFirst();
        ReturnTransferHeader.Get(ReturnTransferLine."Document No.");
        PostDirectTransferOrder(ReturnTransferHeader);

        // [GIVEN] A new outbound transfer for the remaining outstanding qty is created and posted
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        CreateTransferOrderForPurchaseOrder(PurchaseHeader);
        FindTransferOrderForPurchaseLine(TransferHeader, PurchaseLine);
        PostDirectTransferOrder(TransferHeader);

        // [GIVEN] Second partial purchase receipt (3 of remaining 6)
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", SecondReceiptQty);
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Second return transfer order is created
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseOrderPage.OpenView();
        PurchaseOrderPage.GoToRecord(PurchaseHeader);
        PurchaseOrderPage.CreateReturnFromSubcontractor.Invoke();
        PurchaseOrderPage.Close();

        // [THEN] No error occurs and a return transfer line is created with correct Transfer-to Code
        ReturnTransferLine.Reset();
        ReturnTransferLine.SetRange("Subc. Purch. Order No.", PurchaseLine."Document No.");
        ReturnTransferLine.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        ReturnTransferLine.SetRange("Subc. Return Order", true);
        ReturnTransferLine.FindLast();
        ReturnTransferHeader.Get(ReturnTransferLine."Document No.");
        Assert.AreNotEqual('', ReturnTransferHeader."Transfer-to Code",
            'Transfer-to Code must be populated on the second return transfer order.');
        Assert.AreEqual(HomeLocation.Code, ReturnTransferHeader."Transfer-to Code",
            'Transfer-to Code should be the original (home) location.');
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess,HandleTransferOrder')]
    procedure CannotModifyOrDeleteRoutingLineWhenTransferOrderExistsWithTransferToVendor()
    var
        Item: Record Item;
        HomeLocation: Record Location;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRtng: TestPage "Prod. Order Routing";
    begin
        // [SCENARIO] Modifying key fields or deleting a Prod. Order Routing Line must be blocked
        // when subcontracting transfer orders exist for Transfer to Vendor components.
        Initialize();

        // [GIVEN] A subcontracting purchase order with a linked transfer order
        SetupSubContractingProdOrder(Item, HomeLocation, WorkCenter, MachineCenter, ProductionOrder, "Component Supply Method"::"Transfer to Vendor", LibraryRandom.RandIntInRange(1, 10));
        CreateSubcontractingPurchaseOrderForProdOrder(PurchaseHeader, PurchaseLine, Item, WorkCenter, ProductionOrder);
        CreateTransferOrderForPurchaseOrder(PurchaseHeader);

        // [GIVEN] Find routing line for the subcontracting work center
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderRoutingLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        ProdOrderRoutingLine.FindFirst();

        // [THEN] Changing No. is blocked
        ProdOrderRtng.OpenEdit();
        ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
        asserterror ProdOrderRtng."No.".SetValue(WorkCenter[1]."No.");
        Assert.ExpectedError('You cannot change this routing line because transfer orders exist');
        ProdOrderRtng.Close();

        // [THEN] Changing Type is blocked
        ProdOrderRtng.OpenEdit();
        ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
        asserterror ProdOrderRtng.Type.SetValue(ProdOrderRoutingLine.Type::"Machine Center");
        Assert.ExpectedError('You cannot change this routing line because transfer orders exist');
        ProdOrderRtng.Close();

        // [THEN] Changing Routing Link Code is blocked
        ProdOrderRtng.OpenEdit();
        ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
        asserterror ProdOrderRtng."Routing Link Code".SetValue('');
        Assert.ExpectedError('You cannot change this routing line because transfer orders exist');
        ProdOrderRtng.Close();

        // [THEN] Deleting the routing line is blocked
        asserterror ProdOrderRoutingLine.Delete(true);
        Assert.ExpectedError('You cannot change this routing line because transfer orders exist');
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess,HandleTransferOrder')]
    procedure CannotModifyOrDeleteRoutingLineWhenTransferOrderExistsWithVendorSupplied()
    var
        Item: Record Item;
        HomeLocation: Record Location;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRtng: TestPage "Prod. Order Routing";
    begin
        // [SCENARIO] Modifying key fields or deleting a Prod. Order Routing Line must be blocked
        // when subcontracting transfer orders exist for Transfer to Vendor components.
        Initialize();

        // [GIVEN] A subcontracting purchase order with a linked transfer order
        SetupSubContractingProdOrder(Item, HomeLocation, WorkCenter, MachineCenter, ProductionOrder, "Component Supply Method"::"Vendor-Supplied", LibraryRandom.RandIntInRange(1, 10));
        CreateSubcontractingPurchaseOrderForProdOrder(PurchaseHeader, PurchaseLine, Item, WorkCenter, ProductionOrder);
        CreateTransferOrderForPurchaseOrder(PurchaseHeader);

        // [GIVEN] Find routing line for the subcontracting work center
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderRoutingLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        ProdOrderRoutingLine.FindFirst();

        // [THEN] Changing No. is blocked
        ProdOrderRtng.OpenEdit();
        ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
        asserterror ProdOrderRtng."No.".SetValue(WorkCenter[1]."No.");
        Assert.ExpectedError('You cannot change this routing line because transfer orders exist');
        ProdOrderRtng.Close();

        // [THEN] Changing Type is blocked
        ProdOrderRtng.OpenEdit();
        ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
        asserterror ProdOrderRtng.Type.SetValue(ProdOrderRoutingLine.Type::"Machine Center");
        Assert.ExpectedError('You cannot change this routing line because transfer orders exist');
        ProdOrderRtng.Close();

        // [THEN] Changing Routing Link Code is blocked
        ProdOrderRtng.OpenEdit();
        ProdOrderRtng.GoToRecord(ProdOrderRoutingLine);
        asserterror ProdOrderRtng."Routing Link Code".SetValue('');
        Assert.ExpectedError('You cannot change this routing line because transfer orders exist');
        ProdOrderRtng.Close();

        // [THEN] Deleting the routing line is blocked
        asserterror ProdOrderRoutingLine.Delete(true);
        Assert.ExpectedError('You cannot change this routing line because transfer orders exist');
    end;

    [Test]
    procedure WorkCenterRoutingLinesExcludedFromMultiSelectionWhenMachineCenterPresent()
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        Item, Item2 : Record Item;
        MachineCenter: Record "Machine Center";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
        MachineCenterNo: Code[20];
        NoOfCreatedOrders: Integer;
    begin
        // [SCENARIO] When CreateSubcontractingOrdersForRoutingLineSelection is called with a mixed
        // selection containing both Work Center and Machine Center routing lines, only the
        // Work Center lines result in a subcontracting purchase order.
        // This verifies that the Work Center type filter is applied correctly when simulating
        // multi-record selection (CurrPage.SetSelectionFilter cannot be used in test framework).
        Initialize();

        // [GIVEN] A subcontracting Work Center with a vendor
        CreateAndCalculateNeededWorkCenter(WorkCenter, true);

        // [GIVEN] A Machine Center belonging to the subcontracting Work Center
        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenter."No.", "Flushing Method"::"Pick + Manual".AsInteger());
        MachineCenter.Get(MachineCenterNo);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        // [GIVEN] A routing with a Work Center line (Op 010) and a Machine Center line (Op 020),
        // both referencing the same subcontracting Work Center
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenter."No.", '010', 1, 1);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);

        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, MachineCenter."No.", '020', 1, 1);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        LibraryInventory.CreateItem(Item2);
        LibraryManufacturing.CreateProductionBOM(Item2, 2);

        // [GIVEN] An item with the routing and a released production order
        LibraryManufacturing.CreateItemManufacturing(
            Item, "Costing Method"::FIFO, LibraryRandom.RandInt(10),
            "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual",
            RoutingHeader."No.", Item2."Production BOM No.");

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 1);

        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        // [WHEN] All routing lines (Work Center Op 010 + Machine Center Op 020) are passed to
        // CreateSubcontractingOrdersForRoutingLineSelection, simulating a multi-record selection
        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        NoOfCreatedOrders := SubcPurchaseOrderCreator.CreateSubcontractingOrdersForRoutingLineSelection(ProdOrderRoutingLine);

        // [THEN] Exactly one purchase order is created (Work Center line is filtered out)
        Assert.AreEqual(1, NoOfCreatedOrders, 'Exactly one subcontracting purchase order must be created.');

        // [THEN] The purchase order is linked to the Work Center operation (Op 010)
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Operation No.", '010');
        Assert.RecordCount(PurchaseLine, 1);

        // [THEN] No purchase order is created for the Machine Center operation (Op 020)
        PurchaseLine.SetRange("Operation No.", '020');
        Assert.RecordIsEmpty(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess')]
    procedure SubcOrderFlowFieldIsTrueAfterCreatingSubcontractingPurchaseOrder()
    var
        FinishedItem: Record Item;
        Location: Record Location;
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        ReleasedProdOrderRtng: TestPage "Prod. Order Routing";
    begin
        // [SCENARIO 640115] After creating a subcontracting purchase order from a Prod. Order Routing Line,
        // the "Subc. Order" FlowField on the Purchase Header must evaluate to true so the order is visible
        // in the "Subcontracting Orders" view of the Purchase Order List.

        Initialize();

        // [GIVEN] A subcontracting work center with vendor and location
        CreateAndCalculateNeededWorkCenter(WorkCenter, true);
        Vendor.Get(WorkCenter."Subcontractor No.");
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Subc. Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] A routing with a single subcontracting operation
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(
            RoutingLine, RoutingHeader, WorkCenter."No.", '100',
            LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // [GIVEN] A finished good item with the routing
        LibraryManufacturing.CreateItemManufacturing(
            FinishedItem, "Costing Method"::FIFO, LibraryRandom.RandInt(10),
            "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual",
            RoutingHeader."No.", '');
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, FinishedItem."Base Unit of Measure");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        FinishedItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        FinishedITem.Validate("Routing No.", RoutingHeader."No.");
        FinishedItem.Modify(true);

        // [GIVEN] A released production order
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, FinishedItem."No.", LibraryRandom.RandInt(10), Location.Code);

        // [GIVEN] Requisition worksheet template for subcontracting
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        // [WHEN] Create subcontracting purchase order from Prod. Order Routing
        ProdOrderRtngLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRtngLine.SetRange(Type, ProdOrderRtngLine.Type::"Work Center");
        ProdOrderRtngLine.SetRange("Work Center No.", WorkCenter."No.");
        ProdOrderRtngLine.FindFirst();
        ReleasedProdOrderRtng.OpenView();
        ReleasedProdOrderRtng.GoToRecord(ProdOrderRtngLine);
        ReleasedProdOrderRtng.CreateSubcontracting.Invoke();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();

        // [THEN] A purchase order was created and the "Subc. Order" FlowField is true
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.CalcFields("Subc. Order");
        Assert.IsTrue(PurchaseHeader."Subc. Order",
            'The Subc. Order FlowField must be true for a subcontracting purchase order');
    end;
    [ModalPageHandler]
    procedure ItemTrackingLinesSimpleHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingWasOpened := true;
        ItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure DoConfirmCreateProdOrderForSubcontractingProcess(Question: Text[1024]; var Reply: Boolean)
    begin
        case true of
            Question.Contains('Do you want to create a production order from'):
                Reply := true;
            else
                Reply := false;
        end;
    end;

    [PageHandler]
    procedure HandleTransferOrder(var TransfOrderPage: TestPage "Transfer Order")
    begin
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    local procedure CreateAndCalculateNeededWorkCenter(var WorkCenter: Record "Work Center"; IsSubcontracting: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ShopCalendarCode: Code[10];
        WorkCenterNo: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();

        // [GIVEN] Create and Calculate needed Work and Machine Center
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::"Pick + Manual", IsSubcontracting, UnitCostCalculation, '');
        WorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));
    end;

    local procedure CreateWorkCenter(var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10]; FlushingMethod: Enum "Flushing Method"; IsSubcontracting: Boolean; UnitCostCalc: Option; CurrencyCode: Code[10])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        WorkCenter: Record "Work Center";
    begin
        // Create Work Center with required fields where random is used, values not important for test.
        LibraryMfgManagement.CreateWorkCenterWithFixedCost(WorkCenter, ShopCalendarCode, 0);

        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Overhead Rate", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalc);

        if IsSubcontracting then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GenProductPostingGroup.FindFirst();
            GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            GenProductPostingGroup.Modify(true);
            WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(CurrencyCode));
        end;
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Purch. Subcont. Test");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Purch. Subcont. Test");

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Purch. Subcont. Test");
    end;

    local procedure EnsureGeneralPostingSetupIsValid(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup) then begin
            if GeneralPostingSetup.Blocked then begin
                GeneralPostingSetup.Blocked := false;
                GeneralPostingSetup.Modify();
            end;
            exit;
        end;

        GeneralPostingSetup.Init();
        GeneralPostingSetup."Gen. Bus. Posting Group" := GenBusPostingGroup;
        GeneralPostingSetup."Gen. Prod. Posting Group" := GenProdPostingGroup;
        GeneralPostingSetup.Insert();
        GeneralPostingSetup.SuggestSetupAccounts();
    end;

    local procedure SetupSubcontractingEnvironment()
    begin
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
    end;

    local procedure CreateSubcontractingWorkCenters(var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    begin
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);
    end;

    local procedure SetupProductionItemWithTransferComponent(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center"; ComponentSupplyMethod: Enum "Component Supply Method")
    begin
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, ComponentSupplyMethod);
        SetTransferWIPItemOnRoutingLine(Item."Routing No.", WorkCenter[2]."No.", true);
    end;

    local procedure CreateProductionOrderWithTransferRoute(var ProductionOrder: Record "Production Order"; var Location: Record Location; var Item: Record Item; ProductionQty: Decimal)
    begin
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", ProductionQty, Location.Code);
    end;

    local procedure CreateSubcontractingPurchaseOrderForProdOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var ProductionOrder: Record "Production Order")
    begin
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");
        PurchaseLine.SetCurrentKey("Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
#pragma warning disable AA0210              
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    local procedure CreateTransferOrderForPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create Transf. Order", false, false, PurchaseHeader);
    end;

    local procedure CreateReturnTransferOrderForPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetRecFilter();
        Report.Run(Report::"Subc. Create SubCReturnOrder", false, false, PurchaseHeader);
    end;

    local procedure SetupSubContractingProdOrder(var Item: Record Item; var Location: Record Location; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center"; var ProductionOrder: Record "Production Order"; ComponentSupplyMethod: Enum "Component Supply Method"; ProductionQty: Decimal)
    begin
        SetupSubcontractingEnvironment();
        CreateSubcontractingWorkCenters(WorkCenter, MachineCenter);
        SetupProductionItemWithTransferComponent(Item, WorkCenter, MachineCenter, ComponentSupplyMethod);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateProductionOrderWithTransferRoute(ProductionOrder, Location, Item, ProductionQty);
        CreateInventoryForAllComponents(ProductionOrder);
    end;

    local procedure FindTransferProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; PurchaseLine: Record "Purchase Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing No.", PurchaseLine."Routing No.");
        ProdOrderRoutingLine.SetRange("Operation No.", PurchaseLine."Operation No.");
        ProdOrderRoutingLine.FindFirst();

        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.SetRange("Subc. Purchase Order Filter", PurchaseLine."Document No.");
#pragma warning disable AA0210
        ProdOrderComponent.SetRange("Component Supply Method", ProdOrderComponent."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
    end;

    local procedure FindTransferOrderForPurchaseLine(var TransferHeader: Record "Transfer Header"; PurchaseLine: Record "Purchase Line")
    var
        TransferLine: Record "Transfer Line";
    begin
#pragma warning disable AA0210
        TransferLine.SetRange("Subc. Purch. Order No.", PurchaseLine."Document No.");
        TransferLine.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        TransferLine.SetRange("Subc. Prod. Order No.", PurchaseLine."Prod. Order No.");
#pragma warning restore AA0210
        TransferLine.FindFirst();
        TransferHeader.Get(TransferLine."Document No.");
    end;

    local procedure CreateAndPostItemInventory(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostDirectTransferOrder(var TransferHeader: Record "Transfer Header")
    var
        TransferOrderPage: TestPage "Transfer Order";
    begin
        TransferOrderPage.OpenView();
        TransferOrderPage.GoToRecord(TransferHeader);
        TransferOrderPage.Post.Invoke();
    end;

    local procedure CreateInventoryForAllComponents(ProductionOrder: Record "Production Order")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        if ProdOrderComponent.FindSet() then
            repeat
                CreateAndPostItemInventory(ProdOrderComponent."Item No.", ProdOrderComponent."Location Code", ProdOrderComponent."Expected Quantity");
            until ProdOrderComponent.Next() = 0;
    end;

    local procedure SetTransferWIPItemOnRoutingLine(RoutingNo: Code[20]; WorkCenterNo: Code[20]; TransferWIPItem: Boolean)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        RoutingHeader.Get(RoutingNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenterNo);
        RoutingLine.FindFirst();
        RoutingLine."Transfer WIP Item" := TransferWIPItem;
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

}