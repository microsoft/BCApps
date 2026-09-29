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
        SubcontractingMgmtLibrary.SetupInventorySetup();
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
        // Posting a LastOperation put-away updates the Purchase Line bin without changing the Prod. Order Line bin.

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

        // [WHEN] The activity line is assigned a different bin
        WarehouseActivityLine.Validate("Bin Code", AltBin.Code);
        WarehouseActivityLine.Modify(true);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] The put-away is posted
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // [THEN] The Purchase Line bin is updated
        Assert.AreEqual(AltBin.Code, PurchaseLine."Bin Code", 'Purchase Line Bin Code should be written back from the posted activity line.');

        // [THEN] The Warehouse Entry uses the selected bin
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, AltBin.Code, Item."No.", Quantity);

        // [THEN] The Prod. Order Line bin is unchanged
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
        // [SCENARIO] TC-E2E-H02 Split LastOperation put-away updates the Purchase Line with the processed bin
        // Both split quantities post to their bins; the Purchase Line keeps the bin from the final write-back.

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

        // [WHEN] The put-away line is split between two bins
        SubcWarehouseLibrary.SplitActivityLineAcrossBins(WarehouseActivityHeader, WarehouseActivityHeader.Type, Bins, Quantities);

        // [WHEN] Both split lines are posted
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // [THEN] Warehouse Entries contain the quantity for each bin
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, Bins[1].Code, Item."No.", Quantities[1]);
        SubcWarehouseLibrary.VerifyBinContents(Location.Code, Bins[2].Code, Item."No.", Quantities[2]);

        // [THEN] The Purchase Line reflects the final write-back bin
        Assert.AreEqual(Bins[1].Code, PurchaseLine."Bin Code", 'Purchase Line Bin Code should follow the last processed split line.');

        // [THEN] The Prod. Order Line bin remains unchanged
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
        // [SCENARIO] TC-E2E-H03 NotLastOperation put-away writes its entered bin back to the Purchase Line
        // The informational bin is written back without creating a Warehouse Entry.

        // [GIVEN] A NotLastOperation purchase line with a bin entered on its activity line
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

        // [WHEN] The put-away is posted
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // [THEN] No Warehouse Entry is created
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", Location.Code);

        // [THEN] The Purchase Line bin is updated
        Assert.AreEqual(AltBin.Code, PurchaseLine."Bin Code", 'Purchase Line Bin Code should still be written back for NotLastOperation lines.');

        // [THEN] The Prod. Order Line bin remains unchanged
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
        // [SCENARIO] TC-E2E-H04 WIP transfer pick and put-away write bins back to the Transfer Line
        // WIP transfer lines retain the entered source and destination bins without physical inventory movement.

        // [GIVEN] A WIP outbound transfer line with an alternate pick bin
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
        // The forward pick uses the production location, so both alternate bins belong to that location.
        LibraryWarehouse.CreateBin(PickBin, ProdLocation.Code, 'PICKALT', '', '');
        LibraryWarehouse.CreateBin(ProdAltBin, ProdLocation.Code, 'RETALT', '', '');
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // Default bin content enables creation of the return-leg inventory put-away.
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
        // Use a non-default employee because another location can already have the user's default employee record.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, WarehouseRequest."Location Code", false);
        SubcWarehouseLibrary.CreateInvtPickFromTransferOrder(ForwardTransferHeader, WarehouseActivityHeader);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Bin Code", PickBin.Code);
        WarehouseActivityLine.Modify(true);
        LibraryWarehouse.AutoFillQtyHandleWhseActivity(WarehouseActivityHeader);

        // [WHEN] The inventory pick is posted
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        TransferLine.SetRange("Document No.", ForwardTransferHeader."No.");
        TransferLine.FindFirst();

        // [THEN] The Transfer-from Bin Code is updated
        Assert.AreEqual(PickBin.Code, TransferLine."Transfer-from Bin Code", 'Outbound WIP pick should write the informational bin back to Transfer-from Bin Code.');

        // [GIVEN] A return transfer line with an alternate put-away bin
        SubcWarehouseLibrary.CreateReturnTransferWithSubcContext(
            PurchaseHeader, PurchaseLine, ShipLocation.Code, ProdLocation.Code, InTransitLocation.Code, Quantity, ReturnTransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(ReturnTransferHeader);

        // The Bin Mandatory shipping location requires an inventory pick before shipment.
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

        // [WHEN] A partial inventory put-away is posted
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", ReturnTransferHeader."No.");
        TransferLine.FindFirst();
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        // [THEN] The Transfer-to Bin Code is updated without inventory entries
        Assert.AreEqual(ProdAltBin.Code, TransferLine."Transfer-To Bin Code", 'Inbound WIP put-away should write the informational bin back to Transfer-To Bin Code.');
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", ProdLocation.Code);
        SubcWarehouseLibrary.VerifyNoItemLedgerEntry(Item."No.", ProdLocation.Code);

        // [THEN] The Prod. Order Line bin remains unchanged
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
        // [SCENARIO] TC-GAP-I01 A subcontracting receipt cannot be invoiced through Get Receipt Lines

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

        // [WHEN] Get Receipt Lines is run for a new purchase invoice
        LibraryPurchase.CreatePurchHeader(InvoiceHeader, InvoiceHeader."Document Type"::Invoice, Vendor."No.");
        PurchRcptLine.SetRecFilter();
        PurchGetReceipt.SetPurchHeader(InvoiceHeader);
        asserterror PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [THEN] Separate invoice creation is blocked for the subcontracting receipt
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
        // [SCENARIO] TC-GAP-I02 Item charges on non-tracked subcontracting receipts capitalize to capacity

        // [GIVEN] LastOperation and NotLastOperation receipts with item charges
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

        // [WHEN] The item charge is assigned and posted
        LibraryPurchase.PostPurchaseDocument(LastOpChargeInvoice, false, true);

        // [THEN] The LastOperation charge references the Capacity Ledger Entry
        LastOpValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        Assert.RecordIsNotEmpty(LastOpValueEntry);
        LastOpValueEntry.FindLast();
        Assert.AreEqual(0, LastOpValueEntry."Item Ledger Entry No.", 'Last Operation item charge for a non-tracked item must not reference an item ledger entry.');
        Assert.AreNotEqual(0, LastOpValueEntry."Capacity Ledger Entry No.", 'Last Operation item charge for a non-tracked item should capitalize onto the capacity ledger entry.');
        Assert.AreEqual(Round(Quantity * LastOpChargeLine."Direct Unit Cost"), Round(LastOpValueEntry."Cost Amount (Actual)"), 'Last Operation item charge cost must be fully capitalized onto the capacity ledger entry.');

        // [THEN] The NotLastOperation charge also references the Capacity Ledger Entry
        SubcWarehouseLibrary.CreateLocationWithInvtPutAwaySetup(NotLastOpLocation);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := NotLastOpLocation.Code;
        Vendor."Location Code" := NotLastOpLocation.Code;
        Vendor.Modify(true);
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            NotLastOpProductionOrder, "Production Order Status"::Released,
            NotLastOpProductionOrder."Source Type"::Item, Item."No.", Quantity, NotLastOpLocation.Code);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        // Select the routing line from the NotLastOperation production order.
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
        // [SCENARIO] TC-GAP-I04 Canceling an invoice with a subcontracting item charge is blocked

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

        // [THEN] The cancel action is blocked
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
        // [SCENARIO] TC-GAP-I05 A return order from a put-away receipt posts without warehouse shipment

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

        // [THEN] The return line copies the receipt quantity, location, and bin
        Assert.AreEqual(Quantity, ReturnOrderLine.Quantity, 'Return Order should copy the received quantity from the posted receipt.');
        Assert.AreEqual(PurchRcptLine."Location Code", ReturnOrderLine."Location Code", 'Return Order line should copy the receiving location from the posted receipt.');
        Assert.AreEqual(PurchRcptLine."Bin Code", ReturnOrderLine."Bin Code", 'Return Order line should copy the receiving bin from the posted receipt.');

        // [WHEN] The return line is applied to the posted output entry
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.FindFirst();
        ReturnOrderLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
        ReturnOrderLine.Modify(true);
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
        // [SCENARIO] TC-GAP-J01 Inbound purchase and outbound transfer requests remain separate

        // [GIVEN] A location with inbound purchase and outbound transfer requests
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

        // [WHEN] Both warehouse requests exist at the location
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
        // [SCENARIO] TC-GAP-J02 Recreating a deleted split put-away restores one full outstanding line

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

        // [WHEN] The split lines and their put-away header are deleted
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.DeleteAll(true);
        WarehouseActivityHeader.Delete(true);

        // [WHEN] A new inventory put-away is created for the purchase order
        SubcWarehouseLibrary.CreateInvtPutAwayFromPurchaseOrder(PurchaseHeader, WarehouseActivityHeader);
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");

        // [THEN] One unsplit line contains the full outstanding quantity
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
        // [SCENARIO] TC-GAP-K01 Serial-tracked split lines post distinct serials to separate bins

        // [GIVEN] A serial-tracked LastOperation line with two reservations
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
        // Assign tracking to the linked production order line.
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
        // The reservation creates one activity line per serial; assign the bin and serial to each line.
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

        // [WHEN] The split put-away is posted
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Each serial has one output entry
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Serial No.", 'K1SN1');
        Assert.RecordCount(ItemLedgerEntry, 1);
        ItemLedgerEntry.SetRange("Serial No.", 'K1SN2');
        Assert.RecordCount(ItemLedgerEntry, 1);

        // [THEN] Each bin contains its serial-tracked quantity
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
        // [SCENARIO] TC-GAP-K02 Package-tracked split lines post distinct packages to separate bins

        // [GIVEN] A package-tracked LastOperation line with two reservations
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
        // Assign tracking to the linked production order line.
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
        // The reservations create one activity line per package; assign the bin and tracking values to each line.
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
        // [WHEN] The package-tracked put-away is posted
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Each package has one output entry
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
        // [SCENARIO] TC-GAP-L02 NotLastOperation put-away posts without bin defaults

        // [GIVEN] Bin Mandatory = true, Default Bin Code = blank, From-Production Bin Code = blank
        Initialize();
        Quantity := LibraryRandom.RandIntInRange(5, 10);
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);
        SubcWarehouseLibrary.CreateLocationWithBinMandatoryOnly(Location);
        Location."Require Put-away" := true;
        // Always create the put-away line because this location has no default bin.
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

        // [THEN] No Warehouse Entry is created
        SubcWarehouseLibrary.VerifyNoWarehouseEntry(Item."No.", Location.Code);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
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
        // [SCENARIO] TC-GAP-L03 An existing transfer requires a pick after the location requires picks

        // [GIVEN] A released WIP transfer from a location that does not require picks
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

        // [WHEN] The location is made bin mandatory and requires picks
        FromLocation.Get(FromLocation.Code);
        FromLocation."Require Pick" := true;
        FromLocation."Bin Mandatory" := true;
        FromLocation.Modify(true);

        // Re-release the transfer order to create the warehouse request for the updated location.
        LibraryWarehouse.ReopenTransferOrder(TransferHeader);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // Preserve the location and warehouse-request changes before the expected error.
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
        // [SCENARIO] TC-GAP-N02 Undo receipt is blocked after a NotLastOperation inventory put-away

        // [GIVEN] A NotLastOperation purchase line posted through inventory put-away
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

        // [WHEN] Undo Purchase Receipt Line is run
        asserterror Codeunit.Run(Codeunit::"Undo Purchase Receipt Line", PurchRcptLine);

        // [THEN] Undo is blocked and no inventory entries exist
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