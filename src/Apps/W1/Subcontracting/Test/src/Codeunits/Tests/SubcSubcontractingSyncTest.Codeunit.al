// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Planning;
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
        SubcontractingManagementSetup: Record "Subc. Management Setup";
        Work_Center: Record "Work Center";
        WorkCenter: array[2] of Record "Work Center";
        CalculateSubcontracts: Report "Calculate Subcontracts";
        ReqJnlManagement: Codeunit ReqJnlManagement;
        SubTestManSubscription: Codeunit "Subc. Test Man. Subscription";
    begin
        // [SCENARIO] Calculating Subcontracting Deletes Prod Order Quantities

        // [GIVEN] Complete Setup of Manufacturing, include Work- and Machine Centers, Item
        Initialize();
        BindSubscription(SubTestManSubscription);

        // [GIVEN] Some Parameters for Creation
        Subcontracting := true;
        SubcontractingManagementSetup.Get();
        UnitCostCalculation := UnitCostCalculation::Units;

        // [GIVEN]
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter);

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);

        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");

        UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Purchase);

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
        ProductionBOMLine.SetRange("Subcontracting Type", ProductionBOMLine."Subcontracting Type"::Purchase);
#pragma warning restore AA0210
        ProductionBOMLine.FindFirst();
#pragma warning restore

        RequisitionLine."Worksheet Template Name" := SubcontractingManagementSetup."Subcontracting Template Name";
        RequisitionLine."Journal Batch Name" := SubcontractingManagementSetup."Subcontracting Batch Name";

        RequisitionLine.FilterGroup := 2;
        RequisitionLine.SetRange("Worksheet Template Name", SubcontractingManagementSetup."Subcontracting Template Name");
        RequisitionLine.FilterGroup := 0;
        ReqJnlManagement.OpenJnl(RequisitionLine."Journal Batch Name", RequisitionLine);

        CalculateSubcontracts.SetWkShLine(RequisitionLine);
        Work_Center.SetRange("No.", WorkCenter[2]."No.");
        CalculateSubcontracts.SetTableView(WorkCenter[2]);
        CalculateSubcontracts.UseRequestPage(false);
        CalculateSubcontracts.RunModal();

        MakeSubconPurchOrder(ProductionOrder."No.", WorkCenter[2]."No.");

        Assert.AreNotEqual(0, ProductionOrder.Quantity, 'Prod. order Qty. must not be zero after calculation of subcontracting in work sheet.');
    end;

    [Test]
    [HandlerFunctions('DoConfirmCreateProdOrderForSubcontractingProcess')]
    procedure TestQuantitySynchronizationAfterCreateProductionOrderFromPurchaseOrder()
    var
        ItemUOM: Record "Item Unit of Measure";
        Location, Location2 : Record Location;
        ProdOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchLine, PurchLine2 : Record "Purchase Line";
        RoutingLink: Record "Routing Link";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SynchMgmt: Codeunit "Subc. Synchronize Management";
        ItemNoOriginPurchLine: Code[20];
        PurchOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO] Create Production Order from Purchase Order from scratch and test Quantity synchronization
        Initialize();

        // [GIVEN] Create Item for Production include Routing and Prod. BOM
        CreateAndCalculateNeededWorkCenter(WorkCenter, false);
        UpdateSubMgmtCommonWorkCenter(WorkCenter."No.");
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        UpdateSubMgmtRoutingLink(RoutingLink.Code);

        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateLocation(Location2);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Subcontr. Location Code" := Location2.Code;
        Vendor.Modify();
        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchaseHeader, "Purchase Line Type"::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        ItemNoOriginPurchLine := PurchLine."No.";
        PurchLine.Modify(true);

        // [WHEN] Create Prod Order from scratch
        Commit();
        PurchOrder.OpenEdit();
        PurchOrder.GoToRecord(PurchaseHeader);
        PurchOrder.PurchLines.CreateProdOrder.Invoke();

        // [THEN]
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchLine.SetRange("No.", ItemNoOriginPurchLine);
        Assert.RecordCount(PurchLine, 1);
        PurchLine.FindFirst();
        PurchLine.TestField("Prod. Order No.");

        PurchLine2.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");

        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, PurchLine."No.", 3);
        PurchLine2.Validate("Unit of Measure Code", ItemUOM.Code);
        PurchLine2.Modify();
        SynchMgmt.SynchronizeQuantity(PurchLine2, PurchLine);

        ProdOrder.Get("Production Order Status"::Released, PurchLine."Prod. Order No.");
        Assert.AreEqual(PurchLine.Quantity * 3, ProdOrder.Quantity, 'Quantity of Prod. Order must be equal to Quantity of Purchase Line');

        // [TEARDOWN]
        PurchLine.SetRange("No.", ItemNoOriginPurchLine);
        PurchLine.FindFirst();
        ProdOrder.Get("Production Order Status"::Released, PurchLine."Prod. Order No.");
        PurchLine."Prod. Order No." := '';
        PurchLine.Modify();
        ProdOrder.Delete(true);
        UpdateSubMgmtCommonWorkCenter('');
        UpdateSubMgmtRoutingLink('');
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

    local procedure UpdateSubMgmtCommonWorkCenter(WorkCenterNo: Code[20])
    var
        EsMgmtSetup: Record "Subc. Management Setup";
    begin
        EsMgmtSetup.Get();
        EsMgmtSetup."Common Work Center No." := WorkCenterNo;
        EsMgmtSetup.Modify();
    end;

    local procedure UpdateSubMgmtRoutingLink(RtngLink: Code[10])
    var
        EsMgmtSetup: Record "Subc. Management Setup";
    begin
        EsMgmtSetup.Get();
        EsMgmtSetup."Rtng. Link Code Purch. Prov." := RtngLink;
        EsMgmtSetup.Modify();
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

    local procedure UpdateProdBomWithSubcontractingType(Item: Record Item; SubcontractingType: Enum "Subcontracting Type")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        ProductionBOMLine."Subcontracting Type" := SubcontractingType;
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
        Vendor."Subcontr. Location Code" := Location.Code;
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
            WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(CurrencyCode));
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

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Subcontracting Sync Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Subcontracting Sync Test");

        SubSetupLibrary.InitSetupFields();
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);
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
        LibraryMfgManagement.CreateLaborReqWkshTemplateAndNameAndUpdateSetup();
    end;

    local procedure UpdateSubMgmtSetup_ComponentAtLocation(CompAtLocation: Enum "Components at Location")
    var
        EsMgmtSetup: Record "Subc. Management Setup";
    begin
        EsMgmtSetup.Get();
        EsMgmtSetup."Component at Location" := CompAtLocation;
        EsMgmtSetup.Modify();
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

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        Subcontracting: Boolean;
        UnitCostCalculation: Option Time,Units;
}