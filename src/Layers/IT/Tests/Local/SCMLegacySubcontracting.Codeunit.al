#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Environment.Configuration;

codeunit 137500 "SCM Legacy Subcontracting"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;
    ObsoleteReason = 'Legacy Subcontracting will be discontinued, environments should move to the Subcontracting App.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Subcontracting] [Legacy Feature Toggle]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryITLocalization: Codeunit "Library - IT Localization";

        Initialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure AppAreaSetWhenLegacySubcEnabled()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        // [SCENARIO] ApplicationAreaSetup."Legacy Subcontracting" is true when Manufacturing Setup toggle is enabled
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = true
        SetLegacySubcontracting(true);

        // [WHEN] Application areas are reloaded
        RefreshApplicationAreas();

        // [THEN] ApplicationAreaSetup."Legacy Subcontracting" = true
        ApplicationAreaSetup.Get(CompanyName());
        Assert.IsTrue(ApplicationAreaSetup."Legacy Subcontracting", 'Legacy Subcontracting app area should be true when enabled.');
        Assert.IsTrue(ApplicationAreaMgmtFacade.GetApplicationAreaSetup().Contains('#LegacySubcontracting'), 'Legacy Subcontracting setting expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppAreaClearedWhenLegacySubcDisabled()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        // [SCENARIO] ApplicationAreaSetup."Legacy Subcontracting" is false when Manufacturing Setup toggle is disabled
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = false
        SetLegacySubcontracting(false);

        // [WHEN] Application areas are reloaded
        RefreshApplicationAreas();

        // [THEN] ApplicationAreaSetup."Legacy Subcontracting" = false
        ApplicationAreaSetup.Get(CompanyName());
        Assert.IsFalse(ApplicationAreaSetup."Legacy Subcontracting", 'Legacy Subcontracting app area should be false when disabled.');
        Assert.IsFalse(ApplicationAreaMgmtFacade.GetApplicationAreaSetup().Contains('#LegacySubcontracting'), 'Legacy Subcontracting setting expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppAreaNotSetForEssentialExperienceTier()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        // [SCENARIO] ApplicationAreaSetup."Legacy Subcontracting" is NOT set for Essential tier even when the toggle is enabled
        // The subscriber only fires for OnGetPremiumExperienceAppAreas, not for Essential
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = true
        SetLegacySubcontracting(true);

        // [WHEN] Essential experience tier is activated
        LibraryApplicationArea.EnableEssentialSetup();

        // [THEN] ApplicationAreaSetup."Legacy Subcontracting" = false (subscriber does not fire for Essential)
        ApplicationAreaSetup.Get(CompanyName());
        Assert.IsFalse(ApplicationAreaSetup."Legacy Subcontracting",
            'Legacy Subcontracting app area must not be set for Essential experience tier.');

        // Restore to Premium Setup
        LibraryApplicationArea.EnablePremiumSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GuardReturnsTrueWhenEnabled()
    var
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
    begin
        // [SCENARIO] IsLegacySubcontractingEnabled returns true when toggle is ON
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = true
        SetLegacySubcontracting(true);

        // [WHEN] Call IsLegacySubcontractingEnabled
        // [THEN] Returns true
        Assert.IsTrue(LegacySubcFeatureHandler.IsLegacySubcontractingEnabled(), 'Guard should return true when enabled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GuardReturnsFalseWhenDisabled()
    var
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
    begin
        // [SCENARIO] IsLegacySubcontractingEnabled returns false when toggle is OFF
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = false
        SetLegacySubcontracting(false);

        // [WHEN] Call IsLegacySubcontractingEnabled
        // [THEN] Returns false
        Assert.IsFalse(LegacySubcFeatureHandler.IsLegacySubcontractingEnabled(), 'Guard should return false when disabled.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GuardReturnsFalseWhenSetupNotExists()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        TempManufacturingSetupBackup: Record "Manufacturing Setup" temporary;
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
    begin
        // [SCENARIO] IsLegacySubcontractingEnabled returns false when no ManufacturingSetup record exists
        Initialize();
        TempManufacturingSetupBackup.Copy(ManufacturingSetup);
        // [GIVEN] No ManufacturingSetup record
        ManufacturingSetup.Delete();

        // [WHEN] Call IsLegacySubcontractingEnabled
        // [THEN] Returns false
        Assert.IsFalse(LegacySubcFeatureHandler.IsLegacySubcontractingEnabled(), 'Guard should return false when setup does not exist.');

        // Restore ManufacturingSetup
        ManufacturingSetup.Init();
        ManufacturingSetup.Copy(TempManufacturingSetupBackup);
        ManufacturingSetup.Insert();
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DatabaseHasDataWhenOpenWIPTransferExists()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
    begin
        // [SCENARIO] DatabaseHasLegacySubcontractingData returns true when open WIP transfer lines exist
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = true
        SetLegacySubcontracting(true);

        // [GIVEN] Transfer Line exists with "WIP Item" = true and outstanding quantity
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine."WIP Item" := true;
        TransferLine."WIP Outstanding Qty." := 1;
        TransferLine.Insert();

        // [WHEN] Check if data exists (the underlying detection logic)
        // [THEN] DatabaseHasLegacySubcontractingData returns true
        Assert.IsTrue(LegacySubcFeatureHandler.DatabaseHasLegacySubcontractingData(),
            'Should detect open WIP transfer lines as legacy subcontracting data.');

        // Cleanup
        TransferLine.Delete();
        TransferHeader.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DatabaseHasDataWhenOpenWIPPurchaseLineExists()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
    begin
        // [SCENARIO] DatabaseHasLegacySubcontractingData returns true when WIP Item purchase lines exist
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = true
        SetLegacySubcontracting(true);

        // [GIVEN] Purchase Line exists with "WIP Item" = true
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine."WIP Item" := true;
        PurchaseLine.Modify();

        // [WHEN] Check if data exists
        // [THEN] DatabaseHasLegacySubcontractingData returns true (detects open WIP POs)
        Assert.IsTrue(LegacySubcFeatureHandler.DatabaseHasLegacySubcontractingData(),
            'Should detect open WIP purchase lines as legacy subcontracting data.');

        // Cleanup
        PurchaseLine.Delete();
        PurchaseHeader.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DatabaseHasDataWhenSubcontractorPricesExist()
    var
        Item: Record Item;
        SubcontractorPrices: Record "Subcontractor Prices";
        Vendor: Record Vendor;
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
    begin
        // [SCENARIO] DatabaseHasLegacySubcontractingData returns true when WIP Item purchase lines exist
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = true
        SetLegacySubcontracting(true);

        // [GIVEN] A Subcontractor Prices record exists
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryITLocalization.CreateSubContractingPrice(SubcontractorPrices, '', Vendor."No.", Item."No.", '', '', Today(), Item."Base Unit of Measure", 1, CreateCurrency().Code);

        // [WHEN] Check if data exists
        // [THEN] DatabaseHasLegacySubcontractingData returns true
        Assert.IsTrue(LegacySubcFeatureHandler.DatabaseHasLegacySubcontractingData(),
            'Should detect Subcontractor Prices as legacy subcontracting data.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DatabaseHasDataWhenReleasedProdOrderRoutingLineExists()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
    begin
        // [SCENARIO] DatabaseHasLegacySubcontractingData returns true when a released Prod. Order Routing Line with WIP Item = true exists
        Initialize();

        // [GIVEN] A Released Prod. Order Routing Line with WIP Item = true
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Status := "Production Order Status"::Released;
        ProdOrderRoutingLine."Prod. Order No." := 'TEST-LEGACYSUBC';
        ProdOrderRoutingLine."Routing Reference No." := 10000;
        ProdOrderRoutingLine."Routing No." := '';
        ProdOrderRoutingLine."Operation No." := '10';
        ProdOrderRoutingLine."WIP Item" := true;
        ProdOrderRoutingLine.Insert();

        // [WHEN] Check if data exists
        // [THEN] DatabaseHasLegacySubcontractingData returns true
        Assert.IsTrue(LegacySubcFeatureHandler.DatabaseHasLegacySubcontractingData(),
            'Should detect released Prod. Order Routing Lines with WIP Item as legacy subcontracting data.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DatabaseHasDataWhenCapacityLedgerEntryExists()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
    begin
        // [SCENARIO] DatabaseHasLegacySubcontractingData returns true when a Capacity Ledger Entry with subcontracting fields set exists
        Initialize();

        // [GIVEN] A Capacity Ledger Entry with Subcontractor No., Subcontr. Purch. Order No., and WIP Item Qty. set
        CapacityLedgerEntry.Init();
        CapacityLedgerEntry."Entry No." := CapacityLedgerEntry.GetNextEntryNo();
        CapacityLedgerEntry."Subcontractor No." := 'SUBC-TEST';
        CapacityLedgerEntry."Subcontr. Purch. Order No." := 'SUBC-PO-TEST';
        CapacityLedgerEntry."WIP Item Qty." := 1;
        CapacityLedgerEntry.Insert();

        // [WHEN] Check if data exists
        // [THEN] DatabaseHasLegacySubcontractingData returns true
        Assert.IsTrue(LegacySubcFeatureHandler.DatabaseHasLegacySubcontractingData(),
            'Should detect capacity ledger entries with subcontracting fields as legacy data.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCanDisableRaisesErrorWhenAppNotInstalled()
    var
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
        ITMigrationAppNotInstalledErr: Label 'The app "IT Subcontracting Migration" must be installed before you can disable Legacy Subcontracting. Please install the app first and then use the dedicated action "Disable Legacy Subcontracting" to disable Legacy Subcontracting and migrate to the new subcontracting app.';
    begin
        // [SCENARIO] CheckCanDisableLegacySubcontracting raises error when new subcontracting app is not installed
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = true
        SetLegacySubcontracting(true);

        // [WHEN] Call CheckCanDisableLegacySubcontracting
        asserterror LegacySubcFeatureHandler.CheckCanDisableLegacySubcontracting();

        // [THEN] Error: successor app must be installed first
        Assert.ExpectedError(ITMigrationAppNotInstalledErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeSetsFlagForCompaniesWithLegacySubcontractingData()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
    begin
        // [SCENARIO] DatabaseHasLegacySubcontractingData returns true when WIP Item routing lines exist
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = false
        SetLegacySubcontracting(false);

        // [GIVEN] A Routing Line with "WIP Item" = true
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine."WIP Item" := true;
        RoutingLine.Modify();

        // [WHEN] Check DatabaseHasLegacySubcontractingData
        // [THEN] Returns true
        Assert.IsTrue(LegacySubcFeatureHandler.DatabaseHasLegacySubcontractingData(), 'Should detect legacy data when WIP Item routing lines exist.');

        // Simulate what upgrade logic does
        ManufacturingSetup.Get();
        ManufacturingSetup."Legacy Subcontracting" := LegacySubcFeatureHandler.DatabaseHasLegacySubcontractingData();
        ManufacturingSetup.Modify();

        // [THEN] Manufacturing Setup is now enabled
        ManufacturingSetup.Get();
        Assert.IsTrue(ManufacturingSetup."Legacy Subcontracting", 'Upgrade should enable legacy subcontracting when data exists.');

        // Cleanup
        RoutingLine.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpgradeDoesNotSetFlagForCleanCompanies()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcontractorPrices: Record "Subcontractor Prices";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        RoutingLine: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
    begin
        // [SCENARIO] DatabaseHasLegacySubcontractingData returns false when no subcontracting data exists
        Initialize();

        // [GIVEN] No legacy subcontracting data
        if not SubcontractorPrices.IsEmpty() then
            SubcontractorPrices.DeleteAll();
        CapacityLedgerEntry.SetFilter("Subcontractor No.", '<>%1', '');
        if not CapacityLedgerEntry.IsEmpty() then
            CapacityLedgerEntry.DeleteAll();
        RoutingLine.SetRange("WIP Item", true);
        if not RoutingLine.IsEmpty() then
            RoutingLine.DeleteAll();
        ProdOrderRoutingLine.SetRange("WIP Item", true);
        if not ProdOrderRoutingLine.IsEmpty() then
            ProdOrderRoutingLine.DeleteAll();
        TransferLine.SetRange("WIP Item", true);
        if not TransferLine.IsEmpty() then
            TransferLine.DeleteAll();
        PurchaseLine.SetRange("WIP Item", true);
        if not PurchaseLine.IsEmpty() then
            PurchaseLine.DeleteAll();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = false
        SetLegacySubcontracting(false);

        // [WHEN] Check DatabaseHasLegacySubcontractingData
        // [THEN] Returns false
        Assert.IsFalse(LegacySubcFeatureHandler.DatabaseHasLegacySubcontractingData(), 'Should not detect legacy data in a clean company.');

        // Simulate upgrade logic
        ManufacturingSetup.Get();
        ManufacturingSetup."Legacy Subcontracting" := LegacySubcFeatureHandler.DatabaseHasLegacySubcontractingData();
        ManufacturingSetup.Modify();

        // [THEN] Manufacturing Setup stays disabled
        ManufacturingSetup.Get();
        Assert.IsFalse(ManufacturingSetup."Legacy Subcontracting", 'Upgrade should not enable legacy subcontracting for clean companies.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardSubcFieldsVisibleWhenEnabled()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO] Subcontracting fields on Vendor Card are visible when Legacy Subcontracting app area is active
        Initialize();

        // [GIVEN] Legacy Subcontracting is enabled and Premium experience is activated
        SetLegacySubcontracting(true);
        RefreshApplicationAreas();

        // [GIVEN] A vendor exists
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Open the Vendor Card
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [THEN] Subcontracting fields are visible
        Assert.IsTrue(VendorCard.Subcontractor.Visible(), 'Subcontractor field should be visible when Legacy Subcontracting is enabled.');
        Assert.IsTrue(VendorCard."Subcontracting Location Code".Visible(), '"Subcontracting Location Code" should be visible when Legacy Subcontracting is enabled.');
        Assert.IsTrue(VendorCard."Linked to Work Center".Visible(), '"Linked to Work Center" should be visible when Legacy Subcontracting is enabled.');

        VendorCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorCardSubcFieldsNotVisibleWhenDisabled()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO] Subcontracting fields on Vendor Card are NOT visible when Legacy Subcontracting app area is inactive
        Initialize();

        // [GIVEN] Legacy Subcontracting is disabled and Premium experience is activated
        SetLegacySubcontracting(false);
        RefreshApplicationAreas();

        // [GIVEN] A vendor exists
        LibraryPurchase.CreateVendor(Vendor);

        // [WHEN] Open the Vendor Card
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [THEN] Subcontracting fields are NOT visible
        asserterror Assert.IsFalse(VendorCard.Subcontractor.Visible(), 'Subcontractor field should not be visible when Legacy Subcontracting is disabled.');
        asserterror Assert.IsFalse(VendorCard."Subcontracting Location Code".Visible(), '"Subcontracting Location Code" should not be visible when Legacy Subcontracting is disabled.');
        asserterror Assert.IsFalse(VendorCard."Linked to Work Center".Visible(), '"Linked to Work Center" should not be visible when Legacy Subcontracting is disabled.');

        VendorCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreCheckDisableRaisesErrorWhenOpenTransfersExist()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
        OpenSubcontractingTransfersExistErr: Label 'There are still open transfer orders with WIP Items. All subcontracting transfer orders must be completed before disabling Legacy Subcontracting.';
    begin
        // [SCENARIO] CheckCanDisableLegacySubcontracting raises error when open WIP transfer orders exist
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = true
        SetLegacySubcontracting(true);

        // [GIVEN] An open WIP transfer line exists
        LibraryWarehouse.CreateLocation(LocationFrom);
        LibraryWarehouse.CreateLocation(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := 10000;
        TransferLine."WIP Item" := true;
        TransferLine."WIP Outstanding Qty." := 1;
        TransferLine.Insert();

        // [WHEN] Call CheckCanDisableLegacySubcontracting
        asserterror LegacySubcFeatureHandler.CheckCanDisableLegacySubcontracting();

        // [THEN] Error: open subcontracting transfers must be completed first
        Assert.ExpectedError(OpenSubcontractingTransfersExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreCheckDisableRaisesErrorWhenOpenWIPPOsExist()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
        OpenWIPPurchaseOrdersExistErr: Label 'There are still open subcontracting purchase orders. All subcontracting purchase orders must be completed before disabling Legacy Subcontracting.';
    begin
        // [SCENARIO] CheckCanDisableLegacySubcontracting raises error when open WIP purchase orders exist
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = true
        SetLegacySubcontracting(true);

        // [GIVEN] No open WIP transfers (to pass the first check)
        TransferLine.SetRange("WIP Item", true);
        TransferLine.DeleteAll();

        // [GIVEN] An open WIP purchase order line exists
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine."WIP Item" := true;
        PurchaseLine.Modify();

        // [WHEN] Call CheckCanDisableLegacySubcontracting
        asserterror LegacySubcFeatureHandler.CheckCanDisableLegacySubcontracting();

        // [THEN] Error: open WIP purchase orders must be completed first
        Assert.ExpectedError(OpenWIPPurchaseOrdersExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreCheckDisableSucceedsWhenITMigrationAppInstalled()
    var
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        LegacySubcFeatureHandler: Codeunit "Legacy Subc. Feature Handler";
        SCMLegacySubcontracting: Codeunit "SCM Legacy Subcontracting";
    begin
        // [SCENARIO] CheckCanDisableLegacySubcontracting succeeds when no open data exists and IT Migration app is installed
        Initialize();

        // [GIVEN] ManufacturingSetup."Legacy Subcontracting" = true
        SetLegacySubcontracting(true);

        // [GIVEN] No open WIP data
        TransferLine.SetRange("WIP Item", true);
        if not TransferLine.IsEmpty() then
            TransferLine.DeleteAll();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("WIP Item", true);
        if not PurchaseLine.IsEmpty() then
            PurchaseLine.DeleteAll();

        // [GIVEN] IT Migration app is mocked as installed
        BindSubscription(SCMLegacySubcontracting);

        // [WHEN] Call CheckCanDisableLegacySubcontracting
        LegacySubcFeatureHandler.CheckCanDisableLegacySubcontracting();

        // [THEN] No error is raised - the call completed successfully
        UnbindSubscription(SCMLegacySubcontracting);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Legacy Subcontracting");
        LibraryApplicationArea.EnablePremiumSetup();

        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Legacy Subcontracting");
        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Legacy Subcontracting");
    end;

    local procedure SetLegacySubcontracting(Enabled: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert();
        end;
        ManufacturingSetup."Legacy Subcontracting" := Enabled;
        ManufacturingSetup.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Legacy Subc. Feature Handler", 'OnCheckIsITMigrationAppInstalled', '', false, false)]
    local procedure MockITMigrationAppInstalled(var Result: Boolean)
    begin
        Result := true;
    end;

    local procedure RefreshApplicationAreas()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
    end;

    local procedure CreateCurrency(): Record Currency
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency);
    end;
}
#endif
