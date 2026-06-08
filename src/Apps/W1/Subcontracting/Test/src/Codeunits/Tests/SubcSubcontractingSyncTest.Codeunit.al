// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
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

codeunit 139992 "Subc. Subcontracting Sync Test"
{ // [FEATURE] Subcontracting Management
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    procedure TestCreationOfPurchOrderFromRtngLineWithSubcontractorWithAddLine()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        Work_Center: Record "Work Center";
        WorkCenter: array[2] of Record "Work Center";
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcCalculateSubcontracts: Report "Subc. Calculate Subcontracts";
        ReqJnlManagement: Codeunit ReqJnlManagement;
        SubTestManSubscription: Codeunit "Subc. Test Man. Subscription";
    begin
        // [SCENARIO] Calculating Subcontracting Deletes Prod Order Quantities

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        BindSubscription(SubTestManSubscription);

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        ManufacturingSetup.Get();
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Vendor-Supplied");

        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);

        UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] Create Subcontracting Purchase Order from Prod. Order Routing
        CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

#pragma warning disable AA0175
        PurchLine.SetRange("No.", Item."No.");
        PurchLine.DeleteAll();
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
#pragma warning disable AA0210
        ProductionBOMLine.SetRange("Component Supply Method", ProductionBOMLine."Component Supply Method"::"Vendor-Supplied");
#pragma warning restore AA0210
        ProductionBOMLine.FindFirst();
#pragma warning restore

        ManufacturingSetup.Get();
        RequisitionLine."Worksheet Template Name" := ManufacturingSetup."Subcontracting Template Name";
        RequisitionLine."Journal Batch Name" := ManufacturingSetup."Subcontracting Batch Name";

        RequisitionLine.FilterGroup := 2;
        RequisitionLine.SetRange("Worksheet Template Name", ManufacturingSetup."Subcontracting Template Name");
        RequisitionLine.FilterGroup := 0;
        ReqJnlManagement.OpenJnl(RequisitionLine."Journal Batch Name", RequisitionLine);

        SubcCalculateSubcontracts.SetWkShLine(RequisitionLine);
        Work_Center.SetRange("No.", WorkCenter[2]."No.");
        SubcCalculateSubcontracts.SetTableView(WorkCenter[2]);
        SubcCalculateSubcontracts.UseRequestPage(false);
        SubcCalculateSubcontracts.RunModal();

        MakeSubconPurchOrder(ProductionOrder."No.", WorkCenter[2]."No.");

        Assert.AreNotEqual(0, ProductionOrder.Quantity, 'Prod. order Qty. must not be zero after calculation of subcontracting in work sheet.');
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess,HandleTransferOrder')]
    procedure ChangeVendorKeepsTransferOrderWhenItemLedgerEntryExistsForProductionOrder()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        ProductionLocation: Record Location;
        InitialTransferOrderNo: Code[20];
    begin
        // [SCENARIO 623643] When an Item Ledger Entry exists for Production Order "P", changing vendor on Subcontracting PO must NOT delete Transfer Order "T"
        Initialize();

        // [GIVEN] Subcontracting setup with Transfer-type Production Order "P" for item "I", Subcontracting PO for vendor "V1", Transfer Order "T"
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10) + 5);
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        ProductionOrder."Created from Purch. Order" := true;
        ProductionOrder.Modify();
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SetAllProdOrderTransferComponentLocations(ProductionOrder."No.", ProductionLocation.Code);
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        PurchaseLine.Validate("Location Code", ProductionLocation.Code);
        PurchaseLine.Modify(true);

        CreateTransferOrderForSubcontractingPO(PurchaseHeader);
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        TransferHeader.FindFirst();
        InitialTransferOrderNo := TransferHeader."No.";

        // [GIVEN] Item Ledger Entry of "Order Type" = Production and "Order No." = "P"
        CreateItemLedgerEntryForProductionOrder(ItemLedgerEntry, ProductionOrder, Item);

        // [GIVEN] Second subcontracting Vendor "V2"
        CreateSecondSubcontractingVendor(Vendor, WorkCenter[2]);

        // [WHEN] Validate "Buy-from Vendor No." on Subcontracting PO to "V2"
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Modify(true);

        // [THEN] Transfer Order "T" still exists
        Assert.IsTrue(TransferHeader.Get(InitialTransferOrderNo), 'Transfer Order must still exist when Item Ledger Entry exists for Production Order');
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess,HandleTransferOrder')]
    procedure ChangeVendorDeletesTransferOrderWhenNoItemLedgerEntryExistsForProductionOrder()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        ProductionLocation: Record Location;
        InitialTransferOrderNo: Code[20];
    begin
        // [SCENARIO 623643] When NO Item Ledger Entry exists for Production Order "P", changing vendor on Subcontracting PO must delete Transfer Order "T"
        Initialize();

        // [GIVEN] Subcontracting setup with Transfer-type Production Order "P", Subcontracting PO for vendor "V1", Transfer Order "T"
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();
        Subcontracting := true;
        UnitCostCalculation := UnitCostCalculation::Units;

        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithComponentSupplyMethod(Item, "Component Supply Method"::"Transfer to Vendor");
        UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ProductionLocation);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", 1);  // Use quantity 1
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        ProductionOrder."Created from Purch. Order" := true;
        ProductionOrder.Modify();
        UpdateSubMgmtSetupWithReqWkshTemplate();
        SetAllProdOrderTransferComponentLocations(ProductionOrder."No.", ProductionLocation.Code);
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);

        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        PurchaseLine.Validate("Location Code", ProductionLocation.Code);
        PurchaseLine.Modify(true);

        CreateTransferOrderForSubcontractingPO(PurchaseHeader);
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        TransferHeader.FindFirst();
        InitialTransferOrderNo := TransferHeader."No.";

        // [GIVEN] No Item Ledger Entry exists with "Order Type" = Production and "Order No." = "P"

        // [GIVEN] Second subcontracting Vendor "V2"
        CreateSecondSubcontractingVendor(Vendor, WorkCenter[2]);

        // [WHEN] Validate "Buy-from Vendor No." on Subcontracting PO to "V2"
        // Pre-clear all blocking relationships to allow Production Order deletion to succeed
        PrepareProdOrderForDeletion(ProductionOrder."No.", PurchaseHeader."No.");

        // Change vendor - triggers deletion logic with ItemLedgerEntry2.IsEmpty() check
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.Modify(true);

        // [THEN] Transfer Order "T" no longer exists
        Assert.IsFalse(TransferHeader.Get(InitialTransferOrderNo), 'Transfer Order must be deleted when no Item Ledger Entry exists for Production Order');
    end;

    local procedure MakeSubconPurchOrder(ProductionOrderNo: Code[20]; WorkCenterNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // Update Direct unit Cost and Make Order,random is used values not important for test.
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrderNo);
        RequisitionLine.SetRange("Work Center No.", WorkCenterNo);
#pragma warning restore AA0210
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutAMSubcontractWksh(RequisitionLine);
    end;

    local procedure CreateAndCalculateNeededWorkAndMachineCenter(var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ShopCalendarCode: Code[10];
        MachineCenterNo: Code[20];
        MachineCenterNo2: Code[20];
        WorkCenterNo: Code[20];
        WorkCenterNo2: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();

        // [GIVEN] Create and Calculate needed Work and Machine Center
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::"Pick + Manual", not Subcontracting, UnitCostCalculation, '');
        WorkCenter[1].Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter[1], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenterNo, "Flushing Method"::"Pick + Manual".AsInteger());
        MachineCenter[1].Get(MachineCenterNo);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter[1], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo2, WorkCenterNo, "Flushing Method"::"Pick + Manual".AsInteger());
        MachineCenter[2].Get(MachineCenterNo2);
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter[2], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));

        if Subcontracting then
            CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::"Pick + Manual", Subcontracting, UnitCostCalculation, '')
        else
            CreateWorkCenter(WorkCenterNo2, ShopCalendarCode, "Flushing Method"::"Pick + Manual", not Subcontracting, UnitCostCalculation, '');
        WorkCenter[2].Get(WorkCenterNo2);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter[2], CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));
    end;

    local procedure CreateItemForProductionIncludeRoutingAndProdBOM(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ProductionBOMHeader: Record "Production BOM Header";
        NoSeries: Codeunit "No. Series";
        ItemNo: Code[20];
        ItemNo2: Code[20];
        ProductionBOMNo: Code[20];
        RoutingNo: Code[20];
    begin
        ManufacturingSetup.SetLoadFields("Routing Nos.");
        ManufacturingSetup.Get();
        RoutingNo := NoSeries.GetNextNo(ManufacturingSetup."Routing Nos.", WorkDate(), true);

        LibraryMfgManagement.CreateRouting(RoutingNo, MachineCenter[1]."No.", MachineCenter[2]."No.", WorkCenter[1]."No.", WorkCenter[2]."No.");

        // Create Items with Flushing method - Manual with the Parent Item containing Routing No. and Production BOM No.

        CreateItem(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", '', '');
        ItemNo := Item."No.";
        Clear(Item);
        CreateItem(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", '', '');
        ItemNo2 := Item."No.";
        Clear(Item);

        ProductionBOMNo := LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ItemNo, ItemNo2, 1); // value important.

        CreateItem(Item, "Costing Method"::FIFO, "Reordering Policy"::"Lot-for-Lot", "Flushing Method"::"Pick + Manual", RoutingNo, ProductionBOMNo);
    end;

    local procedure UpdateProdBomAndRoutingWithRoutingLink(Item: Record Item; WorkCenterNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
    begin
        RoutingLink.Init();
        RoutingLink.Validate(Code, CopyStr(Item."Production BOM No.", 1, 10));
        RoutingLink.Insert(true);

        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenterNo);
        RoutingLine.FindFirst();
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateProdBomWithComponentSupplyMethod(Item: Record Item; ComponentSupplyMethod: Enum "Component Supply Method")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        ProductionBOMLine."Component Supply Method" := ComponentSupplyMethod;
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateVendorWithSubcontractingLocationCode(WorkCenter: Record "Work Center")
    var
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Get(WorkCenter."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
    end;

    procedure CreateWorkCenter(var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10]; FlushingMethod: Enum "Flushing Method"; Subcontract: Boolean; UnitCostCalc: Option; CurrencyCode: Code[10])
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

        if Subcontract then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GenProductPostingGroup.FindFirst();
            GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            GenProductPostingGroup.Modify(true);
            WorkCenter.Validate("Subcontractor No.", SubcManagementLibrary.CreateSubcontractorWithCurrency(CurrencyCode));
        end;
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    local procedure CreateItem(var Item: Record Item; ItemCostingMethod: Enum "Costing Method"; ItemReorderPolicy: Enum "Reordering Policy"; FlushingMethod: Enum "Flushing Method"; RoutingNo: Code[20]; ProductionBOMNo: Code[20])
    begin
        // Create Item with required fields where random values not important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, ItemCostingMethod, LibraryRandom.RandInt(10), ItemReorderPolicy, FlushingMethod, RoutingNo, ProductionBOMNo);
        Item.Validate("Overhead Rate", LibraryRandom.RandDec(5, 2));
        Item.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 2));
        Item.Modify(true);
    end;

    local procedure CreateTransferOrderForSubcontractingPO(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();
        PurchaseHeaderPage.Close();
    end;

    local procedure CreateItemLedgerEntryForProductionOrder(var ItemLedgerEntry: Record "Item Ledger Entry"; ProductionOrder: Record "Production Order"; Item: Record Item)
    begin
        ItemLedgerEntry.Init();
        if ItemLedgerEntry.FindLast() then;
        ItemLedgerEntry."Entry No." += 1;
        ItemLedgerEntry."Item No." := Item."No.";
        ItemLedgerEntry."Order Type" := ItemLedgerEntry."Order Type"::Production;
        ItemLedgerEntry."Order No." := ProductionOrder."No.";
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Output;
        ItemLedgerEntry.Quantity := 1;
        ItemLedgerEntry.Insert();
    end;

    local procedure CreateSecondSubcontractingVendor(var Vendor: Record Vendor; WorkCenter: Record "Work Center")
    var
        Location: Record Location;
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GenProductPostingGroup.Get(WorkCenter."Gen. Prod. Posting Group");
        LibraryMfgManagement.CreateSubcontractorWithCurrency('');
        Vendor.FindLast();
        Vendor."Subc. Location Code" := Location.Code;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
    end;

    local procedure SetAllProdOrderTransferComponentLocations(ProdOrderNo: Code[20]; LocationCode: Code[10])
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
        if ProdOrderComp.FindSet() then
            repeat
                ProdOrderComp."Location Code" := LocationCode;
                ProdOrderComp.Modify();
            until ProdOrderComp.Next() = 0;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Subcontracting Sync Test");
        LibrarySetupStorage.Restore();

        SubcManagementLibrary.Initialize();
        UpdateSubMgmtSetupComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Subcontracting Sync Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Subcontracting Sync Test");
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderSourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, ProdOrderStatus, ProdOrderSourceType, SourceNo, Quantity);
    end;

    local procedure UpdateSubMgmtSetupWithReqWkshTemplate()
    begin
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();
    end;

    local procedure UpdateSubMgmtSetupComponentAtLocation(CompAtLocation: Enum "Components at Location")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup."Subc. Default Comp. Location" := CompAtLocation;
        ManufacturingSetup.Modify();
    end;

    local procedure CreateSubcontractingOrderFromProdOrderRtngPage(RoutingNo: Code[20]; WorkCenterNo: Code[20])
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ReleasedProdOrderRtng: TestPage "Prod. Order Routing";
    begin
        ProdOrderRtngLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRtngLine.SetRange("Work Center No.", WorkCenterNo);
        ProdOrderRtngLine.FindFirst();

        ReleasedProdOrderRtng.OpenView();
        ReleasedProdOrderRtng.GoToRecord(ProdOrderRtngLine);
        ReleasedProdOrderRtng.CreateSubcontracting.Invoke();
    end;

    local procedure PrepareProdOrderForDeletion(ProdOrderNo: Code[20]; PurchDocNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // Keep main Purchase Line with Prod. Order No. so deletion logic runs,
        // but clear Line No. and routing fields to prevent blocking
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchDocNo);
        PurchaseLine.SetRange("Prod. Order No.", ProdOrderNo);
        if PurchaseLine.FindFirst() then begin
            PurchaseLine."Prod. Order Line No." := 0;
            PurchaseLine."Operation No." := '';
            PurchaseLine."Routing No." := '';
            PurchaseLine."Routing Reference No." := 0;
            PurchaseLine."Qty. Received (Base)" := 0;
            PurchaseLine.Modify();
        end;

        // Delete subcontracting Purchase Lines
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Subc. Prod. Order No.", ProdOrderNo);
        PurchaseLine.DeleteAll(true);

        // Delete Production Order parts to allow DeleteProdOrderRelations() to succeed
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComp.DeleteAll(true);

        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRtngLine.DeleteAll(true);

        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.DeleteAll(true);
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

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcManagementLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        Subcontracting: Boolean;
        UnitCostCalculation: Option Time,Units;
}