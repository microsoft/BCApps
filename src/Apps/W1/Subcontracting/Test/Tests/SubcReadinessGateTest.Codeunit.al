// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

codeunit 139999 "Subc. Readiness Gate Test"
{
    // [FEATURE] [Subcontracting] [Readiness Gate]
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
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcManagementLibrary: Codeunit "Subc. Management Library";
        SubcSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        FirstOperationNoTok: Label '10', Locked = true;
        SecondOperationNoTok: Label '20', Locked = true;
        ReqLineExpectedErr: Label 'Calculate Subcontracts must propose item %1 for subcontractor %2.', Comment = '%1 = Item No., %2 = Vendor No.';
        ReqLineNotExpectedErr: Label 'Calculate Subcontracts must not propose item %1 for subcontractor %2.', Comment = '%1 = Item No., %2 = Vendor No.';
        QtyToPurchaseChangedErr: Label 'The readiness gate must not change the quantity to purchase from subcontractor %1.', Comment = '%1 = Vendor No.';
        QtyReadyToStartErr: Label 'Quantity Ready to Start of operation %1 is incorrect.', Comment = '%1 = Operation No.';

    [Test]
    procedure CalcSubcontractsWithoutReadinessGateProposesBothOperations()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO] With the option Only Operations Ready to Start switched off, Calculate Subcontracts proposes every subcontracted operation, as before.
        Initialize();

        // [GIVEN] An item with a serial routing of two subcontracted operations "O1" and "O2"; "O1" has Send-Ahead Quantity "S"
        CreateItemWithTwoSubcontractedOperations(Item, WorkCenter, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] A refreshed released production order with quantity "Q"; no output is posted, so "O2" is not ready to start
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);

        // [WHEN] Calculate Subcontracts runs with the option switched off
        CalculateSubcontracts(WorkCenter, false);

        // [THEN] Worksheet lines are proposed for "O1" and for "O2"
        VerifyReqLineExists(Item."No.", WorkCenter[1]."Subcontractor No.");
        VerifyReqLineExists(Item."No.", WorkCenter[2]."Subcontractor No.");
    end;

    [Test]
    procedure CalcSubcontractsWithReadinessGateSkipsOperationBelowStartThreshold()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
        SendAheadQty: Decimal;
    begin
        // [SCENARIO] With the option Only Operations Ready to Start switched on, an operation whose predecessor operation is below its start threshold is not proposed.
        Initialize();

        // [GIVEN] An item with a serial routing of two subcontracted operations "O1" and "O2"; "O1" has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(5, 10);
        CreateItemWithTwoSubcontractedOperations(Item, WorkCenter, SendAheadQty);

        // [GIVEN] A refreshed released production order with quantity "Q" > "S"
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "S" - 1 is posted on "O1", so "O2" is not ready to start
        MockOutputForOperation(ProductionOrder, FirstOperationNoTok, SendAheadQty - 1);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);

        // [WHEN] Calculate Subcontracts runs with the option switched on
        CalculateSubcontracts(WorkCenter, true);

        // [THEN] A worksheet line is proposed for "O1" only
        VerifyReqLineExists(Item."No.", WorkCenter[1]."Subcontractor No.");
        VerifyReqLineNotExists(Item."No.", WorkCenter[2]."Subcontractor No.");
    end;

    [Test]
    procedure CalcSubcontractsWithReadinessGateProposesOperationAtStartThreshold()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
        SendAheadQty: Decimal;
    begin
        // [SCENARIO] With the option Only Operations Ready to Start switched on, an operation whose predecessor operation has reached its start threshold is proposed.
        Initialize();

        // [GIVEN] An item with a serial routing of two subcontracted operations "O1" and "O2"; "O1" has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(5, 10);
        CreateItemWithTwoSubcontractedOperations(Item, WorkCenter, SendAheadQty);

        // [GIVEN] A refreshed released production order with quantity "Q" > "S"
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "S" is posted on "O1", so "O2" is ready to start
        MockOutputForOperation(ProductionOrder, FirstOperationNoTok, SendAheadQty);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, SendAheadQty);

        // [WHEN] Calculate Subcontracts runs with the option switched on
        CalculateSubcontracts(WorkCenter, true);

        // [THEN] Worksheet lines are proposed for "O1" and for "O2"
        VerifyReqLineExists(Item."No.", WorkCenter[1]."Subcontractor No.");
        VerifyReqLineExists(Item."No.", WorkCenter[2]."Subcontractor No.");
    end;

    [Test]
    procedure CalcSubcontractsWithReadinessGateKeepsQuantityToPurchase()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
        QtyWithoutGate: array[2] of Decimal;
        SendAheadQty: Decimal;
        Index: Integer;
    begin
        // [SCENARIO] The readiness gate never changes the quantity to purchase of a proposed operation.
        Initialize();

        // [GIVEN] An item with a serial routing of two subcontracted operations "O1" and "O2"; "O1" has Send-Ahead Quantity "S"
        SendAheadQty := LibraryRandom.RandIntInRange(5, 10);
        CreateItemWithTwoSubcontractedOperations(Item, WorkCenter, SendAheadQty);

        // [GIVEN] A refreshed released production order with quantity "Q" > "S"; output "S" is posted on "O1", so "O2" is ready to start
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandIntInRange(20, 50));
        MockOutputForOperation(ProductionOrder, FirstOperationNoTok, SendAheadQty);

        // [GIVEN] Calculate Subcontracts ran with the option switched off; its quantities to purchase for "O1" and "O2" are recorded
        CalculateSubcontracts(WorkCenter, false);
        for Index := 1 to ArrayLen(WorkCenter) do
            QtyWithoutGate[Index] := GetReqLineQuantity(Item."No.", WorkCenter[Index]."Subcontractor No.");

        // [WHEN] Calculate Subcontracts runs again with the option switched on
        CalculateSubcontracts(WorkCenter, true);

        // [THEN] The quantities to purchase for "O1" and "O2" are identical to the run with the option switched off
        for Index := 1 to ArrayLen(WorkCenter) do
            Assert.AreEqual(
              QtyWithoutGate[Index], GetReqLineQuantity(Item."No.", WorkCenter[Index]."Subcontractor No."),
              StrSubstNo(QtyToPurchaseChangedErr, WorkCenter[Index]."Subcontractor No."));
    end;

    [Test]
    procedure CalcSubcontractsWithReadinessGateExcludesProductionFamilyTogether()
    var
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
        FamilyItemNo: array[2] of Code[20];
        SendAheadQty: Decimal;
        Index: Integer;
    begin
        // [SCENARIO] With the option Only Operations Ready to Start switched on, a not-ready shared operation of a production family is excluded for every family item.
        Initialize();

        // [GIVEN] A family of two items "I1" and "I2" with a serial routing of two subcontracted operations "O1" and "O2"; "O1" has Send-Ahead Quantity "S"
        SendAheadQty := 2 * LibraryRandom.RandIntInRange(3, 5);
        CreateFamilyWithTwoSubcontractedOperations(Family, FamilyItemNo, WorkCenter, SendAheadQty);

        // [GIVEN] A refreshed released production order for the family with quantity "Q" > "S"
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Family, Family."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "S" / 2 is posted on "O1" for "I1" only, so the shared "O2" is not ready to start
        MockOutputForOperation(ProductionOrder, FamilyItemNo[1], FirstOperationNoTok, SendAheadQty / 2);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);

        // [WHEN] Calculate Subcontracts runs with the option switched on
        CalculateSubcontracts(WorkCenter, true);

        // [THEN] "O1" is proposed for "I1" and "I2", and "O2" is proposed for neither
        for Index := 1 to ArrayLen(FamilyItemNo) do begin
            VerifyReqLineExists(FamilyItemNo[Index], WorkCenter[1]."Subcontractor No.");
            VerifyReqLineNotExists(FamilyItemNo[Index], WorkCenter[2]."Subcontractor No.");
        end;
    end;

    [Test]
    procedure CalcSubcontractsWithReadinessGateProposesProductionFamilyTogether()
    var
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        WorkCenter: array[2] of Record "Work Center";
        FamilyItemNo: array[2] of Code[20];
        SendAheadQty: Decimal;
        Index: Integer;
    begin
        // [SCENARIO] With the option Only Operations Ready to Start switched on, a ready shared operation of a production family is proposed for every family item.
        Initialize();

        // [GIVEN] A family of two items "I1" and "I2" with a serial routing of two subcontracted operations "O1" and "O2"; "O1" has Send-Ahead Quantity "S"
        SendAheadQty := 2 * LibraryRandom.RandIntInRange(3, 5);
        CreateFamilyWithTwoSubcontractedOperations(Family, FamilyItemNo, WorkCenter, SendAheadQty);

        // [GIVEN] A refreshed released production order for the family with quantity "Q" > "S"
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Family, Family."No.", LibraryRandom.RandIntInRange(20, 50));

        // [GIVEN] Output "S" / 2 is posted on "O1" for "I1" and for "I2", so the shared "O2" is ready to start on the combined output "S"
        for Index := 1 to ArrayLen(FamilyItemNo) do
            MockOutputForOperation(ProductionOrder, FamilyItemNo[Index], FirstOperationNoTok, SendAheadQty / 2);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, SendAheadQty);

        // [WHEN] Calculate Subcontracts runs with the option switched on
        CalculateSubcontracts(WorkCenter, true);

        // [THEN] "O1" and "O2" are proposed for "I1" and for "I2"
        for Index := 1 to ArrayLen(FamilyItemNo) do begin
            VerifyReqLineExists(FamilyItemNo[Index], WorkCenter[1]."Subcontractor No.");
            VerifyReqLineExists(FamilyItemNo[Index], WorkCenter[2]."Subcontractor No.");
        end;
    end;

    [Test]
    procedure CreateSubcontractingOrderForNotReadyOperationWithoutDialog()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: array[2] of Record "Work Center";
        SubcTestManSubscription: Codeunit "Subc. Test Man. Subscription";
        ProdOrderQty: Decimal;
    begin
        // [SCENARIO] Create Subcontracting Order on the production order routing creates the purchase order for an operation that is not ready to start, without a readiness check or a dialog.
        Initialize();

        // [GIVEN] An item with a serial routing of two subcontracted operations "O1" and "O2"; "O1" has Send-Ahead Quantity "S"
        CreateItemWithTwoSubcontractedOperations(Item, WorkCenter, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] A refreshed released production order with quantity "Q"; no output is posted, so "O2" is not ready to start
        ProdOrderQty := LibraryRandom.RandIntInRange(20, 50);
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", ProdOrderQty);
        VerifyQtyReadyToStart(ProductionOrder, SecondOperationNoTok, 0);

        // [GIVEN] The existing question whether to show the created purchase order is handled by its subscriber
        BindSubscription(SubcTestManSubscription);

        // [WHEN] Create Subcontracting Order is invoked on "O2" on the production order routing
        SubcManagementLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter[2]."No.");

        // [THEN] A subcontracting purchase line with quantity "Q" exists for "O2"
        // [THEN] No dialog is shown: the test declares no UI handler, so any Confirm or Message would fail it
        PurchaseLine.SetCurrentKey("Prod. Order No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        PurchaseLine.SetRange("Operation No.", SecondOperationNoTok);
        PurchaseLine.SetLoadFields(Quantity);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Quantity, ProdOrderQty);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Readiness Gate Test");
        LibrarySetupStorage.Restore();

        SubcManagementLibrary.Initialize();
        SubcManagementLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.CreateSubcontractingReqWkshNameAndUpdateSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Readiness Gate Test");

        SubcSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        SubcSetupLibrary.InitialSetupForGenProdPostingGroup();
        LibraryMfgManagement.Initialize();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Readiness Gate Test");
    end;

    local procedure CreateItemWithTwoSubcontractedOperations(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; SendAheadQty: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", CreateRoutingWithTwoSubcontractedOperations(WorkCenter, SendAheadQty));
        Item.Modify(true);
    end;

    local procedure CreateFamilyWithTwoSubcontractedOperations(var Family: Record Family; var FamilyItemNo: array[2] of Code[20]; var WorkCenter: array[2] of Record "Work Center"; SendAheadQty: Decimal)
    var
        FamilyItem: Record Item;
        FamilyLine: Record "Family Line";
        Index: Integer;
    begin
        LibraryManufacturing.CreateFamily(Family);
        for Index := 1 to ArrayLen(FamilyItemNo) do begin
            LibraryInventory.CreateItem(FamilyItem);
            LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", FamilyItem."No.", 1);
            FamilyItemNo[Index] := FamilyItem."No.";
        end;
        Family.Validate("Routing No.", CreateRoutingWithTwoSubcontractedOperations(WorkCenter, SendAheadQty));
        Family.Modify(true);
    end;

    local procedure CreateRoutingWithTwoSubcontractedOperations(var WorkCenter: array[2] of Record "Work Center"; SendAheadQty: Decimal): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryMfgManagement.CreateSubcontractingWorkCenterWithCalendar(WorkCenter[1]);
        LibraryMfgManagement.CreateSubcontractingWorkCenterWithCalendar(WorkCenter[2]);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, WorkCenter[1]."No.", FirstOperationNoTok, 0, LibraryRandom.RandInt(5));
        RoutingLine.Validate("Send-Ahead Quantity", SendAheadQty);
        RoutingLine.Modify(true);
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, WorkCenter[2]."No.", SecondOperationNoTok, 0, LibraryRandom.RandInt(5));
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        exit(RoutingHeader."No.");
    end;

    local procedure CalculateSubcontracts(WorkCenter: array[2] of Record "Work Center"; OnlyOperationsReadyToStart: Boolean)
    var
        WorkCenterToCalculate: Record "Work Center";
    begin
        WorkCenterToCalculate.SetFilter("No.", '%1|%2', WorkCenter[1]."No.", WorkCenter[2]."No.");
        SubcManagementLibrary.CalculateSubcontractOrder(WorkCenterToCalculate, OnlyOperationsReadyToStart);
    end;

    local procedure MockOutputForOperation(ProductionOrder: Record "Production Order"; OperationNo: Code[10]; OutputQty: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetLoadFields("Item No.", "Routing No.", "Routing Reference No.");
        ProdOrderLine.FindFirst();
        SubcManagementLibrary.MockOutputForOperation(ProdOrderLine, OperationNo, OutputQty);
    end;

    local procedure MockOutputForOperation(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; OperationNo: Code[10]; OutputQty: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Item No.");
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.SetLoadFields("Item No.", "Routing No.", "Routing Reference No.");
        ProdOrderLine.FindFirst();
        SubcManagementLibrary.MockOutputForOperation(ProdOrderLine, OperationNo, OutputQty);
    end;

    local procedure SetReqLineFilters(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; VendorNo: Code[20])
    begin
        RequisitionLine.SetCurrentKey(Type, "No.");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.SetRange("Vendor No.", VendorNo);
    end;

    local procedure GetReqLineQuantity(ItemNo: Code[20]; VendorNo: Code[20]): Decimal
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SetReqLineFilters(RequisitionLine, ItemNo, VendorNo);
        RequisitionLine.SetLoadFields(Quantity);
        RequisitionLine.FindFirst();
        exit(RequisitionLine.Quantity);
    end;

    local procedure VerifyReqLineExists(ItemNo: Code[20]; VendorNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SetReqLineFilters(RequisitionLine, ItemNo, VendorNo);
        Assert.IsFalse(RequisitionLine.IsEmpty(), StrSubstNo(ReqLineExpectedErr, ItemNo, VendorNo));
    end;

    local procedure VerifyReqLineNotExists(ItemNo: Code[20]; VendorNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SetReqLineFilters(RequisitionLine, ItemNo, VendorNo);
        Assert.IsTrue(RequisitionLine.IsEmpty(), StrSubstNo(ReqLineNotExpectedErr, ItemNo, VendorNo));
    end;

    local procedure VerifyQtyReadyToStart(ProductionOrder: Record "Production Order"; OperationNo: Code[10]; ExpectedQtyReadyToStart: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetLoadFields("Routing No.", "Routing Reference No.");
        ProdOrderLine.FindFirst();
        ProdOrderRoutingLine.SetLoadFields("Quantity Ready to Start");
        ProdOrderRoutingLine.Get(
            ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Routing Reference No.", ProdOrderLine."Routing No.", OperationNo);
        Assert.AreEqual(ExpectedQtyReadyToStart, ProdOrderRoutingLine."Quantity Ready to Start", StrSubstNo(QtyReadyToStartErr, OperationNo));
    end;
}
