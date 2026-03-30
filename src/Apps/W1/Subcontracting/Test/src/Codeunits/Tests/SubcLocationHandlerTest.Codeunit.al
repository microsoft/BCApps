// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 139981 "Subc. Location Handler Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Enhanced Subcontracting Location Handler
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
        SubCreateProdOrdWizLibrary: Codeunit "Subc. CreateProdOrdWizLibrary";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        WizardFinishedSuccessfully: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Location Handler Test");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Location Handler Test");

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Location Handler Test");
    end;

    [Test]
    procedure TestGetComponentsLocationCode_Purchase()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SubManagementSetup: Record "Subc. Management Setup";
        SubcontractingMgmt: Codeunit "Subcontracting Management";
        CompLocationCode: Code[10];
    begin
        // [SCENARIO] GetComponentsLocationCode returns Purchase Line Location when Setup is Purchase
        Initialize();

        // [GIVEN] Sub Management Setup "Component at Location" is Purchase
        UpdateSubManagementSetup(SubManagementSetup."Component at Location"::Purchase);

        // [GIVEN] A Purchase Line with a Location
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, '');
        LibraryWarehouse.CreateLocation(Location);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::Item, '', LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify();

        // [WHEN] GetComponentsLocationCode is called
        CompLocationCode := SubcontractingMgmt.GetComponentsLocationCode(PurchaseLine);

        // [THEN] The returned location code is the Purchase Line Location
        Assert.AreEqual(Location.Code, CompLocationCode, 'Component Location Code should match Purchase Line Location');
    end;

    [Test]
    procedure TestGetComponentsLocationCode_Company()
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        SubManagementSetup: Record "Subc. Management Setup";
        SubcontractingMgmt: Codeunit "Subcontracting Management";
        CompLocationCode: Code[10];
    begin
        // [SCENARIO] GetComponentsLocationCode returns Company Location when Setup is Company
        Initialize();

        // [GIVEN] Sub Management Setup "Component at Location" is Company
        UpdateSubManagementSetup(SubManagementSetup."Component at Location"::Company);

        // [GIVEN] Company Information has a Location
        LibraryWarehouse.CreateLocation(Location);
        UpdateCompanyInformation(Location.Code);

        // [WHEN] GetComponentsLocationCode is called
        CompLocationCode := SubcontractingMgmt.GetComponentsLocationCode(PurchaseLine);

        // [THEN] The returned location code is the Company Location
        Assert.AreEqual(Location.Code, CompLocationCode, 'Component Location Code should match Company Location');
    end;

    [Test]
    procedure TestGetComponentsLocationCode_Manufacturing()
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        SubManagementSetup: Record "Subc. Management Setup";
        SubcontractingMgmt: Codeunit "Subcontracting Management";
        CompLocationCode: Code[10];
    begin
        // [SCENARIO] GetComponentsLocationCode returns Manufacturing Location when Setup is Manufacturing
        Initialize();

        // [GIVEN] Sub Management Setup "Component at Location" is Manufacturing
        UpdateSubManagementSetup(SubManagementSetup."Component at Location"::Manufacturing);

        // [GIVEN] Manufacturing Setup has a Location
        LibraryWarehouse.CreateLocation(Location);
        UpdateManufacturingSetup(Location.Code);

        // [GIVEN] A Purchase Line (Location doesn't matter)
        PurchaseLine.Init();

        // [WHEN] GetComponentsLocationCode is called
        CompLocationCode := SubcontractingMgmt.GetComponentsLocationCode(PurchaseLine);

        // [THEN] The returned location code is the Manufacturing Location
        Assert.AreEqual(Location.Code, CompLocationCode, 'Component Location Code should match Manufacturing Location');
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder')]
    procedure TestTransferOrderCreation_SameLocation()
    var
        Item: Record Item;
        LocationOrig: Record Location;
        LocationSub: Record Location;
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        Vendor: Record Vendor;
        CreateSubCTransfOrder: Report "Subc. Create Transf. Order";
    begin
        // [SCENARIO] Transfer Order creation uses Origin Location if Component Location equals Subcontractor Location
        Initialize();

        // [GIVEN] Locations: Subcontractor and Original
        LibraryWarehouse.CreateLocation(LocationSub);
        LibraryWarehouse.CreateLocation(LocationOrig);

        // [GIVEN] Subcontracting Scenario Setup
        CreateSubcontractingSetup(
            PurchaseHeader, PurchaseLine, ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRtngLine, Vendor,
            LocationSub, Item, LibraryRandom.RandInt(10), LocationSub.Code, LocationOrig.Code);

        // [WHEN] Running the Create Subcontracting Transfer Order report
        Commit(); // Report requires commit
        PurchaseHeader.SetRecFilter();
        CreateSubCTransfOrder.SetTableView(PurchaseHeader);
        CreateSubCTransfOrder.UseRequestPage(false);
        CreateSubCTransfOrder.Run();

        // [THEN] Transfer Order is created from Origin Location to Subcontractor Location
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        Assert.IsTrue(TransferHeader.FindFirst(), 'Transfer Order should be created');
        Assert.AreEqual(LocationOrig.Code, TransferHeader."Transfer-from Code", 'Transfer-from Code should be Origin Location');
        Assert.AreEqual(LocationSub.Code, TransferHeader."Transfer-to Code", 'Transfer-to Code should be Subcontractor Location');
    end;

    [Test]
    [HandlerFunctions('HandleTransferOrder')]
    procedure TestTransferOrderCreation_PostAndRecreate()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        LocationOrig: Record Location;
        LocationSub: Record Location;
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        CreateSubCTransfOrder: Report "Subc. Create Transf. Order";
        QtyFirstTransfer: Decimal;
        QtyRemaining: Decimal;
        QtyTotal: Decimal;
    begin
        // [SCENARIO] Create Transfer Order, reduce quantity, post, and create new Transfer Order for remaining
        Initialize();

        QtyTotal := 10;
        QtyFirstTransfer := 4;
        QtyRemaining := QtyTotal - QtyFirstTransfer;

        // [GIVEN] Locations
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationSub);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationOrig);

        // [GIVEN] Subcontracting Scenario Setup
        CreateSubcontractingSetup(
            PurchaseHeader, PurchaseLine, ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRtngLine, Vendor,
            LocationSub, Item, QtyTotal, LocationOrig.Code, '');

        // [GIVEN] Inventory for the component at Origin Location (needed for posting transfer)
        LibraryInventory.CreateItemJournalLineInItemTemplate(
            ItemJournalLine, Item."No.", LocationOrig.Code, '', QtyTotal);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Running the Create Subcontracting Transfer Order report (1st time)
        Commit();
        Clear(CreateSubCTransfOrder);
        PurchaseHeader.SetRecFilter();
        CreateSubCTransfOrder.SetTableView(PurchaseHeader);
        CreateSubCTransfOrder.UseRequestPage(false);
        CreateSubCTransfOrder.Run();

        // [THEN] Transfer Order 1 is created for full quantity
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        Assert.IsTrue(TransferHeader.FindFirst(), 'Transfer Order 1 should be created');

        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        Assert.AreEqual(QtyTotal, TransferLine.Quantity, 'Initial Transfer Quantity should be total quantity');

        // [WHEN] Reduce Quantity on Transfer Order and Post
        TransferLine.Validate(Quantity, QtyFirstTransfer);
        TransferLine.Modify();
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true); // Ship and Receive

        // [WHEN] Running the Create Subcontracting Transfer Order report (2nd time)
        Commit();
        Clear(CreateSubCTransfOrder);
        CreateSubCTransfOrder.SetTableView(PurchaseHeader);
        CreateSubCTransfOrder.UseRequestPage(false);
        CreateSubCTransfOrder.Run();

        // [THEN] Transfer Order 2 is created for remaining quantity
        TransferHeader.Reset();
        TransferHeader.SetRange("Subcontr. Purch. Order No.", PurchaseHeader."No.");
        TransferHeader.SetRange(Status, TransferHeader.Status::Open); // Find the new open one
        Assert.IsTrue(TransferHeader.FindFirst(), 'Transfer Order 2 should be created');

        TransferLine.Reset();
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.FindFirst();
        Assert.AreEqual(QtyRemaining, TransferLine.Quantity, 'Second Transfer Quantity should be remaining quantity');
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizard')]
    procedure TestProdOrderLocationFromMfgSetup_PurchaseLocationMustBeDifferent()
    var
        LocationMfg: Record Location;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        SubManagementSetup: Record "Subc. Management Setup";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        ItemNo: Code[20];
    begin
        // [SCENARIO] When location code from Manufacturing Setup is used in Production Order,
        // the Purchase Location Code must be different
        // [GIVEN] proper setup configuration with Manufacturing location
        Initialize();

        // [GIVEN] Sub Management Setup "Component at Location" is Manufacturing
        UpdateSubManagementSetup(SubManagementSetup."Component at Location"::Manufacturing);

        // [GIVEN] Manufacturing Setup with a specific Location Code
        LibraryWarehouse.CreateLocation(LocationMfg);
        UpdateManufacturingSetup(LocationMfg.Code);

        // [GIVEN] Create item without BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // [GIVEN] Create purchase line with subcontracting vendor
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Verify wizard completed successfully
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // [THEN] Find the created Production Order
        ProdOrder.SetRange("Source No.", ItemNo);
        Assert.IsTrue(ProdOrder.FindFirst(), 'Production Order should be created');

        // [THEN] Find the Production Order Line
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        Assert.IsTrue(not ProdOrderLine.IsEmpty(), 'Production Order Line should exist');

        // [THEN] Verify Manufacturing Setup has the configured Location Code
        ManufacturingSetup.Get();
        Assert.AreEqual(LocationMfg.Code, ManufacturingSetup."Components at Location",
            'Manufacturing Setup should have the Manufacturing Location Code');

        // [THEN] Verify Purchase Location is different from Manufacturing Setup Location
        Assert.AreNotEqual(ManufacturingSetup."Components at Location", PurchLine."Location Code",
            'Purchase Location Code must be different from Manufacturing Setup Location Code');
    end;

    local procedure UpdateSubManagementSetup(ComponentAtLocation: Enum "Components at Location")
    var
        SubManagementSetup: Record "Subc. Management Setup";
    begin
        if not SubManagementSetup.Get() then begin
            SubManagementSetup.Init();
            SubManagementSetup.Insert();
        end;
        SubManagementSetup."Component at Location" := ComponentAtLocation;
        SubManagementSetup.Modify();
    end;

    local procedure UpdateManufacturingSetup(LocationCode: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup."Components at Location" := LocationCode;
        ManufacturingSetup.Modify();
    end;

    local procedure UpdateCompanyInformation(LocationCode: Code[10])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Location Code" := LocationCode;
        CompanyInformation.Modify();
    end;

    local procedure CreateSubcontractingSetup(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComp: Record "Prod. Order Component"; var ProdOrderRtngLine: Record "Prod. Order Routing Line"; var Vendor: Record Vendor; var LocationSub: Record Location; var Item: Record Item; Qty: Decimal; CompLocationCode: Code[10]; CompOrigLocationCode: Code[10])
    var
        RoutingLink: Record "Routing Link";
    begin
        // [GIVEN] Vendor with Subcontractor Location
        if Vendor."No." = '' then begin
            LibraryPurchase.CreateVendor(Vendor);
            Vendor."Subcontr. Location Code" := LocationSub.Code;
            Vendor.Modify();
        end;

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Production Order with Component
        LibraryManufacturing.CreateProductionOrder(ProdOrder, "Production Order Status"::Released, ProdOrder."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrder.Status, ProdOrder."No.", Item."No.", '', CompLocationCode, Qty);

        // [GIVEN] Create a Routing Link for linking component to routing line
        LibraryManufacturing.CreateRoutingLink(RoutingLink);

        // [GIVEN] Production Order Component
        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComp, ProdOrder.Status, ProdOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComp.Validate("Item No.", Item."No.");
        ProdOrderComp.Validate(Quantity, Qty);
        ProdOrderComp.Validate("Quantity per", 1);
        ProdOrderComp."Location Code" := CompLocationCode;
        if CompOrigLocationCode <> '' then
            ProdOrderComp."Orig. Location Code" := CompOrigLocationCode;
        ProdOrderComp."Subcontracting Type" := ProdOrderComp."Subcontracting Type"::Transfer;
        ProdOrderComp."Routing Link Code" := RoutingLink.Code;
        ProdOrderComp.Modify();

        // [GIVEN] Prod Order Routing Line (needed for linking)
        CreateProdOrderRoutingLine(ProdOrderRtngLine, ProdOrder, ProdOrderLine, RoutingLink.Code);

        // [GIVEN] Purchase Order linked to Prod Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, "Purchase Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::Item, Item."No.", Qty);
        PurchaseLine."Prod. Order No." := ProdOrder."No.";
        PurchaseLine."Prod. Order Line No." := ProdOrderLine."Line No.";
        PurchaseLine."Routing No." := ProdOrderRtngLine."Routing No.";
        PurchaseLine."Operation No." := ProdOrderRtngLine."Operation No.";
        PurchaseLine."Routing Reference No." := ProdOrderRtngLine."Routing Reference No.";
        PurchaseLine.Modify();
    end;

    local procedure CreateProdOrderRoutingLine(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; RoutingLinkCode: Code[10])
    var
        OperationNo: Code[10];
    begin
        ProdOrderRtngLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderRtngLine.FindLast() then
            OperationNo := IncStr(ProdOrderRtngLine."Operation No.")
        else
            OperationNo := '10';

        ProdOrderRtngLine.Init();
        ProdOrderRtngLine.Status := ProdOrder.Status;
        ProdOrderRtngLine."Prod. Order No." := ProdOrder."No.";
        ProdOrderRtngLine."Routing Reference No." := ProdOrderLine."Line No.";
        ProdOrderRtngLine."Operation No." := OperationNo;
        ProdOrderRtngLine."Routing Link Code" := RoutingLinkCode;
        ProdOrderRtngLine.Insert();
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizard(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    begin
        // [SCENARIO] Handle the Purchase Provision Wizard
        // The wizard should navigate through all steps and finish successfully

        // Click Next to proceed through the wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        // Click Finish to complete the wizard
        if PurchProvisionWizard.ActionFinish.Enabled() then begin
            PurchProvisionWizard.ActionFinish.Invoke();
            WizardFinishedSuccessfully := true;
        end;
    end;

    [PageHandler]
    procedure HandleTransferOrder(var TransfOrderPage: TestPage "Transfer Order")
    begin
    end;
}
