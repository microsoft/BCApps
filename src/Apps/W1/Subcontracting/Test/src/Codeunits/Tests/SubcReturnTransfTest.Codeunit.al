// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Structure;
using System.TestLibraries.Utilities;

codeunit 149917 "Subc. Return Transf. Test"
{
    // [FEATURE] Subcontracting Return Transfer Order - second return after first is posted
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder,TransferOrderPostedMessageHandler')]
    procedure SecondReturnFromSubcontractorSucceedsAfterFirstReturnPosted()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderComp: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        PurchaseHeaderPage: TestPage "Purchase Order";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [SCENARIO 634269] Creating a second return from subcontractor must succeed after the first return is posted and deleted.

        // [GIVEN] Setup manufacturing with subcontracting transfer
        Initialize();
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        UnitCostCalculation := UnitCostCalculation::Units;

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        // [GIVEN] Create production order and subcontracting PO
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 10);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [GIVEN] Find PO and create outbound transfer order
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
#pragma warning disable AA0210
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();

        // [GIVEN] Find and post the outbound transfer order (direct transfer)
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.FindFirst();
        TransferHeader.Get(TransferLine."Document No.");

        Item.Get(ProdOrderComp."Item No.");
        Location.Get(TransferHeader."Transfer-from Code");
        CreateInventory(Item, Location, Bin, ProdOrderComp."Expected Qty. (Base)");

        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
        TransferOrder.OpenView();
        TransferOrder.GoToRecord(TransferHeader);
        TransferOrder.Post.Invoke();

        // [GIVEN] Create first return and post it
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.FindFirst();
        TransferHeader.Get(TransferLine."Document No.");

        Location.Get(TransferHeader."Transfer-from Code");
        CreateInventory(Item, Location, Bin, ProdOrderComp."Expected Qty. (Base)");

        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Modify(true);
        Clear(TransferOrder);
        TransferOrder.OpenView();
        TransferOrder.GoToRecord(TransferHeader);
        TransferOrder.Post.Invoke();

        // [WHEN] Create second return from subcontractor
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateReturnFromSubcontractor.Invoke();

        // [THEN] Second return transfer order is created successfully
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Item No.", ProdOrderComp."Item No.");
        TransferLine.FindFirst();
        TransferHeader.Get(TransferLine."Document No.");
        Assert.AreNotEqual('', TransferHeader."No.", 'Second return transfer order must be created');
        Assert.AreNotEqual(TransferHeader."Transfer-from Code", TransferHeader."Transfer-to Code",
            'Transfer-from and Transfer-to must not be the same');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Return Transf. Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryVariableStorage.Clear();
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Return Transf. Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Return Transf. Test");
    end;

    local procedure CreateInventory(Item: Record Item; Location: Record Location; var Bin: Record Bin; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        ItemJournalLine.Validate("Location Code", Location.Code);
        if Location."Require Put-away" then begin
            LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
            ItemJournalLine.Validate("Bin Code", Bin.Code);
        end;
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    [PageHandler]
    procedure HandleTransferOrder(var TransfOrderPage: TestPage "Transfer Order")
    begin
        TransfOrderPage.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure DoNotConfirmShowCreatedPurchOrderForSubcontracting(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure TransferOrderPostedMessageHandler(Message: Text[1024])
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;
        UnitCostCalculation: Enum "Unit Cost Calculation Type";
}
