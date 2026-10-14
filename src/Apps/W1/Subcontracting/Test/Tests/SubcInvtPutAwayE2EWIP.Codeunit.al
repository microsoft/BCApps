// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;
using System.Environment.Configuration;

codeunit 149920 "Subc. Invt. Put-away E2E WIP"
{
    // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP Tests
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcLibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        BeforeNewWhseActivLineInsertForWipCalled: Boolean;
        AfterSetLineDataForWipCalled: Boolean;
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Invt. Put-away E2E WIP");
        LibrarySetupStorage.Restore();
        LibraryApplicationArea.EnablePremiumSetup();
        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Invt. Put-away E2E WIP");

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Invt. Put-away E2E WIP");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", OnBeforeNewWhseActivLineInsert, '', false, false)]
    local procedure SetBeforeNewWhseActivLineInsertForWipCalled(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location)
    begin
        if WarehouseActivityLine."Subc. Transfer WIP Item" then
            BeforeNewWhseActivLineInsertForWipCalled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", OnAfterSetLineData, '', false, false)]
    local procedure SetAfterSetLineDataForWipCalled(WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        if WarehouseActivityLine."Subc. Transfer WIP Item" then
            AfterSetLineDataForWipCalled := true;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleSubcTransferOrderPage')]
    procedure FullWIPRoundTripForwardPickReturnPutAway()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        InTransitLocation: Record Location;
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        ForwardTransferHeader: Record "Transfer Header";
        ReturnTransferHeader: Record "Transfer Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
        ItemLedgerEntryCountBefore: Integer;
        WarehouseEntryCountBefore: Integer;
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-B01 A full WIP round trip posts transfer and WIP entries without physical stock movement.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Routing line Transfer WIP Item = true, Location L-PROD (production) / L-PICK (subcontractor)
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(ProductionLocation);
        ProductionLocation."Require Pick" := true;
        ProductionLocation.Modify(true);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProductionLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        // [GIVEN] Production Order released; subcontracting purchase order + forward transfer order created
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] Inventory Pick created and posted at L-PROD for the forward transfer (shipping) line
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [WHEN] Receipt leg posted directly at the subcontractor's (non-warehouse-managed) location
        LibraryWarehouse.PostTransferOrder(ForwardTransferHeader, false, true);

        // [THEN] Transfer Shipment Header/Line created; Posted Inventory Pick created
        TransferShipmentHeader.SetRange("Transfer Order No.", ForwardTransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferShipmentHeader);

        // [THEN] No Item Ledger Entry or Warehouse Entry is created; a WIP Ledger Entry is created at the subcontractor location.
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'Forward WIP pick must not create item ledger entries.');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'Forward WIP pick must not create warehouse entries.');
        WIPLedgerEntry.SetRange("Prod. Order Status", ProductionOrder.Status);
        WIPLedgerEntry.SetRange("Prod. Order No.", ProductionOrder."No.");
        WIPLedgerEntry.SetRange("Location Code", Vendor."Subc. Location Code");
        Assert.RecordIsNotEmpty(WIPLedgerEntry);
        WIPLedgerEntry.CalcSums("Quantity (Base)");
        Assert.AreEqual(Quantity, Abs(WIPLedgerEntry."Quantity (Base)"), 'Forward WIP pick should move exactly the shipped quantity into WIP on the subcontractor side.');

        // [WHEN] Return transfer order (Subc. Return Order) released; Inventory Put-Away created and posted at L-PROD
        SubcWarehouseLibrary.CreateReturnTransferWithSubcContext(
            PurchaseHeader, PurchaseLine,
            Vendor."Subc. Location Code", ProductionLocation.Code, InTransitLocation.Code,
            Quantity, ReturnTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ReturnTransferHeader);
        LibraryWarehouse.PostTransferOrder(ReturnTransferHeader, true, false);
        SubcWarehouseLibrary.CreateInvtPutAwayFromTransferOrder(ReturnTransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Transfer Receipt Header/Line created; Posted Invt. Put-away created
        TransferReceiptHeader.SetRange("Transfer Order No.", ReturnTransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferReceiptHeader);
        Assert.AreNotEqual(0, SubcWarehouseLibrary.GetPostedInvtPutAwayLineCountForTransferOrder(ReturnTransferHeader."No."),
            'Return WIP receipt must create posted inventory put-away lines.');

        // [THEN] No Item Ledger Entry created; no Warehouse Entry created
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'Return WIP put-away must not create item ledger entries.');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'Return WIP put-away must not create warehouse entries.');

        // [THEN] Transfer order deleted after full receipt (both forward and return, once fully handled)
        Assert.IsFalse(ReturnTransferHeader.Get(ReturnTransferHeader."No."), 'Return transfer order must be deleted after full receipt.');

        // [THEN] No WIP Ledger Entry is created at the production location.
        WIPLedgerEntry.Reset();
        WIPLedgerEntry.SetRange("Prod. Order Status", ProductionOrder.Status);
        WIPLedgerEntry.SetRange("Prod. Order No.", ProductionOrder."No.");
        WIPLedgerEntry.SetRange("Location Code", ProductionLocation.Code);
        Assert.RecordIsEmpty(WIPLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleSubcTransferOrderPage')]
    procedure TrackedWipTransferPickSkipsRequiredTracking()
    var
        BinContent: Record "Bin Content";
        PickBin: Record Bin;
        Item: Record Item;
        InTransitLocation: Record Location;
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ForwardTransferHeader: Record "Transfer Header";
        ReturnTransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        TempWhseItemTrackingSetup: Record "Item Tracking Setup" temporary;
        WorkCenter: array[2] of Record "Work Center";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        Quantity: Decimal;
    begin
        // [SCENARIO] TC-E2E-B04 A WIP inventory pick posts without a required lot number.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] A lot-tracked WIP transfer item and a bin-mandatory production location requiring inventory picks.
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(ProductionLocation, PickBin);
        ProductionLocation."Require Pick" := true;
        ProductionLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ProductionLocation.Code, true);
        LibraryWarehouse.CreateBinContent(
            BinContent, ProductionLocation.Code, '', ProductionLocation."Default Bin Code", Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        ItemTrackingMgt.GetWhseItemTrkgSetup(Item."No.", TempWhseItemTrackingSetup);
        Assert.IsTrue(TempWhseItemTrackingSetup."Lot No. Required", 'The test item must require lot tracking in warehouse activities.');

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProductionLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);

        // [WHEN] A WIP inventory pick with no lot number is posted.
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        Assert.IsTrue(WarehouseActivityLine."Subc. Transfer WIP Item", 'The inventory pick line must be a WIP transfer line.');
        Assert.AreEqual('', WarehouseActivityLine."Lot No.", 'No lot number should be assigned to a WIP inventory pick line.');
        WarehouseActivityLine.Validate("Bin Code", '');
        WarehouseActivityLine.Modify(true);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Posting succeeds even though standard tracking and bin checks would require a lot number and bin code.
        TransferShipmentHeader.SetRange("Transfer Order No.", ForwardTransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferShipmentHeader);

        // [WHEN] The tracked WIP item returns through an inventory put-away with no lot number or bin code.
        LibraryWarehouse.PostTransferOrder(ForwardTransferHeader, false, true);
        SubcWarehouseLibrary.CreateReturnTransferWithSubcContext(
            PurchaseHeader, PurchaseLine,
            Vendor."Subc. Location Code", ProductionLocation.Code, InTransitLocation.Code,
            Quantity, ReturnTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ReturnTransferHeader);
        LibraryWarehouse.PostTransferOrder(ReturnTransferHeader, true, false);
        SubcWarehouseLibrary.CreateInvtPutAwayFromTransferOrder(ReturnTransferHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        Assert.IsTrue(WarehouseActivityLine."Subc. Transfer WIP Item", 'The inventory put-away line must be a WIP transfer line.');
        Assert.AreEqual('', WarehouseActivityLine."Lot No.", 'No lot number should be assigned to a WIP inventory put-away line.');
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] The return put-away also posts without tracking validation.
        Assert.AreNotEqual(0, SubcWarehouseLibrary.GetPostedInvtPutAwayLineCountForTransferOrder(ReturnTransferHeader."No."),
            'The tracked WIP return must create a posted inventory put-away line.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleSubcTransferOrderPage')]
    procedure WipTransferInventoryPickCreationAllowsBlankBinWithAccordingToBin()
    var
        Bin: Record Bin;
        Item: Record Item;
        InTransitLocation: Record Location;
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        ForwardTransferHeader: Record "Transfer Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [SCENARIO TP-001] A WIP Inventory Pick is created with a blank bin when Special Equipment is According to Bin.
        Initialize();
        BeforeNewWhseActivLineInsertForWipCalled := false;
        AfterSetLineDataForWipCalled := false;
        Quantity := 7;

        // [GIVEN] Bin-mandatory production location with Require Pick and According to Bin setup, but no default bin.
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ProductionLocation);
        ProductionLocation."Require Pick" := true;
        ProductionLocation."Special Equipment" := ProductionLocation."Special Equipment"::"According to Bin";
        ProductionLocation.Modify(true);
        LibraryWarehouse.CreateBin(Bin, ProductionLocation.Code, 'PICK', '', '');
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ProductionLocation.Code, true);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProductionLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        // [GIVEN] Released production order, subcontracting purchase order, and WIP transfer with no source bin.
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);

        TransferLine.SetRange("Document No.", ForwardTransferHeader."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.FindFirst();
        TransferLine.Validate("Transfer-from Bin Code", '');
        TransferLine.Modify(true);

        // [WHEN] An Inventory Pick is created for the released WIP transfer.
        BindSubscription(this);
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);
        UnbindSubscription(this);

        // [THEN] Creation succeeds with one WIP activity line and no prefilled bin or Special Equipment Code.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        Assert.IsTrue(WarehouseActivityLine."Subc. Transfer WIP Item", 'The activity line must be marked as a WIP transfer line.');
        Assert.AreEqual("Subc. Purchase Line Type"::None, WarehouseActivityLine."Subc. Purchase Line Type", 'A transfer WIP line must not have a purchase line type.');
        Assert.AreEqual('', WarehouseActivityLine."Bin Code", 'The WIP activity line must keep its bin code blank.');
        Assert.AreEqual('', WarehouseActivityLine."Special Equipment Code", 'A blank WIP bin must not require special equipment.');
        Assert.AreEqual(Quantity, WarehouseActivityLine.Quantity, 'The WIP activity line must retain the transfer quantity.');
        Assert.AreEqual(0, WarehouseActivityLine."Qty. (Base)", 'The WIP activity line must retain zero base quantity semantics.');
        Assert.IsTrue(BeforeNewWhseActivLineInsertForWipCalled, 'The standard before-insert event must run for a WIP pick line.');
        Assert.IsTrue(AfterSetLineDataForWipCalled, 'The standard after-line-data event must run for a WIP pick line.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleSubcTransferOrderPage')]
    procedure WipTransferInventoryPickPostingPreservesPostedMetadata()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        InTransitLocation: Record Location;
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        Vendor: Record Vendor;
        ForwardTransferHeader: Record "Transfer Header";
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
        ItemLedgerEntryCountBefore: Integer;
        WarehouseEntryCountBefore: Integer;
    begin
        // [SCENARIO TP-002] Posted WIP Inventory Pick metadata preserves zero-base and no-physical-entry behavior.
        Initialize();
        Quantity := 7;

        // [GIVEN] Bin-mandatory production location with Require Pick and According to Bin setup, but no default bin.
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ProductionLocation);
        ProductionLocation."Require Pick" := true;
        ProductionLocation."Special Equipment" := ProductionLocation."Special Equipment"::"According to Bin";
        ProductionLocation.Modify(true);
        LibraryWarehouse.CreateBin(Bin, ProductionLocation.Code, 'PICK', '', '');
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ProductionLocation.Code, true);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProductionLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        // [GIVEN] Released production order, subcontracting purchase order, and WIP transfer with no source bin.
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);

        TransferLine.SetRange("Document No.", ForwardTransferHeader."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.FindFirst();
        TransferLine.Validate("Transfer-from Bin Code", '');
        TransferLine.Modify(true);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] The WIP Inventory Pick is created, autofilled, and posted.
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        Assert.IsTrue(WarehouseActivityLine."Subc. Transfer WIP Item", 'The activity line must be marked as a WIP transfer line.');
        Assert.AreEqual('', WarehouseActivityLine."Bin Code", 'The WIP activity line must keep its bin code blank.');
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Transfer shipment and posted Inventory Pick line retain WIP metadata and zero-base semantics.
        TransferShipmentHeader.SetRange("Transfer Order No.", ForwardTransferHeader."No.");
        Assert.RecordCount(TransferShipmentHeader, 1);
        PostedInvtPickLine.SetRange("Source Type", Database::"Transfer Line");
        PostedInvtPickLine.SetRange("Source No.", ForwardTransferHeader."No.");
        Assert.RecordCount(PostedInvtPickLine, 1);
        PostedInvtPickLine.FindFirst();
        Assert.IsTrue(PostedInvtPickLine."Subc. Transfer WIP Item", 'The posted Inventory Pick line must be marked as a WIP transfer line.');
        Assert.AreEqual("Subc. Purchase Line Type"::None, PostedInvtPickLine."Subc. Purchase Line Type", 'A posted WIP transfer line must have no purchase line type.');
        Assert.AreEqual(Quantity, PostedInvtPickLine.Quantity, 'The posted Inventory Pick line must preserve the handled non-base quantity.');
        Assert.AreEqual(0, PostedInvtPickLine."Qty. (Base)", 'The posted WIP Inventory Pick line must retain zero base quantity semantics.');

        // [THEN] WIP posting does not create physical Item Ledger or Warehouse Entries.
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'WIP pick posting must not create item ledger entries.');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'WIP pick posting must not create warehouse entries.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleSubcTransferOrderPage')]
    procedure WipTransferInventoryPutAwayCreationAllowsBlankBinWithAccordingToBin()
    var
        Bin: Record Bin;
        Item: Record Item;
        InTransitLocation: Record Location;
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
        ForwardTransferHeader: Record "Transfer Header";
        Quantity: Decimal;
    begin
        // [SCENARIO TP-003] A WIP Inventory Put-away is created with a blank bin when Special Equipment is According to Bin.
        Initialize();
        Quantity := 7;

        // [GIVEN] Bin-mandatory production location with Require Pick, Require Put-away, and According to Bin setup.
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ProductionLocation);
        ProductionLocation."Require Pick" := true;
        ProductionLocation."Require Put-away" := true;
        ProductionLocation."Always Create Put-away Line" := true;
        ProductionLocation."Special Equipment" := ProductionLocation."Special Equipment"::"According to Bin";
        ProductionLocation.Modify(true);
        LibraryWarehouse.CreateBin(Bin, ProductionLocation.Code, 'PUT', '', '');
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ProductionLocation.Code, true);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProductionLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        // [GIVEN] Released production order, subcontracting purchase order, and completed forward WIP transfer.
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        LibraryWarehouse.PostTransferOrder(ForwardTransferHeader, false, true);

        // [GIVEN] Released WIP return transfer with an explicitly blank destination bin.
        SubcWarehouseLibrary.CreateReturnTransferWithSubcContext(
            PurchaseHeader, PurchaseLine,
            Vendor."Subc. Location Code", ProductionLocation.Code, InTransitLocation.Code,
            Quantity, ReturnTransferHeader);
        TransferLine.SetRange("Document No.", ReturnTransferHeader."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.FindFirst();
        TransferLine.Validate("Transfer-to Bin Code", '');
        TransferLine.Modify(true);
        LibraryWarehouse.ReleaseTransferOrder(ReturnTransferHeader);
        LibraryWarehouse.PostTransferOrder(ReturnTransferHeader, true, false);

        // [WHEN] An Inventory Put-away is created for the received WIP return transfer.
        SubcWarehouseLibrary.CreateInvtPutAwayFromTransferOrder(ReturnTransferHeader, WarehouseActivityHeader);

        // [THEN] Creation succeeds with one WIP activity line, no prefilled bin, and zero base quantity.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        Assert.IsTrue(WarehouseActivityLine."Subc. Transfer WIP Item", 'The activity line must be marked as a WIP transfer line.');
        Assert.AreEqual("Subc. Purchase Line Type"::None, WarehouseActivityLine."Subc. Purchase Line Type", 'A transfer WIP line must not have a purchase line type.');
        Assert.AreEqual('', WarehouseActivityLine."Bin Code", 'The WIP activity line must keep its bin code blank.');
        Assert.AreEqual(Quantity, WarehouseActivityLine.Quantity, 'The WIP activity line must retain the transfer quantity.');
        Assert.AreEqual(0, WarehouseActivityLine."Qty. (Base)", 'The WIP activity line must retain zero base quantity semantics.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleSubcTransferOrderPage')]
    procedure WipTransferInventoryPutAwayPostingPreservesPostedMetadata()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        InTransitLocation: Record Location;
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        Vendor: Record Vendor;
        ForwardTransferHeader: Record "Transfer Header";
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
        ItemLedgerEntryCountBefore: Integer;
        WarehouseEntryCountBefore: Integer;
    begin
        // [SCENARIO TP-004] Posted WIP Inventory Put-away metadata preserves zero-base and no-physical-entry behavior.
        Initialize();
        Quantity := 7;

        // [GIVEN] Bin-mandatory production location with Require Pick, Require Put-away, and According to Bin setup.
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(ProductionLocation);
        ProductionLocation."Require Pick" := true;
        ProductionLocation."Require Put-away" := true;
        ProductionLocation."Always Create Put-away Line" := true;
        ProductionLocation."Special Equipment" := ProductionLocation."Special Equipment"::"According to Bin";
        ProductionLocation.Modify(true);
        LibraryWarehouse.CreateBin(Bin, ProductionLocation.Code, 'PUT', '', '');
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ProductionLocation.Code, true);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProductionLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        // [GIVEN] Released production order, subcontracting purchase order, and completed forward WIP transfer.
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        LibraryWarehouse.PostTransferOrder(ForwardTransferHeader, false, true);

        // [GIVEN] Released WIP return transfer with an explicitly blank destination bin.
        SubcWarehouseLibrary.CreateReturnTransferWithSubcContext(
            PurchaseHeader, PurchaseLine,
            Vendor."Subc. Location Code", ProductionLocation.Code, InTransitLocation.Code,
            Quantity, ReturnTransferHeader);
        TransferLine.SetRange("Document No.", ReturnTransferHeader."No.");
#pragma warning disable AA0210
        TransferLine.SetRange("Transfer WIP Item", true);
#pragma warning restore AA0210
        TransferLine.FindFirst();
        TransferLine.Validate("Transfer-to Bin Code", '');
        TransferLine.Modify(true);
        LibraryWarehouse.ReleaseTransferOrder(ReturnTransferHeader);
        LibraryWarehouse.PostTransferOrder(ReturnTransferHeader, true, false);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] The WIP Inventory Put-away is created, autofilled, and posted.
        SubcWarehouseLibrary.CreateInvtPutAwayFromTransferOrder(ReturnTransferHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        Assert.IsTrue(WarehouseActivityLine."Subc. Transfer WIP Item", 'The activity line must be marked as a WIP transfer line.');
        Assert.AreEqual('', WarehouseActivityLine."Bin Code", 'The WIP activity line must keep its bin code blank.');
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Transfer receipt and posted Inventory Put-away line retain WIP metadata and zero-base semantics.
        TransferReceiptHeader.SetRange("Transfer Order No.", ReturnTransferHeader."No.");
        Assert.RecordCount(TransferReceiptHeader, 1);
        PostedInvtPutAwayLine.SetRange("Source Type", Database::"Transfer Line");
        PostedInvtPutAwayLine.SetRange("Source No.", ReturnTransferHeader."No.");
        Assert.RecordCount(PostedInvtPutAwayLine, 1);
        PostedInvtPutAwayLine.FindFirst();
        Assert.IsTrue(PostedInvtPutAwayLine."Transfer WIP Item", 'The posted Inventory Put-away line must be marked as a WIP transfer line.');
        Assert.AreEqual("Subc. Purchase Line Type"::None, PostedInvtPutAwayLine."Subc. Purchase Line Type", 'A posted WIP transfer line must have no purchase line type.');
        Assert.AreEqual(Quantity, PostedInvtPutAwayLine.Quantity, 'The posted Inventory Put-away line must preserve the handled non-base quantity.');
        Assert.AreEqual(0, PostedInvtPutAwayLine."Qty. (Base)", 'The posted WIP Inventory Put-away line must retain zero base quantity semantics.');

        // [THEN] WIP posting does not create physical Item Ledger or Warehouse Entries.
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'WIP put-away posting must not create item ledger entries.');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'WIP put-away posting must not create warehouse entries.');
    end;


    [Test]
    [HandlerFunctions('MessageHandler,HandleSubcTransferOrderPage')]
    procedure PartialThenRepeatPickAndPutAwayForWipTransfer()
    var
        Item: Record Item;
        InTransitLocation: Record Location;
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ForwardTransferHeader: Record "Transfer Header";
        ReturnTransferHeader: Record "Transfer Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick - WIP transfer partial posting
        // [SCENARIO] Partial/repeated posting for both legs of a WIP transfer round trip.
        // A Transfer WIP Item has Qty. (Base) = 0, so base-app activity completion deletes the activity after any
        // non-zero partial post. The remaining quantity must therefore be posted from a newly created activity.
        Initialize();
        Quantity := 20;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(ProductionLocation);
        ProductionLocation."Require Pick" := true;
        ProductionLocation.Modify(true);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProductionLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);

        // [WHEN] The forward Pick posts partially, then the remaining quantity is posted from a new activity.
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);
        SubcWarehouseLibrary.PostPartialInventoryPick(WarehouseActivityHeader, 12);

        TransferShipmentLine.SetRange("Transfer Order No.", ForwardTransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferShipmentLine);
        TransferShipmentLine.FindFirst();
        Assert.AreEqual(12, TransferShipmentLine.Quantity, 'Only the handled quantity should have shipped after the first partial Pick.');
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", ProductionLocation.Code);
        SubcWarehouseLibrary.VerifyNoItemLedgerEntry(Item."No.", ProductionLocation.Code);

        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        TransferShipmentLine.CalcSums(Quantity);
        Assert.AreEqual(Quantity, TransferShipmentLine.Quantity, 'Cumulative shipment quantity should equal the total pick quantity across both partial posts.');
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", ProductionLocation.Code);
        SubcWarehouseLibrary.VerifyNoItemLedgerEntry(Item."No.", ProductionLocation.Code);

        LibraryWarehouse.PostTransferOrder(ForwardTransferHeader, false, true);
        SubcWarehouseLibrary.CreateReturnTransferWithSubcContext(
            PurchaseHeader, PurchaseLine, Vendor."Subc. Location Code", ProductionLocation.Code, InTransitLocation.Code, Quantity, ReturnTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ReturnTransferHeader);
        LibraryWarehouse.PostTransferOrder(ReturnTransferHeader, true, false);

        // [WHEN] The return Put-away follows the same partial/repeat pattern.
        SubcWarehouseLibrary.CreateInvtPutAwayFromTransferOrder(ReturnTransferHeader, WarehouseActivityHeader);
        SubcWarehouseLibrary.PostPartialPutAway(WarehouseActivityHeader, 12);

        Assert.IsTrue(ReturnTransferHeader.Get(ReturnTransferHeader."No."), 'Return transfer order must remain open after a partial return receipt.');
        TransferReceiptLine.SetRange("Transfer Order No.", ReturnTransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferReceiptLine);
        TransferReceiptLine.FindFirst();
        Assert.AreEqual(12, TransferReceiptLine.Quantity, 'Only the handled quantity should have been received after the first partial return Put-away.');

        SubcWarehouseLibrary.CreateInvtPutAwayFromTransferOrder(ReturnTransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        TransferReceiptLine.SetRange("Transfer Order No.", ReturnTransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferReceiptLine);
        TransferReceiptLine.CalcSums(Quantity);
        Assert.AreEqual(Quantity, TransferReceiptLine.Quantity, 'Cumulative receipt quantity should equal the total put-away quantity across both partial posts.');
        Assert.IsFalse(ReturnTransferHeader.Get(ReturnTransferHeader."No."), 'Return transfer order must be deleted only after the final, fully-received posting.');
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", ProductionLocation.Code);
        SubcWarehouseLibrary.VerifyNoItemLedgerEntry(Item."No.", ProductionLocation.Code);
    end;

    [Test]
    [HandlerFunctions('HandleSubcTransferOrderPage')]
    procedure ForwardWipTransferWithRequirePickFalsePostsDirectly()
    var
        Item: Record Item;
        InTransitLocation: Record Location;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        ForwardTransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        Vendor: Record Vendor;
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick - WIP transfer direct posting
        // [SCENARIO] A forward WIP transfer posts directly when the shipping location does not require a Pick.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(ProductionLocation);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProductionLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);

        LibraryWarehouse.PostTransferOrder(ForwardTransferHeader, true, true);

        TransferShipmentHeader.SetRange("Transfer Order No.", ForwardTransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferShipmentHeader);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(WarehouseEntry);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(ItemLedgerEntry);
        WIPLedgerEntry.SetRange("Prod. Order Status", ProductionOrder.Status);
        WIPLedgerEntry.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordIsNotEmpty(WIPLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleSubcTransferOrderPage')]
    procedure DirectTransferFullWIPRoundTripForwardPickReturnPutAway()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        ForwardTransferHeader: Record "Transfer Header";
        ReturnTransferHeader: Record "Transfer Header";
        SubcToProdRoute: Record "Transfer Route";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEntry: Record "Warehouse Entry";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
        ItemLedgerEntryCountBefore: Integer;
        WarehouseEntryCountBefore: Integer;
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-B06 A direct WIP transfer posts through the same pick and put-away flow without an in-transit location.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] A WIP routing line with no transfer route between the production and subcontractor locations.
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(ProductionLocation);
        ProductionLocation."Require Pick" := true;
        ProductionLocation.Modify(true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);

        // [GIVEN] Production Order released; subcontracting purchase order + forward transfer order created
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);

        // [THEN] The forward transfer is created as a Direct Transfer (no matching Transfer Route/in-transit location)
        Assert.IsTrue(ForwardTransferHeader."Direct Transfer", 'Forward transfer must be a Direct Transfer when no Transfer Route exists between the production and subcontractor locations.');
        Assert.AreEqual('', ForwardTransferHeader."In-Transit Code", 'Direct Transfer must not use an in-transit location.');
        Assert.AreEqual(ForwardTransferHeader."Direct Transfer Posting"::"Direct Transfer", ForwardTransferHeader."Direct Transfer Posting",
            'Forward transfer must default to the Direct Transfer posting mode from Inventory Setup.');

        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntryCountBefore := ItemLedgerEntry.Count();
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntryCountBefore := WarehouseEntry.Count();

        // [WHEN] Inventory Pick is created, autofilled, and posted at L-PROD for the forward transfer (shipping) line
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] No Item Ledger Entry created; no Warehouse Entry created; WIP Ledger Entry created for subcontractor location
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'Forward WIP pick must not create item ledger entries.');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'Forward WIP pick must not create warehouse entries.');
        WIPLedgerEntry.SetRange("Prod. Order Status", ProductionOrder.Status);
        WIPLedgerEntry.SetRange("Prod. Order No.", ProductionOrder."No.");
        WIPLedgerEntry.SetRange("Location Code", Vendor."Subc. Location Code");
        Assert.RecordIsNotEmpty(WIPLedgerEntry);
        WIPLedgerEntry.CalcSums("Quantity (Base)");
        Assert.AreEqual(Quantity, Abs(WIPLedgerEntry."Quantity (Base)"), 'Forward WIP pick should move exactly the shipped quantity into WIP on the subcontractor side.');

        // [GIVEN] A direct return route and transfer order.
        LibraryWarehouse.CreateAndUpdateTransferRoute(SubcToProdRoute, Vendor."Subc. Location Code", ProductionLocation.Code, '', '', '');
        SubcToProdRoute.Validate("Direct Transfer", true);
        SubcToProdRoute.Modify(true);
        SubcWarehouseLibrary.CreateReturnTransferWithSubcContext(
            PurchaseHeader, PurchaseLine,
            Vendor."Subc. Location Code", ProductionLocation.Code, '',
            Quantity, ReturnTransferHeader);

        // [THEN] The return transfer is also a Direct Transfer
        Assert.IsTrue(ReturnTransferHeader."Direct Transfer", 'Return transfer must be a Direct Transfer when no Transfer Route exists between the subcontractor and production locations.');

        LibraryWarehouse.ReleaseTransferOrder(ReturnTransferHeader);

        // [WHEN] The return leg's Inventory Put-away is created, autofilled, and posted at L-PROD
        SubcWarehouseLibrary.CreateInvtPutAwayFromTransferOrder(ReturnTransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] No Item Ledger Entry created; no Warehouse Entry created by the return put-away either
        Assert.AreEqual(ItemLedgerEntryCountBefore, ItemLedgerEntry.Count(), 'Return WIP put-away must not create item ledger entries.');
        Assert.AreEqual(WarehouseEntryCountBefore, WarehouseEntry.Count(), 'Return WIP put-away must not create warehouse entries.');
        Assert.AreNotEqual(0, SubcWarehouseLibrary.GetPostedInvtPutAwayLineCountForTransferOrder(ReturnTransferHeader."No."),
            'Return WIP receipt via Direct Transfer must create posted inventory put-away lines.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleSubcTransferOrderPage')]
    procedure OutboundPickLineSplitAcrossBins()
    var
        Bins: array[3] of Record Bin;
        PickBin1: Record Bin;
        PickBin2: Record Bin;
        Item: Record Item;
        InTransitLocation: Record Location;
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ForwardTransferHeader: Record "Transfer Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        WorkCenter: array[2] of Record "Work Center";
        Quantities: array[3] of Decimal;
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-B02 Outbound Pick — line splitting across bins (info only, no ledger effect)
        // Splitting a WIP outbound Pick line across two bins is purely informational bookkeeping (no per-bin
        // Warehouse Entry is ever created for Transfer WIP Item lines), so this test confirms the split still
        // succeeds without error, both sub-lines post together into a single Transfer Shipment Line with the summed
        // quantity, and the WIP Ledger records a single net quantity equal to the shipped amount — not one entry per
        // split bin.
        Initialize();
        Quantity := 12;

        // [GIVEN] WIP outbound transfer line at bin-mandatory L-PICK shipping location
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(ProductionLocation, PickBin1);
        ProductionLocation."Require Pick" := true;
        ProductionLocation.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ProductionLocation.Code, true);
        LibraryWarehouse.CreateBin(PickBin2, ProductionLocation.Code, 'PICK2', '', '');

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProductionLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);

        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);

        // [WHEN] Inventory Pick activity line is split across two bins with Qty. to Handle set on each
        Bins[1] := PickBin1;
        Bins[2] := PickBin2;
        Quantities[1] := 5;
        Quantities[2] := 7;

        // [THEN] Split succeeds (no error) even though Transfer WIP Item = true
        SubcWarehouseLibrary.SplitActivityLineAcrossBins(WarehouseActivityHeader, WarehouseActivityHeader.Type, Bins, Quantities);

        // [WHEN] Post both split lines
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Single Transfer Shipment Line created with total quantity; no Warehouse Entry for either split line
        TransferShipmentLine.SetRange("Transfer Order No.", ForwardTransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferShipmentLine);
        TransferShipmentLine.FindFirst();
        Assert.AreEqual(Quantity, TransferShipmentLine.Quantity, 'Shipment line quantity must equal the summed split quantity.');

        // [THEN] No duplicate/double-counted WIP ledger effect from the split
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", ProductionLocation.Code);
        WIPLedgerEntry.SetRange("Prod. Order Status", ProductionOrder.Status);
        WIPLedgerEntry.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordIsNotEmpty(WIPLedgerEntry);
        WIPLedgerEntry.CalcSums("Quantity (Base)");
        Assert.AreEqual(Quantity, WIPLedgerEntry."Quantity (Base)", 'Splitting the pick across bins must create a single net WIP ledger quantity equal to the shipped quantity, not one entry per split bin.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ReturnPutAwayLineSplitAcrossBins()
    var
        Bins: array[3] of Record Bin;
        ProductionBin1: Record Bin;
        ProductionBin2: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        InTransitLocation: Record Location;
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnTransferHeader: Record "Transfer Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        WorkCenter: array[2] of Record "Work Center";
        Quantities: array[3] of Decimal;
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-B03 Return Put-Away — line splitting across bins (info only)
        // Mirrors the outbound pick split test for the return leg: splitting a WIP return Put-away line across two
        // bins must still produce a single Transfer Receipt Line with the summed quantity and a single net
        // (negative) WIP Ledger adjustment equal to the returned amount, with no Item Ledger/Warehouse Entries
        // created for either sub-line.
        Initialize();
        Quantity := 10;

        // [GIVEN] Return transfer line (Transfer WIP Item = true) at bin-mandatory L-PROD
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(ProductionLocation, ProductionBin1);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, ProductionLocation.Code, true);
        LibraryWarehouse.CreateBin(ProductionBin2, ProductionLocation.Code, 'PUT2', '', '');

        // [GIVEN] Default bin content so the return put-away resolves the destination bin.
        LibraryWarehouse.CreateBinContent(
            BinContent, ProductionLocation.Code, '', ProductionLocation."Default Bin Code", Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProductionLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        SubcWarehouseLibrary.CreateReturnTransferWithSubcContext(
            PurchaseHeader, PurchaseLine,
            Vendor."Subc. Location Code", ProductionLocation.Code, InTransitLocation.Code,
            Quantity, ReturnTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ReturnTransferHeader);
        LibraryWarehouse.PostTransferOrder(ReturnTransferHeader, true, false);

        SubcWarehouseLibrary.CreateInvtPutAwayFromTransferOrder(ReturnTransferHeader, WarehouseActivityHeader);

        // [WHEN] Activity line split into two bin-tagged sub-lines, Qty. to Handle set to sum of original qty
        Bins[1] := ProductionBin1;
        Bins[2] := ProductionBin2;
        Quantities[1] := 4;
        Quantities[2] := 6;
        SubcWarehouseLibrary.SplitActivityLineAcrossBins(WarehouseActivityHeader, WarehouseActivityHeader.Type, Bins, Quantities);

        // [WHEN] Post
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Single Transfer Receipt Line created; no Item Ledger/Warehouse Entry for either sub-line
        TransferReceiptLine.SetRange("Transfer Order No.", ReturnTransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferReceiptLine);
        TransferReceiptLine.FindFirst();
        Assert.AreEqual(Quantity, TransferReceiptLine.Quantity, 'Receipt line quantity must equal the summed split quantity.');

        // [THEN] Sum of split quantities equals original transfer quantity (no duplication)
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", ProductionLocation.Code);
        SubcWarehouseLibrary.VerifyNoItemLedgerEntry(Item."No.", ProductionLocation.Code);
        WIPLedgerEntry.SetRange("Prod. Order Status", ProductionOrder.Status);
        WIPLedgerEntry.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordIsNotEmpty(WIPLedgerEntry);
        WIPLedgerEntry.CalcSums("Quantity (Base)");
        Assert.AreEqual(-Quantity, WIPLedgerEntry."Quantity (Base)", 'Splitting the return put-away across bins must create a single net WIP ledger reduction equal to the returned quantity, not one entry per split bin.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleSubcTransferOrderPage')]
    procedure AutoFillQtyToHandleOnWIPLines()
    var
        Item: Record Item;
        InTransitLocation: Record Location;
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ForwardTransferHeader: Record "Transfer Header";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-B05 AutoFill Qty. to Handle on WIP lines (Quantity vs Quantity Base)
        // WIP transfer activity lines intentionally always have Qty. (Base) = 0 (no physical item ledger movement),
        // so "AutoFill Qty. to Handle" must populate the (non-base) Quantity/Qty. to Handle field from Qty.
        // Outstanding while leaving Qty. to Handle (Base) at zero, and posting must succeed without triggering any
        // base-quantity balance errors.
        Initialize();
        Quantity := 9;

        // [GIVEN] WIP transfer activity line with Qty. (Base) = 0
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(ProductionLocation);
        ProductionLocation."Require Pick" := true;
        ProductionLocation.Modify(true);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProductionLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);

        // [WHEN] AutoFill Qty. to Handle invoked
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();

        // [THEN] Quantity field is filled from Qty. Outstanding (not Quantity Base, which remains 0)
        Assert.IsTrue(WarehouseActivityLine."Subc. Transfer WIP Item", 'The inventory pick line must inherit Transfer WIP Item from the transfer line.');
        Assert.AreEqual(0, WarehouseActivityLine."Qty. per Unit of Measure", 'WIP activity lines must have zero Qty. per Unit of Measure.');
        Assert.AreEqual(Quantity, WarehouseActivityLine."Qty. to Handle", 'AutoFill must populate Qty. to Handle from Quantity.');
        Assert.AreEqual(0, WarehouseActivityLine."Qty. to Handle (Base)", 'Qty. to Handle (Base) must remain zero for WIP lines.');

        // [THEN] Posting succeeds without base-quantity errors.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
    end;


    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ProductionOrderOutputAndRoutingSyncAcrossOps()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        ValueEntry: Record "Value Entry";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-E01 Production order output/routing status synchronization across both operations
        // End-to-end reconciliation check across a two-operation routing at a single location: posting Op 10
        // (NotLastOperation) advances only that routing line to Finished while Op 20 stays active and produces only
        // a Capacity Ledger Entry; posting Op 20 (LastOperation) afterward finishes its routing line, produces the
        // output Item Ledger Entry with non-zero cost, and the Prod. Order Line's Finished Quantity reconciles with
        // the total posted output — confirming capacity and item output stay in sync across both operations.
        Initialize();
        Quantity := 8;

        // [GIVEN] Two-op routing, Location L-PA
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

        // [WHEN] Op 10 (NotLastOperation) Put-Away posted
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Prod. Order Routing Line (Op 10) Status = Finished; Op 20 remains Active
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Work Center");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[1]."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(ProdOrderRoutingLine."Routing Status"::Finished, ProdOrderRoutingLine."Routing Status", 'Operation 10 must be finished after posting the first put-away.');

        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreNotEqual(ProdOrderRoutingLine."Routing Status"::Finished, ProdOrderRoutingLine."Routing Status", 'Operation 20 must still be active after the first put-away.');

        // [WHEN] Op 20 (LastOperation) Put-Away posted
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        // Set a purchase cost so the output expected cost can be verified.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 25, 2));
        PurchaseLine.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();

        // [THEN] Prod. Order Routing Line (Op 20) Status = Finished
        Assert.AreEqual(ProdOrderRoutingLine."Routing Status"::Finished, ProdOrderRoutingLine."Routing Status", 'Operation 20 must be finished after posting the second put-away.');

        // [THEN] Prod. Order Line "Finished Quantity"/output reconciles with total posted output quantity
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        Assert.AreEqual(Quantity, ProdOrderLine."Finished Quantity", 'Finished Quantity must reconcile with the posted output quantity.');

        // [THEN] Capacity Ledger Entries exist for both work/machine centers with correct run times
        CapacityLedgerEntry.SetRange(Type, CapacityLedgerEntry.Type::"Work Center");
        CapacityLedgerEntry.SetRange("No.", WorkCenter[1]."No.");
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[1]."No.", Quantity);
        CapacityLedgerEntry.SetRange("No.", WorkCenter[2]."No.");
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);
        SubcWarehouseLibrary.VerifyCapacityLedgerEntry(WorkCenter[2]."No.", Quantity);

        // [THEN] Item Ledger Entry only for second operation (LastOperation) with correct quantity and cost
        SubcWarehouseLibrary.VerifyItemLedgerEntry(Item."No.", Quantity, Location.Code);
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        Assert.RecordIsNotEmpty(ValueEntry);
        ValueEntry.CalcSums("Cost Amount (Expected)");
        // This scenario verifies expected cost; actual cost requires component consumption and cost adjustment.
        Assert.AreNotEqual(0, ValueEntry."Cost Amount (Expected)", 'The output item ledger entry created for the Last Operation must carry a non-zero expected cost.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleSubcTransferOrderPage')]
    procedure WIPLedgerSynchronizesAcrossFullChain()
    var
        Item: Record Item;
        InTransitLocation: Record Location;
        ProductionLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        ForwardTransferHeader: Record "Transfer Header";
        ReturnTransferHeader: Record "Transfer Header";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-E02 WIP ledger synchronization across full subcontracting + WIP transfer chain
        // Broadest WIP integration test: a three-operation routing where Op 10 is a WIP transfer (pick + return) and
        // Op 20 is a LastOperation purchase. Confirms WIP Ledger Entries are created at each location transition
        // along the chain, and that the final output Item Ledger Entry is created only once, at Op 20 (the true last
        // operation) — not prematurely at Op 10.
        Initialize();
        Quantity := 6;

        // [GIVEN] Three-op routing: Op10 = Transfer WIP Item (pick+return), Op20 = LastOperation purchase
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateThreeOpRoutingWithWIPTransfer(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(ProductionLocation);
        ProductionLocation."Require Pick" := true;
        ProductionLocation.Modify(true);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        // Configure the transfer route for the vendor on the WIP operation.
        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Location Code" := ProductionLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProductionLocation.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProductionLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Full sequence executed: forward pick → return put-away → purchase put-away for Op20
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        SubcWarehouseLibrary.CreateReturnTransferWithSubcContext(
            PurchaseHeader, PurchaseLine,
            Vendor."Subc. Location Code", ProductionLocation.Code, InTransitLocation.Code,
            Quantity, ReturnTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ReturnTransferHeader);
        LibraryWarehouse.PostTransferOrder(ReturnTransferHeader, true, false);
        SubcWarehouseLibrary.CreateInvtPutAwayFromTransferOrder(ReturnTransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        WIPLedgerEntry.SetRange("Prod. Order Status", ProductionOrder.Status);
        WIPLedgerEntry.SetRange("Prod. Order No.", ProductionOrder."No.");

        // [THEN] WIP Ledger Entries created at each applicable location transition (per next-location-in-routing rule)
        Assert.RecordIsNotEmpty(WIPLedgerEntry);

        // [THEN] Final Output Item Ledger Entry only created at Op20 (Last Operation), not at Op10
        SubcWarehouseLibrary.VerifyItemLedgerEntry(Item."No.", Quantity, ProductionLocation.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure UndoReceiptBlockedWhenBinMandatory()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-E03 Undo Receipt is blocked once a Posted Invt. Put-away Line exists (Bin Mandatory)
        // At a Bin Mandatory location, once a LastOperation Put-Away has posted (creating a Posted Invt. Put-away
        // Line), "Undo Purchase Receipt Line" must be blocked with the standard base-app error — consistent with how
        // undo is already blocked for the two-step (Warehouse Receipt) flow at bin-mandatory locations.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] LastOperation Put-Away posted at Location L-PA-BIN (Bin Mandatory = true)
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

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
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [WHEN] Undo Receipt attempted on the Purch. Rcpt. Line
        asserterror Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);

        // [THEN] Undo is blocked with the standard "Posted Invt. Put-away Lines" error (consistent with two-step flow)
        Assert.ExpectedError('warehouse put-away lines have already been posted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure UndoReceiptNonBinMandatoryReflectsCurrentBehavior()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-E04 Undo Receipt remains blocked after a non-bin-mandatory inventory put-away.
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] LastOperation Put-Away posted at Location L-PA (Bin Mandatory = false)
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
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [WHEN] Undo Receipt attempted
        asserterror Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);

        // [THEN] Undo is blocked by the current implementation
        Assert.ExpectedError('You cannot undo line');
    end;

    [Test]
    procedure WorksheetResyncUsesOutstandingQuantity()
    var
        Item: Record Item;
        Location: Record Location;
        VendorLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptHeader2: Record "Posted Whse. Receipt Header";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WorkCenter: array[2] of Record "Work Center";
        FirstReceiptQty: Decimal;
        RemainingReceiptQty: Decimal;
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-E06 Get Source Documents / Put-Away Worksheet resync picks up newly received quantity
        // After the first partial Warehouse Receipt is received and fully put away via the worksheet, receiving the
        // remainder of the purchase order and re-running "Get Source Documents" must create one worksheet line for
        // only the newly received quantity.
        Initialize();
        Quantity := 10;
        FirstReceiptQty := 6;
        RemainingReceiptQty := Quantity - FirstReceiptQty;

        // [GIVEN] LastOperation purchase order partially received via Warehouse Receipt, and fully put away
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);
        Location."Use Put-away Worksheet" := true;
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(VendorLocation);
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        SubcWarehouseLibrary.CreateWarehouseReceiptFromPurchaseOrder(PurchaseHeader, WarehouseReceiptHeader);
        SubcWarehouseLibrary.PostPartialWarehouseReceipt(WarehouseReceiptHeader, FirstReceiptQty, PostedWhseReceiptHeader);

        SubcWarehouseLibrary.CreatePutAwayWorksheet(WhseWorksheetTemplate, WhseWorksheetName, Location.Code);
        SubcWarehouseLibrary.GetWarehouseDocumentsForPutAwayWorksheet(WhseWorksheetTemplate.Name, WhseWorksheetName, Location.Code);

        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        Assert.RecordIsNotEmpty(WhseWorksheetLine);
        WhseWorksheetLine.FindFirst();
        Assert.AreEqual(FirstReceiptQty, WhseWorksheetLine.Quantity,
            'The first worksheet line must only cover the partially received quantity.');

        // [GIVEN] The received quantity is fully put away.
        SubcWarehouseLibrary.CreatePutAwayFromWorksheet(WhseWorksheetName, WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] The remainder of the purchase order is received
        SubcWarehouseLibrary.PostWarehouseReceipt(WarehouseReceiptHeader, PostedWhseReceiptHeader2);

        // [WHEN] Put-Away Worksheet "Get Source Documents" run again for the same location
        SubcWarehouseLibrary.GetWarehouseDocumentsForPutAwayWorksheet(WhseWorksheetTemplate.Name, WhseWorksheetName, Location.Code);

        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        Assert.RecordIsNotEmpty(WhseWorksheetLine);
        WhseWorksheetLine.FindFirst();

        // [THEN] Resulting worksheet line quantity equals the remaining (newly received) receipt quantity
        Assert.AreEqual(RemainingReceiptQty, WhseWorksheetLine.Quantity,
            'Worksheet line quantity must match the newly received remaining quantity only.');

        // [THEN] Only one worksheet line exists for the remaining quantity (no duplicate re-fetch)
        Assert.RecordCount(WhseWorksheetLine, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure FromProductionBinPropagatesEndToEnd()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ManufacturingSetup: Record "Manufacturing Setup";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WorkCenter: array[2] of Record "Work Center";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        SubcCalculateSubcontracts: Report "Subc. Calculate Subcontracts";
        Quantity: Decimal;
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-E07 From-Production Bin Code flows from the production order line to the inventory put-away.
        Initialize();
        Quantity := 5;

        // [GIVEN] Bin-mandatory location with a From-Production Bin Code and a released production order
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [THEN] Prod. Order Line inherits the From-Production Bin Code from the location
        Assert.AreEqual(Bin.Code, ProdOrderLine."Bin Code", 'Prod. Order Line must inherit From-Production Bin Code from the location.');

        // [WHEN] Subcontracting worksheet calculation generates the requisition line
        ManufacturingSetup.Get();
        RequisitionLine."Worksheet Template Name" := ManufacturingSetup."Subcontracting Template Name";
        RequisitionLine."Journal Batch Name" := ManufacturingSetup."Subcontracting Batch Name";
        SubcCalculateSubcontracts.SetWkShLine(RequisitionLine);
        SubcCalculateSubcontracts.UseRequestPage(false);
        SubcCalculateSubcontracts.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", ManufacturingSetup."Subcontracting Template Name");
        RequisitionLine.SetRange("Journal Batch Name", ManufacturingSetup."Subcontracting Batch Name");
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();

        // [THEN] Requisition Line inherits the production bin
        Assert.AreEqual(Bin.Code, RequisitionLine."Bin Code", 'Requisition Line must inherit the production bin.');

        // [WHEN] Carry Out Action creates the subcontracting purchase order
        CarryOutActionMsgReq.SetReqWkShLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
#pragma warning disable AA0210
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [THEN] Purchase Line inherits the production bin
        Assert.AreEqual(Bin.Code, PurchaseLine."Bin Code", 'Purchase Line must inherit the production bin.');

        // [WHEN] Inventory Put-Away is created from the purchase order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();

        // [THEN] Inventory Put-Away activity line inherits the production bin
        Assert.AreEqual(Bin.Code, WarehouseActivityLine."Bin Code", 'Inventory Put-away activity line must inherit the production bin.');
    end;

    [Test]
    procedure ManualProdOrderLineBinIsRespected()
    var
        AltBin: Record Bin;
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ManufacturingSetup: Record "Manufacturing Setup";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
        SubcCalculateSubcontracts: Report "Subc. Calculate Subcontracts";
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-G02 Manually-set Prod. Order Line bin (before Calculate Subcontracts) is respected, not overwritten
        // If a user manually overrides the Prod. Order Line's Bin Code BEFORE running "Calculate Subcontracts", that
        // manual choice must be preserved (not overwritten by the location's default) as it flows through to the
        // Requisition Line and then the Purchase Line — confirming user intent takes precedence over the location
        // default earlier in the chain.
        Initialize();

        // [GIVEN] Released production order with an alternate valid bin at its location
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);
        LibraryWarehouse.CreateBin(AltBin, Location.Code, 'ALTBIN', '', '');
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 5, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [WHEN] The production order line bin is manually changed before subcontracting calculation
        ProdOrderLine.Validate("Bin Code", AltBin.Code);
        ProdOrderLine.Modify(true);

        // [WHEN] Subcontracting worksheet calculation generates the requisition line
        ManufacturingSetup.Get();
        RequisitionLine."Worksheet Template Name" := ManufacturingSetup."Subcontracting Template Name";
        RequisitionLine."Journal Batch Name" := ManufacturingSetup."Subcontracting Batch Name";
        SubcCalculateSubcontracts.SetWkShLine(RequisitionLine);
        SubcCalculateSubcontracts.UseRequestPage(false);
        SubcCalculateSubcontracts.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", ManufacturingSetup."Subcontracting Template Name");
        RequisitionLine.SetRange("Journal Batch Name", ManufacturingSetup."Subcontracting Batch Name");
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        RequisitionLine.FindFirst();

        // [THEN] Requisition Line retains the manually selected bin
        Assert.AreEqual(AltBin.Code, RequisitionLine."Bin Code", 'Manual production-order-line bin must propagate to the requisition line.');

        // [WHEN] Carry Out Action creates the subcontracting purchase order
        CarryOutActionMsgReq.SetReqWkShLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
#pragma warning disable AA0210
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();

        // [THEN] Purchase Line retains the manually selected bin
        Assert.AreEqual(AltBin.Code, PurchaseLine."Bin Code", 'Manual production-order-line bin must propagate to the purchase line.');
    end;

    [Test]
    procedure ChangingProdOrderLineLocationRedefaultsBin()
    var
        AltBin: Record Bin;
        Bin1: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        Location1: Record Location;
        Location2: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-G03 Changing a production order line location re-defaults its bin.
        Initialize();

        // [GIVEN] Released production order at a bin-mandatory location with a second bin-mandatory location available
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location1, Bin1);
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location2, Bin2);
        LibraryWarehouse.CreateBin(AltBin, Location1.Code, 'ALTBIN', '', '');
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location1.Code;
        Vendor."Location Code" := Location1.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 5, Location1.Code);

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [WHEN] A manual bin is set and the production order line location is changed
        ProdOrderLine.Validate("Bin Code", AltBin.Code);
        ProdOrderLine.Modify(true);
        ProdOrderLine.Validate("Location Code", Location2.Code);
        ProdOrderLine.Modify(true);

        // [THEN] The bin is defaulted from the new location
        Assert.AreEqual(Bin2.Code, ProdOrderLine."Bin Code", 'Changing the location must re-default the bin for the new location.');
    end;

    [Test]
    [HandlerFunctions('HandleSubcTransferOrderPage')]
    procedure PurchaseLineBinAndLocationLockedAfterTransferExists()
    var
        DefaultBin: Record Bin;
        Item: Record Item;
        InTransitLocation: Record Location;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ForwardTransferHeader: Record "Transfer Header";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-G04 Purchase Line Bin Code/Location Code become immutable once a linked transfer order exists
        // Once a WIP subcontracting purchase line has a linked forward Transfer Order created against it, its Bin
        // Code and Location Code must become immutable — changing either after the fact would desynchronize the
        // transfer route already established, so both Validate calls are expected to raise an error.
        Initialize();

        // [GIVEN] WIP subcontracting purchase line with an existing linked forward transfer order
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, DefaultBin);

        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(Location.Code, Vendor."Subc. Location Code", InTransitLocation.Code);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 5, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);

        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");

        // [THEN] The purchase line cannot be changed after the linked transfer order is created.
        asserterror SubcTransferManagement.CheckSubcPurchLineCanBeModified(PurchaseLine, PurchaseLine.FieldCaption("Bin Code"));
        Assert.ExpectedError('because transfer orders exist for the linked production order');
    end;

    [Test]
    procedure PurchaseLineBinEditableBeforeTransferExists()
    var
        AltBin: Record Bin;
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-G05 Purchase Line Bin Code remains editable (no transfer order link yet) — verify standard bin validation still applies
        // Complements the locked-field test above: BEFORE any linked transfer order exists, the WIP purchase line's
        // Bin Code must remain freely editable to any valid bin at the location (standard behavior, no
        // subcontracting-specific restriction), while entering a nonexistent bin code is still rejected by standard
        // bin validation.
        Initialize();

        // [GIVEN] WIP subcontracting purchase line without a linked transfer order
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);
        LibraryWarehouse.CreateBin(AltBin, Location.Code, 'ALTBIN', '', '');

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 5, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        // [WHEN] The purchase line bin is changed to another valid bin
        PurchaseLine.Validate("Bin Code", AltBin.Code);
        PurchaseLine.Modify(true);

        // [THEN] The purchase line bin is updated
        Assert.AreEqual(AltBin.Code, PurchaseLine."Bin Code", 'Bin Code must remain editable before a transfer order exists.');

        // [WHEN] The purchase line bin is changed to a nonexistent bin
        // [THEN] Standard bin validation rejects the nonexistent bin
        asserterror PurchaseLine.Validate("Bin Code", 'MISSING-BIN');
        Assert.ExpectedError('MISSING-BIN');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure RoutingOrLocationBinChangesAreNotRetroactive()
    var
        Bin1: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-G07 Routing line bin fields changed after Calculate Subcontracts do not retroactively update existing purchase line
        // Confirms bin defaulting is a one-time, creation-time propagation, not a live binding: once a Purchase Line
        // has been created with a given bin, subsequently changing the Location's From-Production Bin Code or the
        // Prod. Order Routing Line's From-Production Bin Code must NOT retroactively update the already-created
        // Purchase Line, and a Put-Away activity line created afterward is still driven by the (unchanged) original
        // Purchase Line bin.
        Initialize();

        // [GIVEN] Existing subcontracting purchase line created from a bin-mandatory location
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin1);
        LibraryWarehouse.CreateBin(Bin2, Location.Code, 'BIN2', '', '');
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 5, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [THEN] The purchase line uses the original production bin
        Assert.AreEqual(Bin1.Code, PurchaseLine."Bin Code", 'Initial purchase line must use the original production bin.');

        // [WHEN] The location and routing line From-Production Bin Code values are changed
        Location."From-Production Bin Code" := Bin2.Code;
        Location.Modify(true);
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        if ProdOrderRoutingLine.FindFirst() then begin
            ProdOrderRoutingLine."From-Production Bin Code" := Bin2.Code;
            ProdOrderRoutingLine.Modify(true);
        end;

        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");

        // [THEN] The existing purchase line retains its original bin
        Assert.AreEqual(Bin1.Code, PurchaseLine."Bin Code", 'Changing routing/location bin fields after purchase-line creation must not retroactively update the purchase line.');

        // [WHEN] Inventory Put-Away is created from the existing purchase order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();

        // [THEN] The put-away line is still driven by the original purchase-line bin
        Assert.AreEqual(Bin1.Code, WarehouseActivityLine."Bin Code", 'The already-created purchase line still drives the put-away bin.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure BinMandatoryToggledOffAfterPropagation()
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
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [FEATURE] Subcontracting Inventory Put-away / Pick E2E WIP
        // [SCENARIO] TC-E2E-G08 Bin Mandatory toggled off after Bin Code already propagated — no error at Put-Away stage
        // If "Bin Mandatory" is turned off on a location AFTER a bin code has already propagated onto the purchase
        // line, the existing (now technically optional) bin value must not block the single-step Put-Away flow —
        // posting should proceed normally using the already-assigned bin.
        Initialize();

        // [GIVEN] Subcontracting purchase line with a propagated production bin
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, Bin);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 5, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.TestField("Bin Code", Bin.Code);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [WHEN] Bin Mandatory is turned off after the bin has propagated
        Location."Bin Mandatory" := false;
        Location.Modify(true);

        // [WHEN] Inventory Put-Away is created and posted
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] The existing bin does not block the single-step put-away flow
        Assert.AreNotEqual(0, SubcWarehouseLibrary.GetPostedInvtPutAwayLineCountForPurchaseOrder(PurchaseHeader."No."),
            'Turning Bin Mandatory off after bin propagation must not block the single-step put-away flow.');
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [PageHandler]
    procedure HandleSubcTransferOrderPage(var TransferOrderPage: TestPage "Transfer Order")
    begin
        TransferOrderPage.OK().Invoke();
    end;
}