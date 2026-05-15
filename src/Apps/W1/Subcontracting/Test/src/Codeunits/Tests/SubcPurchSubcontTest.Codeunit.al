// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
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

        // [WHEN] Try to set the vendor's Subcontr. Location Code to the location with Bin Mandatory
        // [THEN] An error is thrown with ErrorInfo
        asserterror Vendor.Validate("Subcontr. Location Code", Location.Code);
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

        // [WHEN] Try to set the vendor's Subcontr. Location Code to the location with Require Pick
        // [THEN] An error is thrown
        asserterror Vendor.Validate("Subcontr. Location Code", Location.Code);
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

        // [WHEN] Set the vendor's Subcontr. Location Code to the valid location
        // [THEN] The validation succeeds and the field is updated
        Vendor.Validate("Subcontr. Location Code", Location.Code);
        Assert.AreEqual(Location.Code, Vendor."Subcontr. Location Code", 'Subcontr. Location Code should be set to the valid location');
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
        // with Subcontracting Type = "Purchase with Service" and Flushing Method = Backward,
        // the component is consumed via backward flushing when the output is posted.
        // BOM: 1 component item (Subcontracting Type = Purchase with Service, linked to Routing Line 100).
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
        Vendor."Subcontr. Location Code" := Location.Code;
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

        // [GIVEN] A production BOM with one component, Subcontracting Type = Purchase with Service
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", 1);
        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Validate("Subcontracting Type", "Subcontracting Type"::Purchase);
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
}