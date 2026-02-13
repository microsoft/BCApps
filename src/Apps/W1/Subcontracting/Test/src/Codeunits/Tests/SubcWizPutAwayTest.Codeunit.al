// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

codeunit 139999 "Subc. Wiz. Put-Away Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management - Production Order Creation Wizard Put-Away Tests
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubCreateProdOrdWizLibrary: Codeunit "Subc. CreateProdOrdWizLibrary";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        ProdOrderCheckLib: Codeunit "Subc. ProdOrderCheckLib";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;

    // ==================== SCENARIO L: Put-Away Operations ====================

    [Test]
    procedure TestL1_LocationWithWarehouseHandling_PutAwaySetup_TwoOperations()
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        SubManagementSetup: Record "Subc. Management Setup";
        WorkCenter: Record "Work Center";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        LocationCode: Code[10];
        ItemNo: Code[20];
        PutAwayWorkCenterNo: Code[20];
        OperationCount: Integer;
    begin
        // [SCENARIO L1] Location with warehouse handling + Put-Away setup = 2 operations
        // [GIVEN] Location requires warehouse handling and put-away work center is configured
        Initialize();

        // Create location with warehouse handling
        LocationCode := CreateLocationWithWarehouseHandling();

        // Create put-away work center
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 1);
        PutAwayWorkCenterNo := WorkCenter."No.";

        // Configure Sub Management Setup with put-away work center
        SubManagementSetup.Get();
        SubManagementSetup."Put-Away Work Center No." := PutAwayWorkCenterNo;
        SubManagementSetup.Modify();

        // Configure setup to hide both (automatic creation)
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);

        // Create item without BOM/Routing (nothing present scenario)
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Create purchase line with the warehouse location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);
        PurchLine.Validate("Location Code", LocationCode);
        PurchLine.Modify();

        // [WHEN] Run the Production Order Creation process
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Production order should be created with 2 routing operations
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Count routing operations
        ProdOrderRtngLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrder."No.");
        OperationCount := ProdOrderRtngLine.Count();
        Assert.AreEqual(2, OperationCount, 'Should have 2 routing operations (subcontracting + put-away)');

        // Verify first operation (subcontracting)
        ProdOrderRtngLine.SetRange("Operation No.", '10');
        Assert.IsTrue(ProdOrderRtngLine.FindFirst(), 'Should have operation 10 for subcontracting');
        Assert.AreEqual("Capacity Type"::"Work Center", ProdOrderRtngLine.Type, 'Operation 10 should be Work Center type');

        // Verify second operation (put-away)
        ProdOrderRtngLine.SetRange("Operation No.", '20');
        Assert.IsTrue(ProdOrderRtngLine.FindFirst(), 'Should have operation 20 for put-away');
        Assert.AreEqual("Capacity Type"::"Work Center", ProdOrderRtngLine.Type, 'Operation 20 should be Work Center type');
        Assert.AreEqual(PutAwayWorkCenterNo, ProdOrderRtngLine."Work Center No.", 'Operation 20 should use put-away work center');
    end;

    [Test]
    procedure TestL2_LocationWithWarehouseHandling_NoPutAwaySetup_OneOperation()
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        SubManagementSetup: Record "Subc. Management Setup";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        LocationCode: Code[10];
        ItemNo: Code[20];
        OperationCount: Integer;
    begin
        // [SCENARIO L2] Location with warehouse handling + No put-away setup = 1 operation
        // [GIVEN] Location requires warehouse handling but no put-away work center is configured
        Initialize();

        // Create location with warehouse handling
        LocationCode := CreateLocationWithWarehouseHandling();

        // Configure Sub Management Setup without put-away work center
        SubManagementSetup.Get();
        SubManagementSetup."Put-Away Work Center No." := '';
        SubManagementSetup.Modify();

        // Configure setup to hide both (automatic creation)
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);

        // Create item without BOM/Routing (nothing present scenario)
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Create purchase line with the warehouse location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);
        PurchLine.Validate("Location Code", LocationCode);
        PurchLine.Modify();

        // [WHEN] Run the Production Order Creation process
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Production order should be created with 1 routing operation only
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Count routing operations
        ProdOrderRtngLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrder."No.");
        OperationCount := ProdOrderRtngLine.Count();
        Assert.AreEqual(1, OperationCount, 'Should have only 1 routing operation (subcontracting only)');

        // Verify only the subcontracting operation exists
        ProdOrderRtngLine.SetRange("Operation No.", '10');
        Assert.IsTrue(ProdOrderRtngLine.FindFirst(), 'Should have operation 10 for subcontracting');
        Assert.AreEqual("Capacity Type"::"Work Center", ProdOrderRtngLine.Type, 'Operation 10 should be Work Center type');

        // Verify no put-away operation exists
        ProdOrderRtngLine.SetRange("Operation No.", '20');
        Assert.IsTrue(ProdOrderRtngLine.IsEmpty(), 'Should not have operation 20 for put-away');
    end;

    [Test]
    procedure TestL3_LocationWithoutWarehouseHandling_OneOperation()
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        SubManagementSetup: Record "Subc. Management Setup";
        WorkCenter: Record "Work Center";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        LocationCode: Code[10];
        ItemNo: Code[20];
        PutAwayWorkCenterNo: Code[20];
        OperationCount: Integer;
    begin
        // [SCENARIO L3] Location without warehouse handling = 1 operation
        // [GIVEN] Location does not require warehouse handling (even with put-away setup)
        Initialize();

        // Create location without warehouse handling
        LocationCode := CreateLocationWithoutWarehouseHandling();

        // Create put-away work center (should be ignored)
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 1);
        PutAwayWorkCenterNo := WorkCenter."No.";

        // Configure Sub Management Setup with put-away work center
        SubManagementSetup.Get();
        SubManagementSetup."Put-Away Work Center No." := PutAwayWorkCenterNo;
        SubManagementSetup.Modify();

        // Configure setup to hide both (automatic creation)
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);

        // Create item without BOM/Routing (nothing present scenario)
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Create purchase line with the non-warehouse location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);
        PurchLine.Validate("Location Code", LocationCode);
        PurchLine.Modify();

        // [WHEN] Run the Production Order Creation process
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Production order should be created with 1 routing operation only
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Count routing operations
        ProdOrderRtngLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrder."No.");
        OperationCount := ProdOrderRtngLine.Count();
        Assert.AreEqual(1, OperationCount, 'Should have only 1 routing operation (subcontracting only)');

        // Verify only the subcontracting operation exists
        ProdOrderRtngLine.SetRange("Operation No.", '10');
        Assert.IsTrue(ProdOrderRtngLine.FindFirst(), 'Should have operation 10 for subcontracting');
        Assert.AreEqual("Capacity Type"::"Work Center", ProdOrderRtngLine.Type, 'Operation 10 should be Work Center type');

        // Verify no put-away operation exists
        ProdOrderRtngLine.SetRange("Operation No.", '20');
        Assert.IsTrue(ProdOrderRtngLine.IsEmpty(), 'Should not have operation 20 for put-away');
    end;

    [Test]
    procedure TestL5_PutAwayWorkCenterValidation()
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        SubManagementSetup: Record "Subc. Management Setup";
        WorkCenter: Record "Work Center";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        LocationCode: Code[10];
        ItemNo: Code[20];
        PutAwayWorkCenterNo: Code[20];
    begin
        // [SCENARIO L5] Put-away operation uses correct work center from setup
        // [GIVEN] Location requires warehouse handling and specific put-away work center is configured
        Initialize();

        // Create location with warehouse handling
        LocationCode := CreateLocationWithWarehouseHandling();

        // Create specific put-away work center with identifiable properties
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 1);
        PutAwayWorkCenterNo := WorkCenter."No.";
        WorkCenter.Name := 'PUT-AWAY TSubT CENTER';
        WorkCenter.Modify();

        // Configure Sub Management Setup with put-away work center
        SubManagementSetup.Get();
        SubManagementSetup."Put-Away Work Center No." := PutAwayWorkCenterNo;
        SubManagementSetup.Modify();

        // Configure setup to hide both (automatic creation)
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);

        // Create item without BOM/Routing (nothing present scenario)
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Create purchase line with the warehouse location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);
        PurchLine.Validate("Location Code", LocationCode);
        PurchLine.Modify();

        // [WHEN] Run the Production Order Creation process
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Put-away operation should use the configured work center
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Find put-away operation
        ProdOrderRtngLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderRtngLine.SetRange("Operation No.", '20');
        Assert.IsTrue(ProdOrderRtngLine.FindFirst(), 'Should have operation 20 for put-away');

        // Verify work center assignment
        Assert.AreEqual(PutAwayWorkCenterNo, ProdOrderRtngLine."Work Center No.", 'Put-away operation should use configured work center');
        Assert.AreEqual(PutAwayWorkCenterNo, ProdOrderRtngLine."No.", 'Put-away operation No. should match work center');

        // Verify operation description
        Assert.IsTrue(StrPos(ProdOrderRtngLine.Description, 'Put-Away') > 0, 'Put-away operation should have descriptive name');
    end;

    // ==================== HELPER METHODS ====================

    local procedure CreateLocationWithWarehouseHandling(): Code[10]
    var
        Location: Record Location;
        LocationCode: Code[10];
    begin
        LocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Get(LocationCode);
        Location.Validate("Prod. Output Whse. Handling", "Prod. Output Whse. Handling"::"Inventory Put-away");
        Location.Modify(true);
        exit(LocationCode);
    end;

    local procedure CreateLocationWithoutWarehouseHandling(): Code[10]
    var
        Location: Record Location;
        LocationCode: Code[10];
    begin
        LocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Get(LocationCode);
        Location.Validate("Prod. Output Whse. Handling", "Prod. Output Whse. Handling"::"No Warehouse Handling");
        Location.Modify(true);
        exit(LocationCode);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Wiz. Put-Away Test");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Wiz. Put-Away Test");

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Wiz. Put-Away Test");
    end;
}