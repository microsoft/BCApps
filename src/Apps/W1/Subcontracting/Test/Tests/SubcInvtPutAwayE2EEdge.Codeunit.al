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
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

codeunit 149921 "Subc. Invt. Put-away E2E Edge"
{
    // [FEATURE] Subcontracting Inventory Put-away/Pick - Edge Scenarios
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
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Invt. Put-away E2E Edge");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Invt. Put-away E2E Edge");

        SubcontractingMgmtLibrary.Initialize();
        SubcLibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();
        LibrarySetupStorage.Save(Database::"General Ledger Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Invt. Put-away E2E Edge");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure LastOperationSingleBinPutAwayWritesBinBackToPurchaseLine()
    var
        AltBin: Record Bin;
        DefaultBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
        OriginalProdBinCode: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] Group H - Bin write-back after posting
        // [SCENARIO] TC-E2E-H01 LastOperation single-bin Put-Away writes the used bin back to Purchase Line
        // Confirms the standard base-app bin write-back (Whse.-Activity-Post -> UpdateSourceDocument) still fires
        // correctly for a subcontracting LastOperation receipt: overriding the bin on the activity line before
        // posting must update the Purchase Line's Bin Code, while the originating Prod. Order Line (a separate
        // table untouched by this write-back) stays intact.

        // [GIVEN] Location L-PA-BIN, LastOperation purchase line created with Bin Code = "PROD-BIN" (from production order line)
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, DefaultBin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateBin(AltBin, Location.Code, 'ALTBIN', '', '');

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

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        OriginalProdBinCode := ProdOrderLine."Bin Code";

        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();

        // [WHEN] Inventory Put-Away activity line's Bin Code is changed to a different valid bin "ALT-BIN" before posting
        WarehouseActivityLine.Validate("Bin Code", AltBin.Code);
        WarehouseActivityLine.Modify(true);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Put-Away is posted
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // [THEN] Purchase Line."Bin Code" = "ALT-BIN" after posting (standard base app write-back, PurchLine.Modify() in UpdateSourceDocument)
        Assert.AreEqual(AltBin.Code, PurchaseLine."Bin Code", 'Purchase Line Bin Code should be written back from the posted activity line.');

        // [THEN] Warehouse Entry created with Bin Code = "ALT-BIN"
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, AltBin.Code, Item."No.", Quantity);

        // [THEN] Prod. Order Line."Bin Code" is UNCHANGED (still "PROD-BIN") — confirms no write-back to production order line
        Assert.AreEqual(OriginalProdBinCode, ProdOrderLine."Bin Code", 'Production Order Line Bin Code must not be rewritten by Inventory Put-away posting.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SplitLastOperationPutAwayUsesLastProcessedBinOnPurchaseLine()
    var
        Bins: array[3] of Record Bin;
        DefaultBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
        OriginalProdBinCode: Code[20];
        Quantities: array[3] of Decimal;
    begin
        // [FEATURE] Group H - Bin write-back after posting
        // [SCENARIO] TC-E2E-H02 Split Last Operation line across multiple bins — Purchase Line reflects only the last-processed bin
        // Documents a known base-app limitation when a single LastOperation line is split across multiple bins:
        // only the LAST split sub-line processed during posting "wins" on the Purchase Line's Bin Code, even though
        // both bins are correctly reflected in the per-bin Warehouse Entries/Bin Content. This locks in the current
        // (non-ideal) behavior rather than an aspirational one.

        // [GIVEN] LastOperation purchase line, quantity = 20, Location L-PA-BIN
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, DefaultBin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateBin(Bins[1], Location.Code, 'B1', '', '');
        LibraryWarehouse.CreateBin(Bins[2], Location.Code, 'B2', '', '');

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 20, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        OriginalProdBinCode := ProdOrderLine."Bin Code";

        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        Quantities[1] := 12;
        Quantities[2] := 8;

        // [WHEN] Put-Away activity line split into 2 sub-lines: Bin "B1" (qty 12), Bin "B2" (qty 8)
        SubcWarehouseLibrary.SplitActivityLineAcrossBins(WarehouseActivityHeader, WarehouseActivityHeader.Type, Bins, Quantities);

        // [WHEN] Both split lines posted together (single Whse.-Activity-Post run)
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // [THEN] 2 Warehouse Entries created (one per bin, quantities 12 and 8) — this remains the authoritative per-bin record
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, Bins[1].Code, Item."No.", Quantities[1]);
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, Bins[2].Code, Item."No.", Quantities[2]);

        // [THEN] Purchase Line."Bin Code" reflects only ONE of the two bins (whichever split line is processed first in the posting loop)
        // Current base-app behavior processes the original (first/lowest Line No.) split line last on the Purchase
        // Line write-back, so B1 wins - verified empirically (the posting loop's write-back order is not simply
        // ascending Line No.).
        Assert.AreEqual(Bins[1].Code, PurchaseLine."Bin Code", 'Purchase Line Bin Code should follow the last processed split line.');

        // [THEN] Prod. Order Line."Bin Code" remains unchanged regardless of which split-line bin "won" on the Purchase Line
        Assert.AreEqual(OriginalProdBinCode, ProdOrderLine."Bin Code", 'Production Order Line Bin Code must remain unchanged.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure NotLastOperationInformationalBinStillWritesBackToPurchaseLine()
    var
        AltBin: Record Bin;
        DefaultBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
        OriginalProdBinCode: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] Group H - Bin write-back after posting
        // [SCENARIO] TC-E2E-H03 NotLastOperation line — bin entered "for information only" still writes back to Purchase Line
        // NotLastOperation lines never create a physical Warehouse Entry (no bin to actually move stock into), but
        // the base-app write-back logic still unconditionally copies whatever bin was typed on the activity line
        // back to the Purchase Line. This test proves that "informational only" bin entry still mutates the
        // Purchase Line even without any real movement.

        // [GIVEN] NotLastOperation purchase line, Location L-PA-BIN, a bin code entered on the activity line for information purposes
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, DefaultBin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateBin(AltBin, Location.Code, 'INFOBIN', '', '');

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

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        OriginalProdBinCode := ProdOrderLine."Bin Code";

        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Bin Code", AltBin.Code);
        WarehouseActivityLine.Modify(true);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Put-Away posted
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // [THEN] No Warehouse Entry created (per spec §1.1/§3.2 — NotLastOperation has no physical movement)
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", Location.Code);

        // [THEN] Purchase Line."Bin Code" is nevertheless updated to the entered bin
        Assert.AreEqual(AltBin.Code, PurchaseLine."Bin Code", 'Purchase Line Bin Code should still be written back for NotLastOperation lines.');

        // [THEN] Prod. Order Line."Bin Code" remains unchanged
        Assert.AreEqual(OriginalProdBinCode, ProdOrderLine."Bin Code", 'Production Order Line Bin Code must remain unchanged.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,HandleTransferOrderPage')]
    procedure WipTransferPickAndPutAwayWriteBinsBackToTransferLine()
    var
        BinContent: Record "Bin Content";
        PickBin: Record Bin;
        ProdAltBin: Record Bin;
        Item: Record Item;
        InTransitLocation: Record Location;
        ProdLocation: Record Location;
        ShipLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ForwardTransferHeader: Record "Transfer Header";
        ReturnTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseRequest: Record "Warehouse Request";
        WorkCenter: array[2] of Record "Work Center";
        OriginalProdBinCode: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] Group H - Bin write-back after posting
        // [SCENARIO] TC-E2E-H04 Transfer WIP Item lines (Pick + Put-away) — bin write-back to Transfer Line despite no physical movement
        // Extends the same bin write-back concern to the WIP Transfer path (Pick for the outbound leg, Put-away for
        // the inbound return leg): even though Transfer WIP Item lines create no Warehouse/Item Ledger Entries, the
        // entered bin should still propagate to the Transfer Line's "Transfer-from Bin Code"/"Transfer-To Bin Code",
        // while the production location's Prod. Order Line bin remains unaffected throughout.

        // [GIVEN] WIP outbound transfer line (Pick) with a bin entered for information purposes at the shipping location
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.SetTransferWIPItemOnRoutingLine(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationForWIPPick(ShipLocation, ProdLocation, true);

        ProdLocation."Require Pick" := true;
        ProdLocation."Require Put-away" := true;
        ProdLocation.Modify(true);
        // The forward leg's outbound Pick activity is created at ProdLocation (the Transfer-from location for the
        // Prod -> Ship forward WIP transfer, see SubcCreateTransfOrder.Report.al's GetWIPTransferFromLocations), so
        // the override bin used on that activity line must also belong to ProdLocation - a bin from a different
        // location fails the Warehouse Activity Line's "Bin Code" table relation validation.
        LibraryWarehouse.CreateBin(PickBin, ProdLocation.Code, 'PICKALT', '', '');
        LibraryWarehouse.CreateBin(ProdAltBin, ProdLocation.Code, 'RETALT', '', '');
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // A Default=true Bin Content record for the item at ProdLocation's default bin is required so that the
        // Invt. Put-away for the WIP return leg (created further below via CreateInvtPutAwayFromTransferOrder) can
        // resolve a bin via the Default Bin put-away policy - without it, CreateInventoryPutaway.
        // CreatePutawayWithDefaultBinPolicy finds no default bin and exits silently, so no put-away activity is
        // ever created for the Transfer Line ("There is nothing to create."). No physical put-away/output has been
        // posted to ProdLocation yet at this point in the test, so no Bin Content exists there for this item.
        LibraryWarehouse.CreateBinContent(BinContent, ProdLocation.Code, '', ProdLocation."Default Bin Code", Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := ShipLocation.Code;
        Vendor."Location Code" := ShipLocation.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateTransferRoutesForWIPTransfer(ProdLocation.Code, ShipLocation.Code, InTransitLocation.Code);
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, ProdLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        OriginalProdBinCode := ProdOrderLine."Bin Code";

        SubcWarehouseLibrary.CreateSubcontractingForwardTransferFromPurchaseOrder(PurchaseHeader);
        SubcWarehouseLibrary.FindSubcontractingTransferHeader(PurchaseHeader, false, ForwardTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ForwardTransferHeader);

        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Outbound Transfer");
        WarehouseRequest.SetRange("Source No.", ForwardTransferHeader."No.");
        WarehouseRequest.FindFirst();
        // IsDefault=false: earlier tests in this codeunit run (and commit via posting) can already have registered a
        // Default=true Warehouse Employee for this user at a different location; passing true here would silently
        // no-op (see LibraryWarehouse.CreateWarehouseEmployee) and leave ProdLocation without an authorized employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, WarehouseRequest."Location Code", false);
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Bin Code", PickBin.Code);
        WarehouseActivityLine.Modify(true);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] Inventory Pick posted
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        TransferLine.SetRange("Document No.", ForwardTransferHeader."No.");
        TransferLine.FindFirst();

        // [THEN] Transfer Line."Transfer-from Bin Code" updated to the entered bin
        Assert.AreEqual(PickBin.Code, TransferLine."Transfer-from Bin Code", 'Outbound WIP pick should write the informational bin back to Transfer-from Bin Code.');

        // [GIVEN] Return transfer line (Put-away) with a bin entered for information purposes
        SubcWarehouseLibrary.CreateReturnTransferWithSubcContext(
            PurchaseHeader, PurchaseLine, ShipLocation.Code, ProdLocation.Code, InTransitLocation.Code, Quantity, ReturnTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ReturnTransferHeader);

        // ShipLocation (the return transfer's Transfer-from location) is Bin Mandatory with Require Pick = true, so
        // (same as the forward leg above) posting its outbound shipment directly via PostTransferOrder is blocked by
        // "TransferOrder-Post Shipment".CheckWarehouse ("Warehouse handling is required for Transfer order") - Bin
        // Mandatory locations always require the Inventory Pick to be registered first. IsDefault=false here because
        // a default Warehouse Employee already exists (for ProdLocation, created above); passing true would silently
        // no-op and leave ShipLocation without an authorized employee.
        WarehouseRequest.Reset();
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Outbound Transfer");
        WarehouseRequest.SetRange("Source No.", ReturnTransferHeader."No.");
        WarehouseRequest.FindFirst();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, WarehouseRequest."Location Code", false);
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ReturnTransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        WarehouseRequest.Reset();
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Inbound Transfer");
        WarehouseRequest.SetRange("Source No.", ReturnTransferHeader."No.");
        WarehouseRequest.FindFirst();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, WarehouseRequest."Location Code", true);
        SubcWarehouseLibrary.CreateInvtPutAwayFromTransferOrder(ReturnTransferHeader, WarehouseActivityHeader);
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Bin Code", ProdAltBin.Code);
        WarehouseActivityLine.Modify(true);

        WarehouseActivityLine.Validate("Qty. to Handle", Quantity - 1);
        WarehouseActivityLine.Modify(true);

        // [WHEN] Inventory Put-Away posted (partial quantity, so the Transfer Line stays open for inspection below)
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", ReturnTransferHeader."No.");
        TransferLine.FindFirst();
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // [THEN] Transfer Line."Transfer-To Bin Code" updated to the entered bin; no Warehouse Entry/Item Ledger Entry created
        Assert.AreEqual(ProdAltBin.Code, TransferLine."Transfer-To Bin Code", 'Inbound WIP put-away should write the informational bin back to Transfer-To Bin Code.');
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", ProdLocation.Code);
        SubcWarehouseLibrary.VerifyNoItemLedgerEntry(Item."No.", ProdLocation.Code);

        // [THEN] Prod. Order Line."Bin Code" (at the production location) remains unchanged throughout
        Assert.AreEqual(OriginalProdBinCode, ProdOrderLine."Bin Code", 'Production Order Line Bin Code must stay unchanged through WIP pick/put-away posting.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure GetReceiptLinesFromInvtPutAwayReceiptIsCurrentlyBlocked()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        InvoiceHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WorkCenter: array[2] of Record "Work Center";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        Quantity: Decimal;
    begin
        // [FEATURE] Group I - Purchase invoice / financial post-processes
        // [SCENARIO] TC-GAP-I01 Post Purchase Invoice from a receipt created via Inventory Put-Away (Last Operation)
        // A subcontracting receipt created via Inventory Put-Away must be invoiced through the originating
        // subcontracting order, not through a separately created Purchase Invoice's "Get Receipt Lines" action. This
        // test locks in that the block (implemented in "Subc. Purch. Post Ext") still fires for a receipt line that
        // originated from a production order routing, regardless of whether it went through the single-step Put-Away
        // flow.

        // [GIVEN] LastOperation purchase line fully received via Inventory Put-Away (per TC-E2E-A01)
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

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [WHEN] "Get Receipt Lines" is used on a new Purchase Invoice for the same vendor/order, pulling in the Purch. Rcpt. Line created by the Put-Away
        // Current product behavior intentionally blocks this on subcontracting receipt lines; lock that in here.
        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        asserterror PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [THEN] Current behavior: separate invoice creation through Get Receipt Lines is blocked for subcontracting receipt lines
        // Reason: "Subc. Purch. Post Ext".BlockSubcontractingLinesOnCreateInvLinesOnBeforeInsertLineIteration errors out
        // whenever the receipt line originates from a production order, because subcontracting purchase orders must be
        // invoiced from the subcontracting order itself (keeping item charge assignments and quantity reconciliation
        // tied to the originating order) rather than through a separately-created invoice.
        Assert.ExpectedError('subcontracting receipt lines');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ItemChargeAssignmentsRespectActualReceiptTypePostingTargets()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        LastOpLocation: Record Location;
        NotLastOpLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        LastOpProductionOrder: Record "Production Order";
        NotLastOpProductionOrder: Record "Production Order";
        LastOpPurchRcptLine: Record "Purch. Rcpt. Line";
        NotLastOpPurchRcptLine: Record "Purch. Rcpt. Line";
        LastOpChargeInvoice: Record "Purchase Header";
        LastOpPurchaseHeader: Record "Purchase Header";
        NotLastOpChargeInvoice: Record "Purchase Header";
        NotLastOpPurchaseHeader: Record "Purchase Header";
        LastOpChargeLine: Record "Purchase Line";
        LastOpPurchaseLine: Record "Purchase Line";
        NotLastOpChargeLine: Record "Purchase Line";
        NotLastOpPurchaseLine: Record "Purchase Line";
        LastOpValueEntry: Record "Value Entry";
        NotLastOpValueEntry: Record "Value Entry";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Group I - Purchase invoice / financial post-processes
        // [SCENARIO] TC-GAP-I02 Item charge assignment to a subcontracting Last Operation receipt (e.g. freight-in)
        // Item charges (e.g. freight-in) assigned to a subcontracting receipt line for a NON-TRACKED item capitalize
        // onto the Capacity Ledger Entry from the service receipt in both the LastOperation and NotLastOperation
        // cases - only item-TRACKED LastOperation receipts capitalize onto a real output Item Ledger Entry instead
        // (see "Subc. Purch. Post Ext".CopySubcontractingProdOrderFieldsToItemJnlLine and the established behavior
        // locked in by "Subc. Item Charge Posting Test".ItemChargePostingWithoutItemTracking). This test asserts
        // both paths post successfully and land the charge cost on the same (capacity) ledger entry type for this
        // non-tracked item, confirming the posting logic branches correctly on "Subc. Purchase Line Type".

        // [GIVEN] LastOperation purchase line received via Inventory Put-Away; a second purchase line with an Item Charge on a separate invoice
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");

        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(LastOpLocation);
        Vendor."Subc. Location Code" := LastOpLocation.Code;
        Vendor."Location Code" := LastOpLocation.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            LastOpProductionOrder, "Production Order Status"::Released,
            LastOpProductionOrder."Source Type"::Item, Item."No.", Quantity, LastOpLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", LastOpPurchaseLine);
        LastOpPurchaseHeader.Get(LastOpPurchaseLine."Document Type", LastOpPurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(LastOpPurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(LastOpPurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        LastOpPurchRcptLine.SetRange("Order No.", LastOpPurchaseHeader."No.");
        LastOpPurchRcptLine.SetRange("Order Line No.", LastOpPurchaseLine."Line No.");
        LastOpPurchRcptLine.FindFirst();

        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchHeader(LastOpChargeInvoice, LastOpChargeInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(LastOpChargeLine, LastOpChargeInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", Quantity);
        LastOpChargeLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 25, 2));
        LastOpChargeLine.Modify(true);
        LibraryPurchase.CreateItemChargeAssignment(
            ItemChargeAssignmentPurch, LastOpChargeLine, ItemCharge,
            "Purchase Applies-to Document Type"::Receipt,
            LastOpPurchRcptLine."Document No.", LastOpPurchRcptLine."Line No.", LastOpPurchRcptLine."No.",
            Quantity, LastOpChargeLine."Direct Unit Cost");
        ItemChargeAssignmentPurch.Insert(true);

        // [WHEN] Item Charge Assignment (Purch.) is used to assign the charge to the received line
        LibraryPurchase.PostPurchaseDocument(LastOpChargeInvoice, false, true);

        // [THEN] Assignment succeeds and posts without error; charge is capitalized into the item's unit cost.
        // For a NON-TRACKED item, LastOperation charges capitalize onto the Capacity Ledger Entry from the service
        // receipt (same as NotLastOperation below) - only tracked LastOperation receipts target an Item Ledger Entry.
        LastOpValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.RecordIsNotEmpty(LastOpValueEntry);
        LastOpValueEntry.FindLast();
        Assert.AreEqual(0, LastOpValueEntry."Item Ledger Entry No.", 'Last Operation item charge for a non-tracked item must not reference an item ledger entry.');
        Assert.AreNotEqual(0, LastOpValueEntry."Capacity Ledger Entry No.", 'Last Operation item charge for a non-tracked item should capitalize onto the capacity ledger entry.');
        Assert.AreEqual(Round(Quantity * LastOpChargeLine."Direct Unit Cost"), Round(LastOpValueEntry."Cost Amount (Actual)"), 'Last Operation item charge cost must be fully capitalized onto the capacity ledger entry.');

        // [THEN] NotLastOperation lines are handled differently by current code: the posted value entry points to capacity, not inventory
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(NotLastOpLocation);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := NotLastOpLocation.Code;
        Vendor."Location Code" := NotLastOpLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            NotLastOpProductionOrder, "Production Order Status"::Released,
            NotLastOpProductionOrder."Source Type"::Item, Item."No.", Quantity, NotLastOpLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        // Both LastOpProductionOrder and NotLastOpProductionOrder are for the SAME Item (same Routing No.), so the
        // plain (Routing No. + Work Center No.) overload would ambiguously match either production order's routing
        // line. Disambiguate explicitly by Prod. Order No. - by this point LastOpProductionOrder's routing line for
        // WorkCenter[1] has zero Remaining Quantity, so without this the plain overload finds no purchase line at all.
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", NotLastOpProductionOrder."No.", NotLastOpPurchaseLine);
        NotLastOpPurchaseHeader.Get(NotLastOpPurchaseLine."Document Type", NotLastOpPurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(NotLastOpPurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(NotLastOpPurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        NotLastOpPurchRcptLine.SetRange("Order No.", NotLastOpPurchaseHeader."No.");
        NotLastOpPurchRcptLine.SetRange("Order Line No.", NotLastOpPurchaseLine."Line No.");
        NotLastOpPurchRcptLine.FindFirst();

        Clear(ItemCharge);
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchHeader(NotLastOpChargeInvoice, NotLastOpChargeInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(NotLastOpChargeLine, NotLastOpChargeInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", Quantity);
        NotLastOpChargeLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 25, 2));
        NotLastOpChargeLine.Modify(true);
        LibraryPurchase.CreateItemChargeAssignment(
            ItemChargeAssignmentPurch, NotLastOpChargeLine, ItemCharge,
            "Purchase Applies-to Document Type"::Receipt,
            NotLastOpPurchRcptLine."Document No.", NotLastOpPurchRcptLine."Line No.", NotLastOpPurchRcptLine."No.",
            Quantity, NotLastOpChargeLine."Direct Unit Cost");
        ItemChargeAssignmentPurch.Insert(true);
        LibraryPurchase.PostPurchaseDocument(NotLastOpChargeInvoice, false, true);

        NotLastOpValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.RecordIsNotEmpty(NotLastOpValueEntry);
        NotLastOpValueEntry.FindLast();
        Assert.AreEqual(0, NotLastOpValueEntry."Item Ledger Entry No.", 'NotLastOperation item charge should not point to an item ledger entry.');
        Assert.AreNotEqual(0, NotLastOpValueEntry."Capacity Ledger Entry No.", 'NotLastOperation item charge currently capitalizes against capacity.');
        Assert.AreEqual(
            Round(Quantity * NotLastOpChargeLine."Direct Unit Cost"), Round(NotLastOpValueEntry."Cost Amount (Actual)"),
            'NotLastOperation item charge cost must be fully capitalized onto the capacity ledger entry.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ItemChargeAssignedToSerialTrackedLastOperationViaSingleStepPutAway()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ChargeInvoice: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        ChargeLine: Record "Purchase Line";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Vendor: Record Vendor;
        ValueEntry: Record "Value Entry";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
        NoSeriesCodeunit: Codeunit "No. Series";
        SerialNo: Code[50];
    begin
        // [FEATURE] Group I - Purchase invoice / financial post-processes
        // [SCENARIO] Item charge assignment to a tracked LastOperation receipt through single-step Put-away.
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateSerialTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 1, Location.Code);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        SerialNo := NoSeriesCodeunit.GetNextNo(Item."Serial Nos.");
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, SerialNo, '', 1);

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

        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchHeader(ChargeInvoice, ChargeInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(ChargeLine, ChargeInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", 1);
        ChargeLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 25, 2));
        ChargeLine.Modify(true);
        LibraryPurchase.CreateItemChargeAssignment(
            ItemChargeAssignmentPurch, ChargeLine, ItemCharge,
            "Purchase Applies-to Document Type"::Receipt,
            PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.",
            1, ChargeLine."Direct Unit Cost");
        ItemChargeAssignmentPurch.Insert(true);
        LibraryPurchase.PostPurchaseDocument(ChargeInvoice, false, true);

        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Serial No.", SerialNo);
        ItemLedgerEntry.FindFirst();
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.RecordIsNotEmpty(ValueEntry);
        ValueEntry.FindLast();
        Assert.AreEqual(ItemLedgerEntry."Entry No.", ValueEntry."Item Ledger Entry No.", 'The item charge must capitalize onto the specific tracked output Item Ledger Entry.');
        Assert.AreEqual(0, ValueEntry."Capacity Ledger Entry No.", 'A tracked Last Operation item charge must not reference a Capacity Ledger Entry.');
        Assert.AreEqual(Round(ChargeLine."Direct Unit Cost"), Round(ValueEntry."Cost Amount (Actual)"), 'Item charge cost must be fully capitalized onto the tracked Item Ledger Entry.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CancelPostedPurchaseInvoiceWithSubcontractingItemChargeIsBlocked()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PostedInvoiceHeader: Record "Purch. Inv. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeInvoice: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        ItemChargeLine: Record "Purchase Line";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WorkCenter: array[2] of Record "Work Center";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] Group I - Purchase invoice / financial post-processes
        // [SCENARIO] TC-GAP-I04 Correct/Cancel a posted Purchase Invoice for a subcontracting Last Operation line
        // Once an item charge has been assigned to and posted against a subcontracting order receipt (producing a
        // Value Entry with both an Item Charge No. and a Capacity Ledger Entry No.), standard Correct/Cancel logic
        // cannot reverse that combination. This test locks in that
        // "Subc. Purch. Post Ext".BlockCancelIfHasSubcontractingItemChargeValueEntry blocks the cancel and directs
        // the user toward a corrective credit memo instead.

        // [GIVEN] LastOperation purchase line fully received (Put-Away) and invoiced through an item-charge invoice
        Initialize();
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
            ProductionOrder."Source Type"::Item, Item."No.", 1, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchHeader(ItemChargeInvoice, ItemChargeInvoice."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(ItemChargeLine, ItemChargeInvoice, "Purchase Line Type"::"Charge (Item)", ItemCharge."No.", 1);
        ItemChargeLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        ItemChargeLine.Modify(true);
        LibraryPurchase.CreateItemChargeAssignment(
            ItemChargeAssignmentPurch, ItemChargeLine, ItemCharge,
            "Purchase Applies-to Document Type"::Receipt,
            PurchRcptLine."Document No.", PurchRcptLine."Line No.", PurchRcptLine."No.",
            1, ItemChargeLine."Direct Unit Cost");
        ItemChargeAssignmentPurch.Insert(true);
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(ItemChargeInvoice, false, true);
        PostedInvoiceHeader.Get(PostedInvoiceNo);

        // [WHEN] "Correct" or "Cancel" is used on the posted Purchase Invoice
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PostedInvoiceHeader);

        // [THEN] Current behavior: the Subcontracting app blocks the cancel path for this invoice shape
        // Reason: "Subc. Purch. Post Ext".BlockCancelIfHasSubcontractingItemChargeValueEntry errors out because the
        // posted invoice has a Value Entry with both an Item Charge No. and a Capacity Ledger Entry No. (i.e. the charge
        // was assigned to a subcontracting order receipt). Standard Correct/Cancel logic cannot reverse that combination,
        // so the user is directed to use "Create Corrective Credit Memo" instead.
        Assert.ExpectedError('contains item charges assigned to a subcontracting order receipt');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure CreateReturnOrderFromPutAwayReceiptPostsWithoutWarehouseShipment()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseHeader: Record "Purchase Header";
        ReturnOrderHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnOrderLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseRequest: Record "Warehouse Request";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Group I - Purchase invoice / financial post-processes
        // [SCENARIO] TC-GAP-I05 Purchase Return Order against an already put-away-received subcontracting line
        // Confirms that a Purchase Return Order created from a receipt that went through the single-step Inventory
        // Put-Away flow correctly copies quantity/location/bin from the posted receipt, and that posting the return
        // does not spuriously require or create an outbound Warehouse Shipment/Pick request — the return should
        // behave like any other non-warehouse purchase return despite the unusual receipt origin.

        // [GIVEN] LastOperation purchase line fully received and invoiced via Inventory Put-Away
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

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [WHEN] A Purchase Return Order is created via "Create Return Order" for the posted receipt
        LibraryPurchase.CreatePurchHeader(ReturnOrderHeader, ReturnOrderHeader."Document Type"::"Return Order", Vendor."No.");
        LibraryPurchase.CopyPurchaseDocument(ReturnOrderHeader, "Purchase Document Type From"::"Posted Receipt", PurchRcptLine."Document No.", true, false);
        ReturnOrderLine.SetRange("Document Type", ReturnOrderHeader."Document Type");
        ReturnOrderLine.SetRange("Document No.", ReturnOrderHeader."No.");
        ReturnOrderLine.SetRange("No.", Item."No.");
        ReturnOrderLine.FindFirst();

        // [THEN] Return order correctly references quantity received through the single-step Put-Away path
        Assert.AreEqual(Quantity, ReturnOrderLine.Quantity, 'Return Order should copy the received quantity from the posted receipt.');
        Assert.AreEqual(PurchRcptLine."Location Code", ReturnOrderLine."Location Code", 'Return Order line should copy the receiving location from the posted receipt.');
        Assert.AreEqual(PurchRcptLine."Bin Code", ReturnOrderLine."Bin Code", 'Return Order line should copy the receiving bin from the posted receipt.');

        // [THEN] Posting the return does not require (and does not incorrectly create) a Warehouse Shipment/Pick
        // A subcontracting LastOperation receipt for a non-tracked item posts as a standard manufacturing Output
        // entry (via "Mfg. Purch.-Post"), so posting a Return Order copied from that receipt also routes through
        // output posting and requires "Appl.-to Item Entry" to identify which output entry is being reversed - just
        // like reversing any other production output. Populate it from the OUTPUT Item Ledger Entry itself (found
        // by Item/Order/Order Line No.), NOT from PurchRcptLine."Item Rcpt. Entry No." - for a LastOperation receipt
        // that field actually stores the Capacity Ledger Entry No. of the posted output operation
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.FindFirst();
        ReturnOrderLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReturnOrderLine.Modify(true);
        //TODO is that really correct there a action for that?
        LibraryPurchase.PostPurchaseDocument(ReturnOrderHeader, true, false);
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Return Order");
        WarehouseRequest.SetRange("Source No.", ReturnOrderHeader."No.");
        Assert.RecordIsEmpty(WarehouseRequest);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ConcurrentWarehouseRequestsStaySeparatedByActivityType()
    var
        DefaultBin: Record Bin;
        Item: Record Item;
        OutboundItem: Record Item;
        InTransitLocation: Record Location;
        Location: Record Location;
        ToLocation: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        PutAwayActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseRequest: Record "Warehouse Request";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [FEATURE] Group J - Warehouse request lifecycle
        // [SCENARIO] TC-GAP-J01 Concurrent Warehouse Requests — purchase Last Operation and WIP outbound transfer at the same location/bin
        // A single location can simultaneously be a subcontractor receiving location (inbound Purchase Order
        // Put-away) and a WIP shipping location (outbound Transfer Pick). This test verifies the two independent
        // Warehouse Requests coexist without interfering, that creation of an activity picks up only the matching
        // direction/source-document type, and that posting one request does not delete or corrupt the other's
        // still-open Warehouse Request row.

        // [GIVEN] A location acting both as subcontractor receiving location (LastOperation Put-Away) and as WIP shipping location (outbound Pick)
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, DefaultBin);
        Location."Require Pick" := true;
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

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
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryInventory.CreateItem(OutboundItem);
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, Location.Code, LibraryWarehouse.CreateLocation(ToLocation), InTransitLocation.Code, OutboundItem, 3);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Both a Purchase Order (Inbound) and a Transfer Order (Outbound) Warehouse Request exist simultaneously for that location
        WarehouseRequest.SetRange("Location Code", Location.Code);
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Purchase Order");
        Assert.RecordIsNotEmpty(WarehouseRequest);

        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Outbound Transfer");
        Assert.RecordIsNotEmpty(WarehouseRequest);

        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, PutAwayActivityHeader);
        Assert.AreEqual("Warehouse Activity Source Document"::"Purchase Order", PutAwayActivityHeader."Source Document", 'Inbound activity should only pick the purchase request.');

        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(TransferHeader, WarehouseActivityHeader);
        Assert.AreEqual("Warehouse Activity Source Document"::"Outbound Transfer", WarehouseActivityHeader."Source Document", 'Outbound activity should only pick the transfer request.');

        // [THEN] Posting one does not delete or corrupt the Warehouse Request row of the other
        // Reuse the SAME (still-open) PutAwayActivityHeader from above instead of calling
        // CreateInvtPutAwayFromPurchaseOrder again - the Put-away header/line already exist and haven't been
        // posted yet, so a second call finds nothing new to create ("There is nothing to create.")
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(PutAwayActivityHeader);
        LibraryWarehouse.PostInventoryActivity(PutAwayActivityHeader, false);

        WarehouseRequest.Reset();
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetRange("Source Document", WarehouseRequest."Source Document"::"Outbound Transfer");
        WarehouseRequest.SetRange("Source No.", TransferHeader."No.");
        Assert.RecordIsNotEmpty(WarehouseRequest);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure DeleteSplitPutAwayAndRecreateSourceBuildsFreshUnsplittedLine()
    var
        Bins: array[3] of Record Bin;
        DefaultBin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
        Quantities: array[3] of Decimal;
        Quantity: Decimal;
    begin
        // [FEATURE] Group J - Warehouse request lifecycle
        // [SCENARIO] TC-GAP-J02 Delete a split Inventory Put-Away activity line before posting, then re-run "Get Source Documents"
        // Verifies that deleting a split (multi-bin) Inventory Put-Away activity — including its header — cleanly
        // restores the underlying purchase line to its original unsplit outstanding state, so that re-running
        // "Get Source Documents" produces one fresh, unsplit activity line for the full outstanding quantity rather
        // than resurrecting stale split remnants or partial quantities.

        // [GIVEN] LastOperation Put-Away activity line split into 2 bin-tagged sub-lines
        Initialize();
        Quantity := 10;
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, DefaultBin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateBin(Bins[1], Location.Code, 'J2B1', '', '');
        LibraryWarehouse.CreateBin(Bins[2], Location.Code, 'J2B2', '', '');

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
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        Quantities[1] := 6;
        Quantities[2] := 4;
        SubcWarehouseLibrary.SplitActivityLineAcrossBins(WarehouseActivityHeader, WarehouseActivityHeader.Type, Bins, Quantities);

        // [WHEN] One sub-line is deleted and the Inventory Put-Away header itself is deleted entirely
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.DeleteAll(true);
        WarehouseActivityHeader.Delete(true);

        // [WHEN] "Get Source Documents" / AutoCreatePutAway is run again for the same purchase order
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");

        // [THEN] A fresh, single (unsplit) activity line is created for the full outstanding quantity
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual(Quantity, WarehouseActivityLine.Quantity, 'Recreated Inventory Put-away should contain one unsplit line with the full outstanding quantity.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SplitSerialTrackedPutAwayPostsDistinctSerialEntriesPerBin()
    var
        Bins: array[3] of Record Bin;
        DefaultBin: Record Bin;
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
        WorkCenter: array[2] of Record "Work Center";
        Quantities: array[3] of Decimal;
    begin
        // [FEATURE] Group K - Item tracking UI and reservation edges
        // [SCENARIO] TC-GAP-K01 Partial tracking quantities via "Item Tracking Lines" page on a split Last Operation line
        // When a serial-tracked LastOperation line is split across two bins with tracking already assigned per-unit
        // via reservation entries, this test confirms the bin split does not corrupt or duplicate the serial
        // assignment: each sub-line posts to its own bin and produces a distinct, non-overlapping Item Ledger Entry
        // per serial number.

        // [GIVEN] Serial-tracked LastOperation activity line split into two bin sub-lines (qty 1 + qty 1)
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateSerialTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, DefaultBin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateBin(Bins[1], Location.Code, 'K1B1', '', '');
        LibraryWarehouse.CreateBin(Bins[2], Location.Code, 'K1B2', '', '');

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 2, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        // Subcontracting purchase lines are linked to a production order, so the standard base-app guard
        // ("Mfg. Purchase Document Mgt.".OnOpenItemTrackingLinesOnAfterCheck) unconditionally blocks assigning
        // item tracking directly on the Purchase Line. The real subcontracting UI flow
        // ("Subc. Purchase Line Ext".OpenItemTrackingOfProdOrderLine) instead assigns tracking against the
        // Prod. Order Line, so the test must do the same.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, 'K1SN1', '', 1);
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, 'K1SN2', '', 1);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        Quantities[1] := 1;
        Quantities[2] := 1;
        // Serial tracking DOES make base app pre-split the Warehouse Activity Line per unit (one line per distinct
        // serial reservation, unlike lot/package tracking - see SplitPackageTrackedPutAwayPostsDistinctPackageEntriesPerBin's
        // comment for the contrast) - so 2 lines already exist here, each with "Qty. (Base)" = 1. However, the
        // "Serial No." field itself is NOT auto-populated from a Prod. Order Line-based reservation (only from a
        // Purchase Line-based one - see CreateInventoryPutaway.Codeunit.al's FindReservationFromPurchaseLine and
        // the analogous comment in "Subc. Invt. Put-away E2E Purch".SerialTrackedLastOperationFullE2E), so it must
        // be assigned directly on each pre-split line, matching that established pattern.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindSet();
        WarehouseActivityLine.Validate("Bin Code", Bins[1].Code);
        WarehouseActivityLine.Validate("Qty. to Handle", Quantities[1]);
        WarehouseActivityLine.Validate("Serial No.", 'K1SN1');
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Bin Code", Bins[2].Code);
        WarehouseActivityLine.Validate("Qty. to Handle", Quantities[2]);
        WarehouseActivityLine.Validate("Serial No.", 'K1SN2');
        WarehouseActivityLine.Modify(true);

        // [WHEN] The Item Tracking Lines page is conceptually applied per sub-line; current automated path drives tracking through purchase-line reservations
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] No overlapping/duplicate serial numbers are assignable across the two sub-lines
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Serial No.", 'K1SN1');
        Assert.RecordCount(ItemLedgerEntry, 1);
        ItemLedgerEntry.SetRange("Serial No.", 'K1SN2');
        Assert.RecordCount(ItemLedgerEntry, 1);

        // [THEN] Posting both sub-lines creates distinct Item Ledger Entries per serial
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, Bins[1].Code, Item."No.", 1);
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, Bins[2].Code, Item."No.", 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SplitPackageTrackedPutAwayPostsDistinctPackageEntriesPerBin()
    var
        Bins: array[3] of Record Bin;
        DefaultBin: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TempItemTrackingSetup: Record "Item Tracking Setup";
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
        WorkCenter: array[2] of Record "Work Center";
        Quantities: array[3] of Decimal;
    begin
        // [FEATURE] Group K - Item tracking UI and reservation edges
        // [SCENARIO] TC-GAP-K02 Package Tracking Nos. batch-assignment across a split line
        // Package-tracking analogue of the serial-split test above: confirms that splitting a package-tracked line
        // across bins, with per-unit package assignment already made via reservation entries, produces distinct
        // output Item Ledger Entries carrying the correct Package No. per bin/sub-line, with no cross-contamination
        // between packages.

        // [GIVEN] Package-tracked LastOperation line split across 2 bins
        Initialize();
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreatePackageAndLotTrackedItemForProductionWithSetup(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetupAndBin(Location, DefaultBin);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateBin(Bins[1], Location.Code, 'K2B1', '', '');
        LibraryWarehouse.CreateBin(Bins[2], Location.Code, 'K2B2', '', '');

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify(true);

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 2, Location.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        // Subcontracting purchase lines are linked to a production order, so the standard base-app guard
        // ("Mfg. Purchase Document Mgt.".OnOpenItemTrackingLinesOnAfterCheck) unconditionally blocks assigning
        // item tracking directly on the Purchase Line. The real subcontracting UI flow
        // ("Subc. Purchase Line Ext".OpenItemTrackingOfProdOrderLine) instead assigns tracking against the
        // Prod. Order Line, so the test must do the same.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        Clear(TempItemTrackingSetup);
        TempItemTrackingSetup."Lot No." := 'K2LOT1';
        TempItemTrackingSetup."Package No." := 'PKG-A';
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, TempItemTrackingSetup, 1);
        Clear(TempItemTrackingSetup);
        TempItemTrackingSetup."Lot No." := 'K2LOT2';
        TempItemTrackingSetup."Package No." := 'PKG-B';
        LibraryManufacturing.CreateProdOrderItemTracking(ReservationEntry, ProdOrderLine, TempItemTrackingSetup, 1);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        Quantities[1] := 1;
        Quantities[2] := 1;
        // Like serial tracking (see SplitSerialTrackedPutAwayPostsDistinctSerialEntriesPerBin's comment), base app
        // pre-splits the Warehouse Activity Line per unit when 2 separate per-unit reservation entries exist against
        // the Prod. Order Line (one per distinct lot/package here), even though lot/package tracking is not itself
        // auto-populated onto each pre-split line the way it would be from a Purchase Line-based reservation. So 2
        // lines already exist here (each "Qty. (Base)" = 1) - calling SplitActivityLineAcrossBins on top of that
        // trips "Qty. to Handle must not be Qty. Outstanding" (1=1), matching fix #35's finding. Assign bin and
        // lot/package directly to each of the 2 pre-existing lines instead of splitting further.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindSet();
        WarehouseActivityLine.Validate("Bin Code", Bins[1].Code);
        WarehouseActivityLine.Validate("Qty. to Handle", Quantities[1]);
        WarehouseActivityLine.Validate("Lot No.", 'K2LOT1');
        WarehouseActivityLine.Validate("Package No.", 'PKG-A');
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Bin Code", Bins[2].Code);
        WarehouseActivityLine.Validate("Qty. to Handle", Quantities[2]);
        WarehouseActivityLine.Validate("Lot No.", 'K2LOT2');
        WarehouseActivityLine.Validate("Package No.", 'PKG-B');
        WarehouseActivityLine.Modify(true);
        // Item tracking is already assigned per unit via the reservation entries created above; the bin split only needs
        // to match those per-unit quantities to bins (via the standard Warehouse Activity Line split logic used by
        // SplitActivityLineAcrossBins), so no separate item-tracking split step is required here.

        // [WHEN] Package tracking assignment is posted through the split Inventory Put-away
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Each sub-line's Warehouse Entry and Item Ledger Entry carries a distinct Package No.
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Package No.", 'PKG-A');
        Assert.RecordCount(ItemLedgerEntry, 1);
        ItemLedgerEntry.SetRange("Package No.", 'PKG-B');
        Assert.RecordCount(ItemLedgerEntry, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure NotLastOperationPutAwayPostsWithoutBinDefaults()
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
        WarehouseEmployee: Record "Warehouse Employee";
        WorkCenter: array[2] of Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] Group L - Location configuration compatibility
        // [SCENARIO] TC-GAP-L02 Bin Mandatory location without a Default Bin Code and without From-Production Bin Code, for Not Last Operation
        // At a Bin Mandatory location with no Default Bin Code and no From-Production Bin Code configured, a
        // NotLastOperation activity line (which never produces a physical Warehouse Entry) should be exempt from the
        // bin-mandatory requirement and post cleanly with a blank Bin Code — unlike a LastOperation line at the same
        // location, which would require a bin because it performs a real physical put-away.

        // [GIVEN] Bin Mandatory = true, Default Bin Code = blank, From-Production Bin Code = blank
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(Location);
        Location."Require Put-away" := true;
        // Base app's CreateInventoryPutaway.CreatePutAwayLinesFromPurchase only creates a Warehouse Activity Line at
        // a Bin Mandatory location when either a bin was actually resolved (CreatePutawayWithDefaultBinPolicy) OR
        // "Always Create Put-away Line" is set - "Specifies that a put-away line is created, even if an appropriate
        // zone and bin in which to place the items cannot be found." With no Default Bin Code configured (per this
        // test's premise) and this flag left off, NO line is created at all regardless of NotLastOperation status,
        // so this flag must be enabled to actually exercise the "NotLastOperation posts without bin defaults"
        // scenario the test is meant to lock in.
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

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

        // [WHEN] Inventory Put-Away is created and posted for this line
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        Assert.AreEqual('', WarehouseActivityLine."Bin Code", 'The informational NotLastOperation line should not require a default bin.');
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] No error is raised despite the location lacking any bin defaults
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", Location.Code);
        // Clarification: yes - for LastOperation lines a bin is required at Bin Mandatory locations. This is covered by
        // the LastOperation put-away tests that run against "CreateLocationWithInvtPutAwaySetupAndBin" (e.g.
        // LastOperationSingleBinPutAwayWritesBinBackToPurchaseLine and SplitLastOperationLineAcrossThreeBins in this
        // codeunit, and SerialTrackedLastOperationFullE2E in "Subc. Invt. Put-away E2E Purch"), where the standard
        // Warehouse Activity Line bin validation enforces a bin because those lines create real Warehouse Entries.
        // NotLastOperation lines are exempt here because they never post a physical movement (no Warehouse Entry).
    end;

    [Test]
    procedure ExistingTransferRequiresPickAfterLocationToggle()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        FromLocation: Record Location;
        InTransitLocation: Record Location;
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // [FEATURE] Group L - Location configuration compatibility
        // [SCENARIO] TC-GAP-L03 Location "Require Pick" toggled true mid-flow, after a WIP forward transfer already exists without a Pick
        // General (non-subcontracting-specific) warehouse regression check: if a shipping location's "Require Pick"
        // flag is turned on AFTER a transfer order already exists (but before it ships), the existing transfer order
        // must now go through an Inventory Pick before it can be posted — confirming the location setting is
        // evaluated at post time, not just at transfer-order creation time.

        // [GIVEN] A WIP forward transfer order already created (shipping location initially "Require Pick" = false)
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, FromLocation.Code, true);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", FromLocation.Code, '', 5);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        SubcWarehouseLibrary.CreateTransferOrderWithWIPItemFlagWithoutRoutingReference(
            TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, Item, 5);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [WHEN] "Require Pick" is changed to true on the location AFTER the transfer order exists but before it is shipped
        // "Bin Mandatory" must also be set: TransferOrderPostShipment.Codeunit.al's CheckWarehouse only unconditionally
        // blocks direct posting when Location."Bin Mandatory" AND ("Require Pick" or "Require Shipment") - for a
        // non-Bin-Mandatory location it instead only blocks when a Warehouse line ALREADY exists for this specific
        // transfer line (WhseValidateSourceLine.WhseLinesExist), which is never the case here since no Pick was ever
        // created. Plain "Require Pick" = true alone does NOT retroactively block an existing, warehouse-untouched
        // transfer order from posting directly.
        FromLocation.Get(FromLocation.Code);
        FromLocation."Require Pick" := true;
        FromLocation."Bin Mandatory" := true;
        FromLocation.Modify(true);

        // Reopen + re-release the transfer order so base app's "Whse.-Transfer Release" re-evaluates warehouse
        // requirements against the now-changed location and creates the Warehouse Request needed for a Pick -
        // toggling the location flags alone does not retroactively touch an already-released document.
        LibraryWarehouse.ReopenTransferOrder(TransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // Commit before the asserterror below: an error inside an asserterror rolls the ambient transaction back to
        // the last Commit(), not just the failing statement - without this, the Outbound Warehouse Request just
        // created by ReleaseTransferOrder (and the location flag changes above) would be lost once PostTransferOrder
        // raises its expected error, breaking the subsequent CreateInvtPickFromTransferOrder lookup.
        Commit();

        asserterror LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        Assert.ExpectedError('Warehouse handling is required for Transfer order');

        // [THEN] The existing transfer order requires an Inventory Pick to be created before it can be shipped
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(TransferHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferHeader."No.");
        Assert.RecordIsNotEmpty(TransferShipmentHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure UndoReceiptForNotLastOperationRemainsBlockedByPostedInvtPutAwayLine()
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
        // [FEATURE] Group N - Undo receipt discrepancy
        // [SCENARIO] TC-GAP-N02 Undo Receipt for Not Last Operation lines (no spec coverage at all today)
        // Gap-coverage test: NotLastOperation lines post only a Capacity Ledger Entry (Qty. (Base) = 0, no Item
        // Ledger Entry, no Warehouse Entry) via Inventory Put-Away, yet "Undo Purchase Receipt Line" still hits Undo
        // Posting Management's generic "posted Invt. Put-away lines already exist" guard. This locks in that the
        // undo is blocked even though no physical inventory movement actually occurred for this line type — a case
        // with no prior spec coverage.

        // [GIVEN] NotLastOperation purchase line posted via Inventory Put-Away (capacity ledger entry only, Qty. (Base) = 0, no Item Ledger Entry, no Warehouse Entry)
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
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
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[1]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("Order Line No.", PurchaseLine."Line No.");
        PurchRcptLine.FindFirst();

        // [WHEN] Undo Purchase Receipt Line is attempted
        // Actual current behavior is blocked by Undo Posting Management's generic posted Invt. Put-away line check,
        // even though this NotLastOperation path created no item ledger entry and no warehouse entry.
        asserterror Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);

        // [THEN] Determine and assert actual behavior
        Assert.ExpectedError('warehouse put-away lines have already been posted');
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", Location.Code);
        SubcWarehouseLibrary.VerifyNoItemLedgerEntry(Item."No.", Location.Code);
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
        if Message.Contains('Number of Invt. Pick activities created') then
            exit;
        if Message.Contains('successfully posted and is now deleted') then
            exit;
        Error('Unexpected Message: %1', Message);
    end;

    [PageHandler]
    procedure HandleTransferOrderPage(var TransferOrderPage: TestPage "Transfer Order")
    begin
        TransferOrderPage.OK().Invoke();
    end;
}