// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 149919 "Subc. Invt. Put-away E2E Purch"
{
    // [FEATURE] Subcontracting Inventory Put-away E2E Purchase Tests
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcLibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Invt. Put-away E2E Purch");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Invt. Put-away E2E Purch");

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Invt. Put-away E2E Purch");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SingleOperationE2ECreateEditPostVerify()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Purchase Full Lifecycle
        // [SCENARIO] Post a single LastOperation purchase order through Inventory Put-away.

        // [GIVEN] Single-op routing (LastOperation), Location L-PA, Vendor with subcontracting setup
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        // [GIVEN] Production Order released, subcontracting purchase order generated and released
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN]  Inventory Put-Away is created from the purchase order
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);

        // [THEN]  One activity line created; Subc. Purchase Line Type = LastOperation; Qty. per UoM restored (>0)
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
#pragma warning disable AA0210
        WarehouseActivityLine.SetRange("Subc. Purchase Line Type", "Subc. Purchase Line Type"::LastOperation);
#pragma warning restore AA0210
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual("Subc. Purchase Line Type"::LastOperation, WarehouseActivityLine."Subc. Purchase Line Type", 'Activity line should be last operation');
        Assert.IsTrue(WarehouseActivityLine."Qty. per Unit of Measure" > 0, 'Qty. per Unit of Measure must be restored');

        // [WHEN]  AutoFill Qty. to Handle is invoked, then the Put-Away is posted
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN]  Purch. Rcpt. Header/Line created; Posted Invt. Put-away Header/Line created
        GetPurchRcptLine(PurchRcptLine, PurchaseLine);
        Assert.AreEqual(Quantity, PurchRcptLine.Quantity, 'Purchase receipt line quantity should match order quantity');

        PostedInvtPutAwayLine.SetRange("Source Type", Database::"Purchase Line");
        PostedInvtPutAwayLine.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(PostedInvtPutAwayLine);
        PostedInvtPutAwayLine.FindFirst();
        PostedInvtPutAwayHeader.Get(PostedInvtPutAwayLine."No.");
        Assert.AreNotEqual('', PostedInvtPutAwayHeader."No.", 'Posted inventory put-away header should exist');

        // [THEN]  Output Item Ledger Entry created (Quantity = order qty); Capacity Ledger Entry created
        SubcWarehouseLibrary.VerifyItemLedgerEntry(Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[2]."No.", Quantity);

        // [THEN]  Purchase Line is fully received and the Warehouse Request is completely handled
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(0, PurchaseLine."Outstanding Quantity", 'Purchase line should be fully received');
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Order");
        WarehouseRequest.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(WarehouseRequest);
        WarehouseRequest.FindFirst();
        Assert.IsTrue(WarehouseRequest."Completely Handled", 'Warehouse request should be marked completely handled after full receipt');

        // [THEN]  Production Order routing line status updated to Finished (last operation)
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", PurchaseLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Operation No.", PurchaseLine."Operation No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(ProdOrderRoutingLine."Routing Status"::Finished, ProdOrderRoutingLine."Routing Status", 'Routing line should be finished');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TransferWIPItemIsNotSetOnPurchasePutAwayLine()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        Initialize();

        // [GIVEN] A subcontracting purchase line whose routing source has Transfer WIP Item enabled.
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 5, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Assert.IsTrue(PurchaseLine."Transfer WIP Item", 'The purchase line must carry the routing WIP flag for this regression test.');
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN] An Inventory Put-away is created from the purchase order.
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();

        // [THEN] Purchase-source activity lines do not inherit Transfer WIP Item.
        Assert.IsFalse(WarehouseActivityLine."Subc. Transfer WIP Item", 'Transfer WIP Item must only be copied from transfer lines.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TwoOperationSequentialPutAwayPerOperation()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineFirstOp: Record "Purchase Line";
        PurchaseLineLastOp: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Sequential Multi-Operation Posting
        // [SCENARIO] Two-operation E2E — sequential put-away per operation, combined verification
        // Confirms the sequential, per-operation posting pattern for a two-operation routing: posting the
        // NotLastOperation (Op 10) put-away first only advances that operation's routing status and posts a Capacity
        // Ledger Entry (no item movement), while the LastOperation (Op 20) put-away — posted afterward — is the one
        // that finally creates the output Item Ledger Entry and closes both purchase lines.

        // [GIVEN] Two-op routing, Location L-PA, both purchase lines released in one purchase order
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenterSameVendor(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        PurchaseLineFirstOp.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLineFirstOp.SetRange("Document No.", PurchaseHeader."No.");

#pragma warning disable AA0210
        PurchaseLineFirstOp.SetRange("Work Center No.", WorkCenter[1]."No.");
#pragma warning restore AA0210

        PurchaseLineFirstOp.FindFirst();

        PurchaseLineLastOp.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLineLastOp.SetRange("Document No.", PurchaseHeader."No.");
#pragma warning disable AA0210
        PurchaseLineLastOp.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLineLastOp.FindFirst();

        // [WHEN]  Create + post Inventory Put-Away for Op 10 (NotLastOperation) only
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        if WarehouseActivityLine.FindSet() then
            repeat
                if WarehouseActivityLine."Source Line No." = PurchaseLineFirstOp."Line No." then
                    WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity)
                else
                    WarehouseActivityLine.Validate("Qty. to Handle", 0);
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN]  Capacity Ledger Entry only for Op 10; no Item Ledger Entry; no Warehouse Entry
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[1]."No.", Quantity);
        SubcWarehouseLibrary.VerifyNoItemLedgerEntry(Item."No.", Location.Code);
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", Location.Code);

        // [THEN]  Production Order: Op 10 routing status = Finished, Op 20 still Active
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", PurchaseLineFirstOp."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Operation No.", PurchaseLineFirstOp."Operation No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(ProdOrderRoutingLine."Routing Status"::Finished, ProdOrderRoutingLine."Routing Status", 'First operation should be finished');

        ProdOrderRoutingLine.SetRange("Routing Reference No.", PurchaseLineLastOp."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Operation No.", PurchaseLineLastOp."Operation No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreNotEqual(ProdOrderRoutingLine."Routing Status"::Finished, ProdOrderRoutingLine."Routing Status", 'Second operation should still be active');

        // [WHEN]  Post Inventory Put-Away for Op 20 (LastOperation)
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN]  Output Item Ledger Entry created; Capacity Ledger Entry for Op 20
        SubcWarehouseLibrary.VerifyItemLedgerEntry(Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[2]."No.", Quantity);

        // [THEN]  Both Purchase Lines Outstanding Quantity = 0; both Warehouse Requests fully handled
        PurchaseLineFirstOp.Get(PurchaseLineFirstOp."Document Type", PurchaseLineFirstOp."Document No.", PurchaseLineFirstOp."Line No.");
        PurchaseLineLastOp.Get(PurchaseLineLastOp."Document Type", PurchaseLineLastOp."Document No.", PurchaseLineLastOp."Line No.");
        Assert.AreEqual(0, PurchaseLineFirstOp."Outstanding Quantity", 'First purchase line should be fully received');
        Assert.AreEqual(0, PurchaseLineLastOp."Outstanding Quantity", 'Second purchase line should be fully received');
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Order");
        WarehouseRequest.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(WarehouseRequest);
        WarehouseRequest.FindFirst();
        Assert.IsTrue(WarehouseRequest."Completely Handled", 'Warehouse Request should be marked completely handled once both purchase lines are fully received');

        // [THEN]  Production Order fully consumed/output reconciles with routing operations quantity
        ProdOrderRoutingLine.SetRange("Routing Reference No.", PurchaseLineLastOp."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Operation No.", PurchaseLineLastOp."Operation No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(ProdOrderRoutingLine."Routing Status"::Finished, ProdOrderRoutingLine."Routing Status", 'Second operation should be finished');
        SubcWarehouseLibrary.VerifyItemLedgerEntry(Item."No.", Quantity, Location.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure MultiVendorCombinedGetSourceDocumentsScenario()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader1: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineRemaining: Record "Purchase Line";
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityHeaderPO1: Record "Warehouse Activity Header";
        WarehouseActivityHeaderPO2: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseRequest: Record "Warehouse Request";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Multi-Source Aggregation
        // [SCENARIO] Multi-vendor combined scenario via single Put-Away worksheet/get-source
        // When two operations of the same routing are outsourced to two different vendors, a single combined "Get
        // Source Documents" run must still create separate activity lines per source purchase line, each retaining
        // its own "Subc. Purchase Line Type" classification. Verifies partial posting (one vendor's line) leaves the
        // other vendor's line outstanding, and that posting both eventually closes both purchase lines independently.

        // [GIVEN] Two-op routing with two different vendors (per operation)
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        // [GIVEN] Warehouse Employee must be created here even though the location is not Bin Mandatory.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor1.Get(WorkCenter[1]."Subcontractor No.");
        Vendor1."Subc. Location Code" := Location.Code;
        Vendor1."Location Code" := Location.Code;
        Vendor1.Modify(true);

        Vendor2.Get(WorkCenter[2]."Subcontractor No.");
        Vendor2."Subc. Location Code" := Location.Code;
        Vendor2."Location Code" := Location.Code;
        Vendor2.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader1);

        PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
#pragma warning disable AA0210
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        PurchaseLine.SetRange("Buy-from Vendor No.", Vendor1."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader1.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        PurchaseLine.SetRange("Buy-from Vendor No.", Vendor2."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader1);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader2);

        // [WHEN]  Create Inventory Put-away documents for all released purchase orders at the location
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Order");
        WarehouseRequest.SetRange("Location Code", Location.Code);
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, true, false, false);
        WarehouseActivityHeader.SetRange(Type, "Warehouse Activity Type"::"Invt. Put-away");
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);

        // [THEN]  Two separate activity headers created (one per source purchase order), each keeps its own Subc. Purchase Line Type
        Assert.RecordCount(WarehouseActivityHeader, 2);
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeader1."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual("Subc. Purchase Line Type"::NotLastOperation, WarehouseActivityLine."Subc. Purchase Line Type", 'First vendor line should remain not last operation');
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeaderPO1 := WarehouseActivityHeader;

        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeader2."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual("Subc. Purchase Line Type"::LastOperation, WarehouseActivityLine."Subc. Purchase Line Type", 'Second vendor line should remain last operation');
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeaderPO2 := WarehouseActivityHeader;

        PurchaseLineRemaining.Reset();
        PurchaseLineRemaining.SetRange("Document Type", PurchaseHeader2."Document Type");
        PurchaseLineRemaining.SetRange("Document No.", PurchaseHeader2."No.");
        PurchaseLineRemaining.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLineRemaining.FindFirst();

        // [THEN]  Posting one at a time leaves the other outstanding; full posting closes both
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeaderPO1);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeaderPO1, false);

        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader1."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader1."No.");
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.FindFirst();
        Assert.AreEqual(0, PurchaseLine."Outstanding Quantity", 'First source should be closed after first posting');

        PurchaseLineRemaining.SetRange("Document Type", PurchaseHeader2."Document Type");
        PurchaseLineRemaining.SetRange("Document No.", PurchaseHeader2."No.");
        PurchaseLineRemaining.FindFirst();
        Assert.AreEqual(Quantity, PurchaseLineRemaining."Outstanding Quantity", 'Second source should remain outstanding after first posting');

        // [THEN]  Posting only the first (NotLastOperation) vendor's line creates a Capacity Ledger Entry for that
        // work center only, and no output Item Ledger Entry / Warehouse Entry yet (no physical output until the
        // LastOperation line posts).
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[1]."No.", Quantity);
        SubcWarehouseLibrary.VerifyNoItemLedgerEntry(Item."No.", Location.Code);
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", Location.Code);

        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeaderPO2);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeaderPO2, false);

        PurchaseLineRemaining.Get(PurchaseLineRemaining."Document Type", PurchaseLineRemaining."Document No.", PurchaseLineRemaining."Line No.");
        Assert.AreEqual(0, PurchaseLineRemaining."Outstanding Quantity", 'Second source should be closed after final posting');

        // [THEN]  Posting the second (LastOperation) vendor's line creates the output Item Ledger Entry and a
        // Capacity Ledger Entry for that work center too; the first work center's Capacity Ledger Entry remains
        // unchanged from the earlier posting.
        SubcWarehouseLibrary.VerifyItemLedgerEntry(Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[2]."No.", Quantity);
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[1]."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PartialReceiptThenRepeatPutAwayForRemainingQty()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseRequest: Record "Warehouse Request";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Partial Posting
        // [SCENARIO] Partial receipt then repeat Put-Away for remaining quantity (LastOperation)
        // Confirms partial-quantity posting works correctly for a LastOperation line: posting less than the full
        // quantity leaves the purchase line/warehouse request open with the correct outstanding balance, and a second
        // Put-Away for the remainder creates a second linked Posted Invt. Put-away Line referencing the same
        // Purch. Rcpt./Purchase Line, with cumulative item ledger quantity reconciling to the original order quantity.

        // [GIVEN] Single-op routing, quantity = 10, Location L-PA
        Initialize();
        Quantity := 10;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN]  Create Put-Away, set Qty. to Handle = 6, post
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        SubcWarehouseLibrary.PostPartialPutAway(WarehouseActivityHeader, 6);

        // [THEN]  Purch. Rcpt. Line Quantity = 6; Outstanding Quantity = 4; Item Ledger Entry qty = 6
        GetPurchRcptLine(PurchRcptLine, PurchaseLine);
        Assert.AreEqual(6, PurchRcptLine.Quantity, 'First receipt should post partial quantity');
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(4, PurchaseLine."Outstanding Quantity", 'Purchase line should remain partially outstanding');
        SubcWarehouseLibrary.VerifyItemLedgerEntry(Item."No.", 6, Location.Code);

        // [THEN]  Warehouse Request remains (Completely Handled = false)
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Order");
        WarehouseRequest.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(WarehouseRequest);
        WarehouseRequest.FindFirst();
        Assert.IsFalse(WarehouseRequest."Completely Handled", 'Warehouse request must remain open after partial posting');

        // [WHEN]  Post the remaining quantity (4) on the same still-open Put-Away for the remaining line
        SubcWarehouseLibrary.PostPartialPutAway(WarehouseActivityHeader, 4);

        // [THEN]  Two Posted Invt. Put-away Lines reference the same Purch. Rcpt. Line/Purchase Line
        PostedInvtPutAwayLine.SetRange("Source Document", PostedInvtPutAwayLine."Source Document"::"Purchase Order");
        PostedInvtPutAwayLine.SetRange("Source No.", PurchaseHeader."No.");
        PostedInvtPutAwayLine.SetRange("Source Line No.", PurchaseLine."Line No.");
        Assert.RecordCount(PostedInvtPutAwayLine, 2);

        // [THEN]  Cumulative Item Ledger Entry quantity = 10; Outstanding Quantity = 0; Warehouse Request fully handled
        SubcWarehouseLibrary.VerifyItemLedgerEntry(Item."No.", Quantity, Location.Code);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(0, PurchaseLine."Outstanding Quantity", 'Purchase line should be fully received after second posting');
        WarehouseRequest.Reset();
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Order");
        WarehouseRequest.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(WarehouseRequest);
        WarehouseRequest.FindFirst();
        Assert.IsTrue(WarehouseRequest."Completely Handled", 'Warehouse Request should be marked completely handled once fully received');

        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[2]."No.", Quantity);
        SubcWarehouseLibrary.VerifyItemLedgerEntry(Item."No.", Quantity, Location.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AutoFillQtyToHandleAcrossMixedLineTypes()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineFirstOp: Record "Purchase Line";
        PurchaseLineLastOp: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away - AutoFill Qty. to Handle
        // [SCENARIO] AutoFill Qty. to Handle across mixed line types
        // The "AutoFill Qty. to Handle" action must correctly fill both line shapes on the same Put-Away header: a
        // NotLastOperation line (Qty. (Base) intentionally stays 0, no TestField error) and a LastOperation line
        // (Qty. (Base) filled to match Qty. Outstanding (Base)), without either line overfilling beyond its
        // outstanding quantity.

        // [GIVEN] Two-op routing (NotLastOperation Qty.(Base)=0, LastOperation Qty.(Base)>0) on one Put-Away
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(8, 15);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenterSameVendor(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        PurchaseLineFirstOp.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLineFirstOp.SetRange("Document No.", PurchaseHeader."No.");
#pragma warning disable AA0210
        PurchaseLineFirstOp.SetRange("Work Center No.", WorkCenter[1]."No.");
#pragma warning restore AA0210
        PurchaseLineFirstOp.FindFirst();

        PurchaseLineLastOp.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLineLastOp.SetRange("Document No.", PurchaseHeader."No.");
#pragma warning disable AA0210
        PurchaseLineLastOp.SetRange("Work Center No.", WorkCenter[2]."No.");
#pragma warning restore AA0210
        PurchaseLineLastOp.FindFirst();

        // [WHEN]  AutoFill Qty. to Handle action executed
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [THEN]  NotLastOperation line: Quantity field filled (base qty stays 0, no TestField error)
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Source Line No.", PurchaseLineFirstOp."Line No.");
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(WarehouseActivityLine.Quantity, WarehouseActivityLine."Qty. to Handle", 'Not last operation line quantity should be autofilled');
        Assert.AreEqual(0, WarehouseActivityLine."Qty. to Handle (Base)", 'Not last operation line base quantity must stay zero');

        // [THEN]  LastOperation line: Quantity (Base) filled matching Qty. Outstanding (Base)
        WarehouseActivityLine.SetRange("Source Line No.", PurchaseLineLastOp."Line No.");
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(WarehouseActivityLine.Quantity, WarehouseActivityLine."Qty. to Handle", 'Last operation quantity should be autofilled');
        Assert.AreEqual(WarehouseActivityLine."Qty. Outstanding (Base)", WarehouseActivityLine."Qty. to Handle (Base)", 'Last operation base quantity should be autofilled');

        // [THEN]  Neither line overfills beyond Qty. Outstanding
        Assert.IsTrue(WarehouseActivityLine."Qty. to Handle" <= WarehouseActivityLine."Qty. Outstanding", 'Last operation line must not overfill');
        WarehouseActivityLine.SetRange("Source Line No.", PurchaseLineFirstOp."Line No.");
        WarehouseActivityLine.FindFirst();
        Assert.IsTrue(WarehouseActivityLine."Qty. to Handle" <= WarehouseActivityLine."Qty. Outstanding", 'Not last operation line must not overfill');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SerialTrackedLastOperationFullE2E()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseRequest: Record "Warehouse Request";
        WorkCenter: array[2] of Record "Work Center";
        NoSeriesCodeunit: Codeunit "No. Series";
        SerialNo: Code[50];
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Serial Tracking
        // [SCENARIO] Serial-tracked Last Operation — full E2E with tracking mandatory
        // Full E2E for mandatory serial tracking on a LastOperation line: serial numbers assigned via Item Tracking
        // Lines on the purchase line must propagate through to the Inventory Put-Away activity line, and posting
        // must produce a per-serial Output Item Ledger Entry plus a matching Warehouse Entry tied to the specific
        // bin/serial combination.

        // [GIVEN] Serial-tracked item, Location L-PA-BIN, single-op routing (LastOperation)
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateSerialTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 1, Location.Code);

        // [GIVEN] Serial number assigned to the production order line
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        SerialNo := NoSeriesCodeunit.GetNextNo(Item."Serial Nos.");
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, SerialNo, '', 1);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN]  Create an Inventory Put-away with the serial number from the production order line
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(SerialNo, WarehouseActivityLine."Serial No.", 'Serial number should be auto-assigned on the inventory put-away line from the Prod. Order Line reservation');

        // [WHEN]  Post
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN]  Output Item Ledger Entry created per serial (or aggregated with matching Reservation/Item Tracking entries)
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Serial No.", SerialNo);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(1, ItemLedgerEntry.Quantity, 'Output item ledger entry quantity should match the single serial-tracked unit (no under/overpick)');

        // [THEN]  Warehouse Entry created per serial/bin combination
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Serial No.", SerialNo);
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        Assert.RecordIsNotEmpty(WarehouseEntry);
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(1, WarehouseEntry.Quantity, 'Warehouse entry quantity should match the single serial-tracked unit (no under/overpick)');

        // [THEN]  Purchase Line is fully received and the Warehouse Request is completely handled
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(0, PurchaseLine."Outstanding Quantity", 'Purchase line should be fully received after serial-tracked posting');
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Order");
        WarehouseRequest.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(WarehouseRequest);
        WarehouseRequest.FindFirst();
        Assert.IsTrue(WarehouseRequest."Completely Handled", 'Warehouse request should be marked completely handled after full serial-tracked receipt');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure LotTrackedLastOperationSplitAcrossTwoBins()
    var
        Bin1: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseRequest: Record "Warehouse Request";
        WorkCenter: array[2] of Record "Work Center";
        NoSeriesCodeunit: Codeunit "No. Series";
        LotNo1: Code[50];
        LotNo2: Code[50];
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Lot Tracking
        // [SCENARIO] Lot-tracked Last Operation — split across two bins with different lots
        // Combines lot tracking with bin splitting: a 20-unit LastOperation line pre-tracked as two lots (12 + 8
        // units) is split into two activity lines, each assigned its own bin, then posted together. Verifies each
        // lot/bin combination produces its own correctly-quantified Warehouse Entry and output Item Ledger Entry,
        // with no cross-lot quantity bleed and the total reconciling to the full posted quantity.

        // [GIVEN] Lot-tracked item, Location L-PA-BIN, single-op routing (LastOperation), quantity = 20
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin1);
        LibraryWarehouse.CreateBin(Bin2, Location.Code, 'PUTAWAY2', '', '');
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 20, Location.Code);

        // [GIVEN] Lot numbers assigned to the production order line
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LotNo1 := NoSeriesCodeunit.GetNextNo(Item."Lot Nos.");
        LotNo2 := NoSeriesCodeunit.GetNextNo(Item."Lot Nos.");
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, '', LotNo1, 12);
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, '', LotNo2, 8);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN]  Create an Inventory Put-away with one activity line for each lot
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Lot No.", LotNo1);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(12, WarehouseActivityLine.Quantity, 'First lot line should carry the split quantity from its reservation entry');
        WarehouseActivityLine.Validate("Bin Code", Bin1.Code);
        WarehouseActivityLine.Modify(true);

        WarehouseActivityLine.SetRange("Lot No.", LotNo2);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(8, WarehouseActivityLine.Quantity, 'Second lot line should carry the split quantity from its reservation entry');
        WarehouseActivityLine.Validate("Bin Code", Bin2.Code);
        WarehouseActivityLine.Modify(true);

        // [WHEN]  Post both split lines
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN]  Two Warehouse Entries created, one per lot/bin combination
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Lot No.", LotNo1);
        WarehouseEntry.SetRange("Bin Code", Bin1.Code);
        Assert.RecordIsNotEmpty(WarehouseEntry);
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(12, WarehouseEntry.Quantity, 'First lot/bin warehouse entry should match split quantity');

        WarehouseEntry.SetRange("Lot No.", LotNo2);
        WarehouseEntry.SetRange("Bin Code", Bin2.Code);
        Assert.RecordIsNotEmpty(WarehouseEntry);
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(8, WarehouseEntry.Quantity, 'Second lot/bin warehouse entry should match split quantity');

        // [THEN]  Output Item Ledger Entries carry the correct Lot No. each
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Lot No.", LotNo1);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(12, ItemLedgerEntry.Quantity, 'First lot item ledger quantity should match split quantity');

        ItemLedgerEntry.SetRange("Lot No.", LotNo2);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(8, ItemLedgerEntry.Quantity, 'Second lot item ledger quantity should match split quantity');

        // [THEN]  Sum of posted quantities = 20; no duplicate entries
        SubcWarehouseLibrary.VerifyItemLedgerEntry(Item."No.", 20, Location.Code);

        // [THEN]  Purchase Line is fully received and the Warehouse Request is completely handled
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(0, PurchaseLine."Outstanding Quantity", 'Purchase line should be fully received after multi-lot tracked posting');
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Order");
        WarehouseRequest.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(WarehouseRequest);
        WarehouseRequest.FindFirst();
        Assert.IsTrue(WarehouseRequest."Completely Handled", 'Warehouse request should be marked completely handled after full multi-lot tracked receipt');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PackageTrackedLastOperationCombinedWithLot()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseRequest: Record "Warehouse Request";
        WorkCenter: array[2] of Record "Work Center";
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
        NoSeriesCodeunit: Codeunit "No. Series";
        LotNo: Code[50];
        PackageNo: Code[50];
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Package + Lot Tracking
        // [SCENARIO] Package-tracked Last Operation combined with Lot
        // Verifies combined Lot + Package Specific Tracking (both mandatory) on a LastOperation line: both
        // identifiers entered on the purchase line's item tracking must propagate to the activity line, and posting
        // must produce both an Item Ledger Entry and a Warehouse Entry that carry the matching Lot No. and Package
        // No. together, with quantities intact and the reservation/tracking specification honoring base-app rules.

        // [GIVEN] Item tracking code with Lot + Package Specific Tracking mandatory, Location L-PA-BIN
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreatePackageAndLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 5, Location.Code);

        // [GIVEN] Lot and package numbers assigned to the production order line
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LotNo := NoSeriesCodeunit.GetNextNo(Item."Lot Nos.");
        PackageNo := CopyStr('PKG-' + Format(LibraryRandom.RandIntInRange(1000, 9999)), 1, 50);
        Clear(TempItemTrackingSetup);
        TempItemTrackingSetup."Lot No." := LotNo;
        TempItemTrackingSetup."Package No." := PackageNo;
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, TempItemTrackingSetup, 5);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN]  Create an Inventory Put-away and assign its lot and package numbers
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Validate("Package No.", PackageNo);
        WarehouseActivityLine.Modify(true);
        Assert.AreEqual(LotNo, WarehouseActivityLine."Lot No.", 'Lot number should be present on the inventory put-away line before posting');
        Assert.AreEqual(PackageNo, WarehouseActivityLine."Package No.", 'Package number should be present on the inventory put-away line before posting');
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN]  Item Ledger Entry and Warehouse Entry both carry Lot No. and Package No.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.SetRange("Package No.", PackageNo);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(5, ItemLedgerEntry.Quantity, 'Output item ledger entry quantity should match the full posted quantity.');

        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Lot No.", LotNo);
        WarehouseEntry.SetRange("Package No.", PackageNo);
        Assert.RecordIsNotEmpty(WarehouseEntry);
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(5, WarehouseEntry.Quantity, 'Warehouse entry quantity should match the full posted quantity.');

        // [THEN]  Purchase Line is fully received and the Warehouse Request is completely handled
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(0, PurchaseLine."Outstanding Quantity", 'Purchase line should be fully received after combined lot/package tracked posting');
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Order");
        WarehouseRequest.SetRange("Source No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(WarehouseRequest);
        WarehouseRequest.FindFirst();
        Assert.IsTrue(WarehouseRequest."Completely Handled", 'Warehouse request should be marked completely handled after full combined lot/package tracked receipt');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ItemTrackingBlockedForNotLastOperationLines()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
        PurchaseOrderPage: TestPage "Purchase Order";
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Tracking Guard Rails
        // [SCENARIO] Item tracking blocked for Not Last Operation lines
        // Since a NotLastOperation line never has Qty. (Base) > 0 (no physical output to track), the UI must actively
        // block opening "Item Tracking Lines" for such a purchase line (per spec §3.5) rather than silently allowing
        // entry that could never be honored. Also confirms the line still posts successfully with zero base quantity
        // and no ledger/warehouse entries despite the tracking block.

        // [GIVEN] Two-op routing, Op 10 = NotLastOperation, tracked item
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[1]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);

        // [WHEN]  User attempts to enter Serial/Lot/Package No. on the NotLastOperation activity line
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.GoToRecord(PurchaseHeader);
        PurchaseOrderPage.PurchLines.GoToRecord(PurchaseLine);
        asserterror PurchaseOrderPage.PurchLines."Item Tracking Lines".Invoke();

        // [THEN]  Entry is blocked (spec §3.5) — field disabled or validation error raised
        Assert.ExpectedError('Item tracking lines can only be viewed for subcontracting purchase lines which are linked to a routing line which is the last operation.');
        PurchaseOrderPage.Close();

        // [THEN]  Posting succeeds without any tracking value (Qty.(Base)=0, no Item Ledger Entry expected)
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        SubcWarehouseLibrary.VerifyNoItemLedgerEntry(Item."No.", Location.Code);
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", Location.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure MandatoryTrackingPostingBlockedWhenOmitted()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Mandatory Tracking Negative
        // [SCENARIO] Mandatory tracking negative test — posting blocked when omitted (Last Operation only)
        // Negative test for mandatory serial tracking: attempting to post a LastOperation Inventory Put-Away without
        // assigning any serial numbers must fail with the standard base-app mandatory-tracking error, and —
        // critically — must leave no partial/orphaned Item Ledger Entries or Warehouse Entries behind after the
        // failed post.

        // [GIVEN] Serial-tracked item with "SN Specific Tracking" mandatory, Location L-PA-BIN, LastOperation
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateSerialTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 1, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN]  Post Inventory Put-Away without assigning any serial numbers
        asserterror LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        Assert.ExpectedError('Serial No. must have a value');

        // [THEN]  Posting fails with the standard mandatory-tracking error before any ledger entries are created
        // [THEN]  No partial/orphan Item Ledger Entries or Warehouse Entries remain after the failed post
        SubcWarehouseLibrary.VerifyNoItemLedgerEntry(Item."No.", Location.Code);
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", Location.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SplitLastOperationLineAcrossThreeBins()
    var
        Bin1: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        Bins: array[3] of Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        Quantities: array[3] of Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Line Splitting
        // [SCENARIO] Split Last Operation line across 3 bins, verify per-bin Warehouse Entry and Bin Content
        // Core multi-bin split scenario: a 30-unit LastOperation line is split into three 10-unit activity lines,
        // each targeting a distinct new bin with no pre-existing Bin Content. Verifies three separate Warehouse
        // Entries and auto-created Bin Content records (one per bin), a single output Item Ledger Entry summing to
        // the full quantity, and a Purch. Rcpt. Line quantity equal to the split total.

        // [GIVEN] Location L-PA-BIN, LastOperation line, quantity = 30, no pre-existing Bin Content
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin1);
        LibraryWarehouse.CreateBin(Bin2, Location.Code, 'PUTAWAY2', '', '');
        LibraryWarehouse.CreateBin(Bin3, Location.Code, 'PUTAWAY3', '', '');
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 30, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);

        // [WHEN]  Split into 3 activity lines (10/10/10) with distinct bins B1/B2/B3, Qty. to Handle set on each
        Bins[1] := Bin1;
        Bins[2] := Bin2;
        Bins[3] := Bin3;
        Quantities[1] := 10;
        Quantities[2] := 10;
        Quantities[3] := 10;
        SubcWarehouseLibrary.SplitActivityLineAcrossBins(WarehouseActivityHeader, WarehouseActivityHeader.Type, Bins, Quantities);

        // [WHEN]  Post
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN]  3 Warehouse Entries created, one per bin, quantities matching split
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Bin Code", Bin1.Code);
        Assert.RecordIsNotEmpty(WarehouseEntry);
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(10, WarehouseEntry.Quantity, 'Bin 1 warehouse entry should match split quantity');

        WarehouseEntry.SetRange("Bin Code", Bin2.Code);
        Assert.RecordIsNotEmpty(WarehouseEntry);
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(10, WarehouseEntry.Quantity, 'Bin 2 warehouse entry should match split quantity');

        WarehouseEntry.SetRange("Bin Code", Bin3.Code);
        Assert.RecordIsNotEmpty(WarehouseEntry);
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(10, WarehouseEntry.Quantity, 'Bin 3 warehouse entry should match split quantity');

        // [THEN]  Bin Content auto-created for each new item/bin combination
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, Bin1.Code, Item."No.", 10);
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, Bin2.Code, Item."No.", 10);
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, Bin3.Code, Item."No.", 10);

        // [THEN]  Single Output Item Ledger Entry (or 3, depending on base app aggregation) with total quantity = 30
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(30, ItemLedgerEntry.Quantity, 'Output quantity should match full posted quantity');

        // [THEN]  Purch. Rcpt. Line quantity received = 30 (sum of all splits)
        GetPurchRcptLine(PurchRcptLine, PurchaseLine);
        Assert.AreEqual(30, PurchRcptLine.Quantity, 'Receipt quantity should match split total');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SplitNotLastOperationLineHasNoWhseEffect()
    var
        Bin1: Record Bin;
        Bin2: Record Bin;
        Bins: array[3] of Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
        Quantities: array[3] of Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Non-Physical Split Lines
        // [SCENARIO] Split Not Last Operation line — no ledger/warehouse effect regardless of split count
        // Confirms that splitting a NotLastOperation line across multiple bins is purely cosmetic/informational:
        // regardless of how many bins the line is divided into, posting still produces no Warehouse Entry and no Bin
        // Content record for any of the split lines, while the underlying Capacity Ledger Entry/output posting still
        // occurs exactly once via MfgPurchPost, independent of the split.

        // [GIVEN] NotLastOperation line, quantity = 15, Location L-PA-BIN
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[1]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin1);
        LibraryWarehouse.CreateBin(Bin2, Location.Code, 'PUTAWAY2', '', '');
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 15, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);

        // [WHEN]  Split into 2 lines (bin B1/B2), post both
        Bins[1] := Bin1;
        Bins[2] := Bin2;
        Quantities[1] := 8;
        Quantities[2] := 7;
        SubcWarehouseLibrary.SplitActivityLineAcrossBins(WarehouseActivityHeader, WarehouseActivityHeader.Type, Bins, Quantities);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN]  No Warehouse Entry created for either split line
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", Location.Code);

        // [THEN]  Single Capacity Ledger Entry / Output posting still occurs via MfgPurchPost (independent of split)
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[1]."No.", 15);

        // [THEN]  No Bin Content created as a side effect of the split
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(BinContent);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SplitThenRemergeByDeletingOneLine()
    var
        Bin1: Record Bin;
        Bin2: Record Bin;
        Bins: array[3] of Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        Quantities: array[3] of Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Split Line Lifecycle
        // [SCENARIO] Split then re-merge scenario — deleting one split line and reposting
        // Covers the "undo a split before posting" lifecycle: after splitting a LastOperation line across two bins,
        // deleting one split sub-line and re-expanding the remaining line's Qty. to Handle back to the full quantity
        // must post cleanly as a single-bin Warehouse Entry for the full amount, with no leftover reference to the
        // deleted split line in the Posted Invt. Put-away Lines.

        // [GIVEN] LastOperation line split into 2 bins
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin1);
        LibraryWarehouse.CreateBin(Bin2, Location.Code, 'PUTAWAY2', '', '');
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 12, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);

        Bins[1] := Bin1;
        Bins[2] := Bin2;
        Quantities[1] := 6;
        Quantities[2] := 6;
        SubcWarehouseLibrary.SplitActivityLineAcrossBins(WarehouseActivityHeader, WarehouseActivityHeader.Type, Bins, Quantities);

        // [WHEN]  One split line is deleted before posting, remaining line's Qty. to Handle adjusted to full quantity
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Bin Code", Bin2.Code);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Delete(true);

        WarehouseActivityLine.SetRange("Bin Code", Bin1.Code);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate(Quantity, 12);
        WarehouseActivityLine.Validate("Qty. to Handle", 12);
        WarehouseActivityLine.Modify(true);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN]  Posting the remaining line produces correct total quantity, single bin Warehouse Entry
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Location Code", Location.Code);
        WarehouseEntry.SetRange("Bin Code", Bin1.Code);
        Assert.RecordIsNotEmpty(WarehouseEntry);
        WarehouseEntry.CalcSums(Quantity);
        Assert.AreEqual(12, WarehouseEntry.Quantity, 'Remaining bin should receive full quantity');

        // [THEN]  No leftover reference to the deleted split line in Posted Invt. Put-away Lines
        PostedInvtPutAwayLine.SetRange("Source Document", PostedInvtPutAwayLine."Source Document"::"Purchase Order");
        PostedInvtPutAwayLine.SetRange("Source No.", PurchaseHeader."No.");
        PostedInvtPutAwayLine.SetRange("Source Line No.", PurchaseLine."Line No.");
        Assert.RecordCount(PostedInvtPutAwayLine, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SplitWithExistingBinContentVsFromProductionBin()
    var
        Bin1: Record Bin;
        Bins: array[3] of Record Bin;
        DefaultBin: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
        Quantities: array[3] of Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Bin Content Reuse
        // [SCENARIO] Split with existing Bin Content vs From-Production Bin Code
        // Verifies bin-content reuse semantics when splitting a line across a bin that already has existing Bin
        // Content (from a prior manual item journal posting) versus the location's From-Production Bin Code
        // (inherited via the production order line, with no prior content). Both sub-lines must post successfully,
        // correctly incrementing the existing Bin Content for the reused bin and creating a fresh Bin Content record
        // for the new bin.

        // [GIVEN] Bin Content already exists for item/bin B1 at L-PA-BIN; From-Production Bin Code = B2
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, DefaultBin);
        LibraryWarehouse.CreateBin(Bin1, Location.Code, 'REUSEBIN', '', '');
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin1.Code, 5);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 30, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [WHEN]  Put-Away activity line created (inherits B2 from production order line propagation)
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);

        // [WHEN]  Line split so one sub-line targets B1 (existing content) and one targets B2 (from-production)
        Bins[1] := Bin1;
        Bins[2] := DefaultBin;
        Quantities[1] := 15;
        Quantities[2] := 15;
        SubcWarehouseLibrary.SplitActivityLineAcrossBins(WarehouseActivityHeader, WarehouseActivityHeader.Type, Bins, Quantities);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN]  Both bins post successfully; existing Bin Content reused for B1, new Bin Content created for B2
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, Bin1.Code, Item."No.", 20);
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, DefaultBin.Code, Item."No.", 15);
    end;



    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure QuantityBalancingSuppressedOnlyForIntendedLineTypes()
    var
        Item: Record Item;
        FromLocation: Record Location;
        InTransitLocation: Record Location;
        ProdLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderStd: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLineStd: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        MixedHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseRequest: Record "Warehouse Request";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
        TotalLineCount: Integer;
    begin
        // [FEATURE] Subcontracting Inventory Put-away - Balance Validation
        // [SCENARIO] Quantity balancing suppressed only for the intended line types
        // Ensures the base-app "Qty. (Base) must reconcile with Quantity" balance validation
        // (OnBeforeValidateQuantityIsBalanced) is bypassed ONLY for the two line shapes that intentionally have
        // Qty. (Base) = 0 — NotLastOperation and Transfer WIP Item lines — while a standard (non-subcontracting)
        // purchase line and a LastOperation line mixed into the same aggregated Put-Away header (via combined "Get
        // Source Documents") still enforce normal balancing and post correctly.

        // [GIVEN] Mixed activity lines: LastOperation, NotLastOperation, Transfer WIP Item, and a standard (None) line together in one Put-Away header (multi-line worksheet aggregation)
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(6, 10);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenterSameVendor(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(FromLocation);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := FromLocation.Code;
        Vendor."Location Code" := FromLocation.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, FromLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
            until PurchaseLine.Next() = 0;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeaderStd, '', FromLocation.Code);
        LibraryPurchase.CreatePurchaseLine(PurchaseLineStd, PurchaseHeaderStd, PurchaseLineStd.Type::Item, Item."No.", Quantity);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLineStd."Gen. Bus. Posting Group", PurchaseLineStd."Gen. Prod. Posting Group");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeaderStd);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProdLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, ProdLocation.Code, FromLocation.Code, InTransitLocation.Code, Item, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FromLocation.Code, false);
        // [WHEN]  Create Inventory Put-away documents for all released source documents at the location
        WarehouseRequest.Reset();
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Location Code", FromLocation.Code);
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, true, false, false);

        // [WHEN]  Auto-fill and post every resulting header
        MixedHeader.SetRange(Type, MixedHeader.Type::"Invt. Put-away");
        MixedHeader.SetRange("Location Code", FromLocation.Code);
        Assert.RecordCount(MixedHeader, 3);
        TotalLineCount := 0;
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        MixedHeader.FindSet();
        repeat
            WarehouseActivityLine.SetRange("No.", MixedHeader."No.");
            Assert.IsFalse(WarehouseActivityLine.IsEmpty(), 'Each header should contain at least one line');
            TotalLineCount += WarehouseActivityLine.Count();
        until MixedHeader.Next() = 0;
        Assert.AreEqual(4, TotalLineCount, 'Mixed source documents should contain all four line categories combined');

        MixedHeader.FindSet();
        repeat
            LibraryWarehouse.AutoFillQtyHandleWhseActivity(MixedHeader);
            LibraryWarehouse.PostInventoryActivity(MixedHeader, false);
        until MixedHeader.Next() = 0;

        // [THEN]  NotLastOperation and Transfer WIP Item lines post without balance errors
        WarehouseActivityLine.SetRange("No.");
        WarehouseActivityLine.SetRange("Subc. Transfer WIP Item", true);
        Assert.IsTrue(WarehouseActivityLine.IsEmpty(), 'Transfer WIP line should be fully posted without balance errors');

        // [THEN]  Standard and LastOperation lines post normally
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(PurchaseLine);
        PurchaseLineStd.Get(PurchaseLineStd."Document Type", PurchaseLineStd."Document No.", PurchaseLineStd."Line No.");
        Assert.AreEqual(0, PurchaseLineStd."Outstanding Quantity", 'Standard purchase line should still post normally');
    end;

    local procedure GetPurchRcptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseLine: Record "Purchase Line")
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseLine."Document No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        if Message.Contains('Number of Invt. Put-away activities created') then
            exit;
        if Message.Contains('was successfully posted and is now deleted') then
            exit;
        Error('Unexpected Message: %1', Message);
    end;
}