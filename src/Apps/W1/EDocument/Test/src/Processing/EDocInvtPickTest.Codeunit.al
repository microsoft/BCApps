// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using System.TestLibraries.Utilities;

codeunit 139863 "E-Doc. Invt. Pick Test"
{
    Subtype = Test;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure InvtPickWithWrongLotOnBinDoesNotCreateShipmentOrILE()
    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        Location: Record Location;
        Bin: Record Bin;
        WrongBin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        EDocument: Record "E-Document";
        WarehouseEmployee: Record "Warehouse Employee";
        SalesOrderNo: Code[20];
        LotNo: Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [E-Document] [Inventory Pick] [Warehouse]
        // [SCENARIO 625438] Posting Inventory Pick with wrong Lot No. on Bin does not create
        //   Posted Sales Shipment, ILE, or E-Document when E-Document Service Flow is active.
        //   Previously, E-Document subscriber caused a premature Commit() that persisted the
        //   Sales Shipment and ILE even when the warehouse bin check failed.

        // [GIVEN] E-Document service configured for Sales Shipment
        Initialize(Customer, EDocumentService);
        Qty := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Location with Bin Mandatory and Require Pick
        CreateLocationWithBinMandatoryAndRequirePick(Location, Bin, WrongBin, WarehouseEmployee);

        // [GIVEN] Lot-tracked item with stock on BIN-A
        CreateLotTrackedItem(Item);
        LotNo := LibraryUtility.GenerateGUID();
        CreateAndPostInvtAdjustmentWithLotTracking(Item."No.", Location.Code, Bin.Code, Qty, LotNo);

        // [GIVEN] Sales Order with the item on this location
        CreateSalesOrderWithItemOnLocation(SalesHeader, SalesLine, Customer, Item, Location, Qty);
        SalesOrderNo := SalesHeader."No.";

        // [GIVEN] Inventory Pick created for the Sales Order
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateInventoryPickFromSalesOrder(SalesHeader);

        // [GIVEN] Pick line set to take Lot from BIN-B where the Lot does NOT exist
        // Assign Bin Code directly to bypass OnValidate bin content check — simulates
        // the invalid state that the posting engine must catch and roll back.
        FindInventoryPickLine(WarehouseActivityHeader, WarehouseActivityLine, SalesOrderNo);
        WarehouseActivityLine."Lot No." := LotNo;
        WarehouseActivityLine."Bin Code" := WrongBin.Code;
        WarehouseActivityLine.Modify(true);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);

        // [WHEN] Post the Inventory Pick — should fail because lot is not on BIN-B
        Commit();
        asserterror LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] No Posted Sales Shipment was created
        SalesShipmentHeader.SetRange("Order No.", SalesOrderNo);
        Assert.RecordIsEmpty(SalesShipmentHeader);

        // [THEN] No Sale Item Ledger Entry was created
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        Assert.RecordIsEmpty(ItemLedgerEntry);

        // [THEN] No E-Document was created
        EDocument.SetRange("Document Type", Enum::"E-Document Type"::"Sales Shipment");
        EDocument.SetRange("Bill-to/Pay-to No.", Customer."No.");
        Assert.RecordIsEmpty(EDocument);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure InvtPickWithCorrectLotOnBinCreatesShipmentAndEDocument()
    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        Location: Record Location;
        Bin: Record Bin;
        WrongBin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        EDocument: Record "E-Document";
        WarehouseEmployee: Record "Warehouse Employee";
        SalesOrderNo: Code[20];
        LotNo: Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [E-Document] [Inventory Pick] [Warehouse]
        // [SCENARIO 625438] Posting Inventory Pick with correct Lot No. on Bin creates
        //   Posted Sales Shipment, ILE and E-Document consistently.
        //   The E-Document is created via deferred OnAfterPostWhseActivityCompleted event.

        // [GIVEN] E-Document service configured for Sales Shipment
        Initialize(Customer, EDocumentService);
        Qty := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Location with Bin Mandatory and Require Pick
        CreateLocationWithBinMandatoryAndRequirePick(Location, Bin, WrongBin, WarehouseEmployee);

        // [GIVEN] Lot-tracked item with stock on BIN-A
        CreateLotTrackedItem(Item);
        LotNo := LibraryUtility.GenerateGUID();
        CreateAndPostInvtAdjustmentWithLotTracking(Item."No.", Location.Code, Bin.Code, Qty, LotNo);

        // [GIVEN] Sales Order with the item on this location
        CreateSalesOrderWithItemOnLocation(SalesHeader, SalesLine, Customer, Item, Location, Qty);
        SalesOrderNo := SalesHeader."No.";

        // [GIVEN] Inventory Pick created for the Sales Order
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateInventoryPickFromSalesOrder(SalesHeader);

        // [GIVEN] Pick line with correct Lot and correct Bin
        FindInventoryPickLine(WarehouseActivityHeader, WarehouseActivityLine, SalesOrderNo);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
        LibraryWarehouse.SetQtyToHandleWhseActivity(WarehouseActivityHeader, WarehouseActivityLine.Quantity);

        // [WHEN] Post the Inventory Pick
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Posted Sales Shipment exists
        SalesShipmentHeader.SetRange("Order No.", SalesOrderNo);
        Assert.RecordIsNotEmpty(SalesShipmentHeader);

        // [THEN] Item Ledger Entry exists for the sale
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Location Code", Location.Code);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);

        // [THEN] E-Document was created for the shipment
        SalesShipmentHeader.FindFirst();
        EDocument.SetRange("Document Type", Enum::"E-Document Type"::"Sales Shipment");
        EDocument.SetRange("Document No.", SalesShipmentHeader."No.");
        Assert.RecordIsNotEmpty(EDocument);
    end;

    local procedure Initialize(var Customer: Record Customer; var EDocumentService: Record "E-Document Service")
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        GLSetup: Record "General Ledger Setup";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        LibraryVariableStorage.Clear();

        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocumentService.DeleteAll();

        GLSetup.GetRecordOnce();
        GLSetup."VAT Reporting Date Usage" := GLSetup."VAT Reporting Date Usage"::Disabled;
        GLSetup.Modify();

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::"Mock");
        LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Shipment");

        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
    end;

    local procedure CreateLocationWithBinMandatoryAndRequirePick(
        var Location: Record Location;
        var Bin: Record Bin;
        var WrongBin: Record Bin;
        var WarehouseEmployee: Record "Warehouse Employee")
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'BIN-A', '', '');
        LibraryWarehouse.CreateBin(WrongBin, Location.Code, 'BIN-B', '', '');
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateLotTrackedItem(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        StandardItem: Record Item;
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);

        // Use the standard E-Doc item's VAT Prod. Posting Group to avoid blocked VAT setup
        LibraryEDoc.GetGenericItem(StandardItem);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("VAT Prod. Posting Group", StandardItem."VAT Prod. Posting Group");
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure CreateAndPostInvtAdjustmentWithLotTracking(
        ItemNo: Code[20];
        LocationCode: Code[10];
        BinCode: Code[20];
        Qty: Decimal;
        LotNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);

        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ItemJournalLine.OpenItemTrackingLines(false);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateSalesOrderWithItemOnLocation(
        var SalesHeader: Record "Sales Header";
        var SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        Qty: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Qty);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreateInventoryPickFromSalesOrder(var SalesHeader: Record "Sales Header")
    var
        WhseRequest: Record "Warehouse Request";
        CreateInvtPutPick: Report "Create Invt Put-away/Pick/Mvmt";
    begin
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetRange("Source Document", WhseRequest."Source Document"::"Sales Order");
        WhseRequest.SetRange("Source No.", SalesHeader."No.");
        CreateInvtPutPick.SetTableView(WhseRequest);
        CreateInvtPutPick.InitializeRequest(false, true, false, false, false);
        CreateInvtPutPick.UseRequestPage(false);
        CreateInvtPutPick.SuppressMessages(true);
        CreateInvtPutPick.RunModal();
    end;

    local procedure FindInventoryPickLine(
        var WarehouseActivityHeader: Record "Warehouse Activity Header";
        var WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesOrderNo: Code[20])
    begin
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Invt. Pick");
        WarehouseActivityHeader.SetRange("Source No.", SalesOrderNo);
        WarehouseActivityHeader.FindFirst();

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
    end;

    [ModalPageHandler]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines.New();
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

}
