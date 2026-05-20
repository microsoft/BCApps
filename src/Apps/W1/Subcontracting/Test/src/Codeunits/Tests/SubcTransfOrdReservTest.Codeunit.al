// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using System.TestLibraries.Utilities;

codeunit 149915 "Subc. Transf. Ord. Reserv. Test"
{
    // [FEATURE] Subcontracting Transfer Order Reservation Integration Tests
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure FullQuantityTransferTransfersAllReservationsWithoutConfirm()
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
    begin
        // [SCENARIO] Full quantity transfer moves all component reservations to the transfer order without showing the excess cancellation message.

        // [GIVEN] A transfer-subcontracting production order with a transfer component quantity of 30 and matching component reservations
        Initialize();
        SetupTransferReservationScenario(Item, WorkCenter, MachineCenter, ProductionOrder, ProdOrderComponent, 10, 3, false);
        CreateReservationOnProdOrderComp(ProdOrderComponent, 30, ProdOrderComponent."Location Code");

        // [WHEN] A subcontracting purchase order is created for the full production quantity and a transfer order is created from it
        CreateSubcontractingPurchaseOrderAndReduceQuantity(Item, WorkCenter[2], ProductionOrder, PurchaseHeader, PurchaseLine, 0);
        CreateTransferOrder(PurchaseHeader);
        FindTransferLine(TransferLine, ProductionOrder, ProdOrderComponent);

        // [THEN] All reservations are transferred to the transfer line and no excess reservation confirm dialog is shown
        TransferLine.CalcFields("Reserved Qty. Outbnd. (Base)");
        Assert.AreEqual(30, TransferLine."Quantity (Base)", 'Transfer line base qty mismatch');
        Assert.AreEqual(30, TransferLine."Reserved Qty. Outbnd. (Base)", 'Reserved qty outbound must match transfer qty');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting')]
    procedure PartialQuantityWithReservationsBlocksTransferCreation()
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
    begin
        // [SCENARIO 634236] Creating a transfer order when the transfer quantity is less than the reserved quantity on the component must be blocked with an error.

        // [GIVEN] A released production order with quantity 10, transfer component quantity per 3, and 30 reserved component quantity
        Initialize();
        SetupTransferReservationScenario(Item, WorkCenter, MachineCenter, ProductionOrder, ProdOrderComponent, 10, 3, false);
        CreateReservationOnProdOrderComp(ProdOrderComponent, 30, ProdOrderComponent."Location Code");

        // [WHEN] The subcontracting purchase order quantity is reduced from 10 to 6 before the transfer order is created
        CreateSubcontractingPurchaseOrderAndReduceQuantity(Item, WorkCenter[2], ProductionOrder, PurchaseHeader, PurchaseLine, 6);
        asserterror CreateTransferOrder(PurchaseHeader);

        // [THEN] Transfer creation is blocked and reservations on the component remain intact
        Assert.ExpectedError('Cancel existing reservations on the component before creating a partial transfer');
#pragma warning disable AA0210
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        Assert.RecordIsEmpty(TransferLine);
        Assert.AreEqual(1, CountProdOrderComponentReservations(ProdOrderComponent), 'Reservations on the component must remain intact when transfer is blocked');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting')]
    procedure PartialQuantitySerialReservationsBlocksTransferCreation()
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
    begin
        // [SCENARIO 634399] Creating a transfer order with serial-tracked component reservations when the transfer quantity is less than the reserved quantity must be blocked.

        // [GIVEN] A released production order with quantity 3, transfer component quantity per 2, and 6 serial-number component reservations
        Initialize();
        SetupTransferReservationScenario(Item, WorkCenter, MachineCenter, ProductionOrder, ProdOrderComponent, 3, 2, true);
        CreateSerialReservationsOnProdOrderComp(ProdOrderComponent, 6, ProdOrderComponent."Location Code");

        // [WHEN] The subcontracting purchase order quantity is reduced from 3 to 2 before the transfer order is created
        CreateSubcontractingPurchaseOrderAndReduceQuantity(Item, WorkCenter[2], ProductionOrder, PurchaseHeader, PurchaseLine, 2);
        asserterror CreateTransferOrder(PurchaseHeader);

        // [THEN] Transfer creation is blocked and serial reservations on the component remain intact
        Assert.ExpectedError('Cancel existing reservations on the component before creating a partial transfer');
#pragma warning disable AA0210
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        Assert.RecordIsEmpty(TransferLine);
        Assert.AreEqual(6, CountProdOrderComponentReservations(ProdOrderComponent), 'Serial reservations on the component must remain intact when transfer is blocked');
    end;

    [Test]
    [HandlerFunctions('DoNotConfirmShowCreatedPurchOrderForSubcontracting,HandleTransferOrder')]
    procedure PartialQuantityWithoutReservationsAllowsTransferCreation()
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        WorkCenter: array[2] of Record "Work Center";
        MachineCenter: array[2] of Record "Machine Center";
    begin
        // [SCENARIO] Reducing the subcontracting PO quantity when the component has no reservations must allow transfer creation without error.

        // [GIVEN] A released production order with quantity 10, transfer component quantity per 3, and NO reservations
        Initialize();
        SetupTransferReservationScenario(Item, WorkCenter, MachineCenter, ProductionOrder, ProdOrderComponent, 10, 3, false);

        // [WHEN] The subcontracting purchase order quantity is reduced from 10 to 6 and a transfer order is created
        CreateSubcontractingPurchaseOrderAndReduceQuantity(Item, WorkCenter[2], ProductionOrder, PurchaseHeader, PurchaseLine, 6);
        CreateTransferOrder(PurchaseHeader);

        // [THEN] Transfer line is created with the reduced quantity without error
#pragma warning disable AA0210
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        TransferLine.FindFirst();
        Assert.AreEqual(18, TransferLine."Quantity (Base)", 'Transfer line base qty should reflect the reduced PO qty');
    end;

    local procedure Initialize()
    begin
        OpenedTransferOrderNo := '';

        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Transf. Ord. Reserv. Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryVariableStorage.Clear();
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Transf. Ord. Reserv. Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Transf. Ord. Reserv. Test");
    end;

    local procedure SetupTransferReservationScenario(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center"; var ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component"; ProductionQty: Decimal; ComponentQtyPer: Decimal; SerialTrackedComponent: Boolean)
    begin
        SubcontractingMgmtLibrary.UpdateManufacturingSetupWithSubcontractingLocation();
        SubcontractingMgmtLibrary.SetupInventorySetup();

        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        SubcontractingMgmtLibrary.UpdateProdBomWithSubcontractingType(Item, "Subcontracting Type"::Transfer);
        UpdateTransferComponentQuantityPer(Item, ComponentQtyPer);
        if SerialTrackedComponent then
            EnableSerialTrackingOnTransferComponent(Item);
        SubcontractingMgmtLibrary.UpdateVendorWithSubcontractingLocationCode(WorkCenter[2]);

        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, ProductionOrder."Source Type"::Item, Item."No.", ProductionQty);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcontractingMgmtLibrary.UpdateProdOrderCompWithLocationCode(ProductionOrder."No.");
        SubcontractingMgmtLibrary.CreateTransferRoute(WorkCenter[2], ProductionOrder);
        FindTransferProdOrderComponent(ProdOrderComponent, ProductionOrder);
    end;

    local procedure UpdateTransferComponentQuantityPer(Item: Record Item; ComponentQtyPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        ProductionBOMLine.Validate("Quantity per", ComponentQtyPer);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure EnableSerialTrackingOnTransferComponent(Item: Record Item)
    var
        ComponentItem: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ItemTrackingCode: Record "Item Tracking Code";
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.FindLast();
        ComponentItem.Get(ProductionBOMLine."No.");

        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(
            SerialNoSeriesLine, SerialNoSeries.Code,
            PadStr(Format(CurrentDateTime(), 0, 'S<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'),
            PadStr(Format(CurrentDateTime(), 0, 'S<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, false);

        ComponentItem.Validate("Item Tracking Code", ItemTrackingCode.Code);
        ComponentItem.Validate("Serial Nos.", SerialNoSeries.Code);
        ComponentItem.Modify(true);
    end;

    local procedure CreateSubcontractingPurchaseOrderAndReduceQuantity(Item: Record Item; WorkCenter: Record "Work Center"; ProductionOrder: Record "Production Order"; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ReducedQty: Decimal)
    begin
        SubcontractingMgmtLibrary.CreateSubcontractingOrderFromProdOrderRtngPage(Item."Routing No.", WorkCenter."No.");

        PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
#pragma warning disable AA0210
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();

        if ReducedQty <> 0 then begin
            PurchaseLine.Validate(Quantity, ReducedQty);
            PurchaseLine.Modify(true);
        end;

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    local procedure CreateTransferOrder(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeaderPage: TestPage "Purchase Order";
    begin
        PurchaseHeaderPage.OpenView();
        PurchaseHeaderPage.GoToRecord(PurchaseHeader);
        PurchaseHeaderPage.CreateTransfOrdToSubcontractor.Invoke();
        PurchaseHeaderPage.Close();
    end;

    local procedure FindTransferProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComponent.SetRange("Subcontracting Type", ProdOrderComponent."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindTransferLine(var TransferLine: Record "Transfer Line"; ProductionOrder: Record "Production Order"; ProdOrderComponent: Record "Prod. Order Component")
    begin
#pragma warning disable AA0210
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        TransferLine.SetRange("Item No.", ProdOrderComponent."Item No.");
        TransferLine.SetRange("Subc. Prod. Ord. Comp Line No.", ProdOrderComponent."Line No.");
        TransferLine.FindFirst();
    end;

    local procedure CreateReservationOnProdOrderComp(ProdOrderComponent: Record "Prod. Order Component"; Qty: Decimal; LocationCode: Code[10])
    var
        ReservationEntry: Record "Reservation Entry";
        EntryNo: Integer;
    begin
        if ReservationEntry.FindLast() then
            EntryNo := ReservationEntry."Entry No." + 1
        else
            EntryNo := 1;

        ReservationEntry.Init();
        ReservationEntry."Entry No." := EntryNo;
        ReservationEntry.Positive := false;
        ReservationEntry."Item No." := ProdOrderComponent."Item No.";
        ReservationEntry."Location Code" := LocationCode;
        ReservationEntry."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Reservation;
        ReservationEntry."Source Type" := Database::"Prod. Order Component";
        ReservationEntry."Source Subtype" := ProdOrderComponent.Status.AsInteger();
        ReservationEntry."Source ID" := ProdOrderComponent."Prod. Order No.";
        ReservationEntry."Source Prod. Order Line" := ProdOrderComponent."Prod. Order Line No.";
        ReservationEntry."Source Ref. No." := ProdOrderComponent."Line No.";
        ReservationEntry.Quantity := -Qty;
        ReservationEntry."Quantity (Base)" := -Qty;
        ReservationEntry.Insert();
    end;

    local procedure CreateSerialReservationsOnProdOrderComp(ProdOrderComponent: Record "Prod. Order Component"; Qty: Integer; LocationCode: Code[10])
    var
        i: Integer;
    begin
        for i := 1 to Qty do
            CreateSerialReservationOnProdOrderComp(ProdOrderComponent, LocationCode, CopyStr(StrSubstNo('SN%1', i), 1, 50));
    end;

    local procedure CreateSerialReservationOnProdOrderComp(ProdOrderComponent: Record "Prod. Order Component"; LocationCode: Code[10]; SerialNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
        EntryNo: Integer;
    begin
        if ReservationEntry.FindLast() then
            EntryNo := ReservationEntry."Entry No." + 1
        else
            EntryNo := 1;

        ReservationEntry.Init();
        ReservationEntry."Entry No." := EntryNo;
        ReservationEntry.Positive := false;
        ReservationEntry."Item No." := ProdOrderComponent."Item No.";
        ReservationEntry."Location Code" := LocationCode;
        ReservationEntry."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Reservation;
        ReservationEntry."Serial No." := SerialNo;
        ReservationEntry."Source Type" := Database::"Prod. Order Component";
        ReservationEntry."Source Subtype" := ProdOrderComponent.Status.AsInteger();
        ReservationEntry."Source ID" := ProdOrderComponent."Prod. Order No.";
        ReservationEntry."Source Prod. Order Line" := ProdOrderComponent."Prod. Order Line No.";
        ReservationEntry."Source Ref. No." := ProdOrderComponent."Line No.";
        ReservationEntry.Quantity := -1;
        ReservationEntry."Quantity (Base)" := -1;
        ReservationEntry.Insert();
    end;

    local procedure CountProdOrderComponentReservations(ProdOrderComponent: Record "Prod. Order Component"): Integer
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Source Type", Database::"Prod. Order Component");
        ReservationEntry.SetRange("Source Subtype", ProdOrderComponent.Status.AsInteger());
        ReservationEntry.SetRange("Source ID", ProdOrderComponent."Prod. Order No.");
        ReservationEntry.SetRange("Source Prod. Order Line", ProdOrderComponent."Prod. Order Line No.");
        ReservationEntry.SetRange("Source Ref. No.", ProdOrderComponent."Line No.");
        exit(ReservationEntry.Count());
    end;

    [PageHandler]
    procedure HandleTransferOrder(var TransfOrderPage: TestPage "Transfer Order")
    begin
        OpenedTransferOrderNo := CopyStr(TransfOrderPage."No.".Value(), 1, MaxStrLen(OpenedTransferOrderNo));
        TransfOrderPage.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure DoNotConfirmShowCreatedPurchOrderForSubcontracting(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;
        OpenedTransferOrderNo: Code[20];
}