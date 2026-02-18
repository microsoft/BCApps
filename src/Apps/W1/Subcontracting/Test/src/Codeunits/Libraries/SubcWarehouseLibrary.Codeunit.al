// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
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
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

codeunit 149908 "Subc. Warehouse Library"
{
    // [FEATURE] Subcontracting Warehouse Test Library
    // Consolidated data creation functions for warehouse tests to avoid code duplication

    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SubcLibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";

    // ========================================
    // MANUFACTURING SETUP FUNCTIONS
    // ========================================

    procedure CreateAndCalculateNeededWorkAndMachineCenter(var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center"; Subcontracting: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        Location: Record Location;
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
        WorkCenterNo: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryManufacturing.UpdateShopCalendarWorkingDays();

        if Subcontracting then begin
            LibraryPurchase.CreateSubcontractor(Vendor1);
            Vendor1."Subcontr. Location Code" := LibraryWarehouse.CreateLocation(Location);
            Vendor1.Modify(true);
            LibraryPurchase.CreateSubcontractor(Vendor2);
            Vendor2."Subcontr. Location Code" := LibraryWarehouse.CreateLocation(Location);
            Vendor2.Modify(true);
        end;

        // Create first work center
        SubcLibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter[1], LibraryRandom.RandDec(10, 2));
        WorkCenterNo := WorkCenter[1]."No.";

        if Subcontracting then begin
            WorkCenter[1]."Subcontractor No." := Vendor1."No.";
            WorkCenter[1].Modify(true);
        end;

        // Create machine centers
        LibraryManufacturing.CreateMachineCenterWithCalendar(
            MachineCenter[1], WorkCenterNo, LibraryRandom.RandDec(10, 1));

        LibraryManufacturing.CreateMachineCenterWithCalendar(
            MachineCenter[2], WorkCenterNo, LibraryRandom.RandDec(10, 1));

        // Create second work center
        SubcLibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter[2], LibraryRandom.RandDec(10, 2));

        if Subcontracting then begin
            WorkCenter[2]."Subcontractor No." := Vendor2."No.";
            WorkCenter[2].Modify(true);
        end;
    end;

    procedure CreateAndCalculateNeededWorkAndMachineCenterSameVendor(var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center"; Subcontracting: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        Vendor: Record Vendor;
        WorkCenterNo: Code[20];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        LibraryManufacturing.UpdateShopCalendarWorkingDays();

        // Create single vendor for both work centers
        if Subcontracting then
            LibraryPurchase.CreateSubcontractor(Vendor);

        // Create first work center
        SubcLibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter[1], LibraryRandom.RandDec(10, 2));
        WorkCenterNo := WorkCenter[1]."No.";

        if Subcontracting then begin
            WorkCenter[1]."Subcontractor No." := Vendor."No.";
            WorkCenter[1].Modify(true);
        end;

        // Create machine centers for first work center
        LibraryManufacturing.CreateMachineCenterWithCalendar(
            MachineCenter[1], WorkCenterNo, LibraryRandom.RandDec(10, 1));

        LibraryManufacturing.CreateMachineCenterWithCalendar(
            MachineCenter[2], WorkCenterNo, LibraryRandom.RandDec(10, 1));

        // Create second work center with same vendor
        SubcLibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter[2], LibraryRandom.RandDec(10, 2));

        if Subcontracting then begin
            WorkCenter[2]."Subcontractor No." := Vendor."No.";
            WorkCenter[2].Modify(true);
        end;
    end;

    procedure CreateItemForProductionIncludeRoutingAndProdBOM(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMNo: Code[20];
        RoutingNo: Code[20];
    begin
        // Create routing
        RoutingNo := CreateRouting(MachineCenter, WorkCenter);

        // Create component items
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);

        // Create production BOM
        ProductionBOMNo := LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, Item2."No.", Item3."No.", 1);

        // Create finished item
        LibraryManufacturing.CreateItemManufacturing(
            Item, "Costing Method"::FIFO, LibraryRandom.RandDec(10, 2),
            "Reordering Policy"::" ", "Flushing Method"::Backward, RoutingNo, ProductionBOMNo);
    end;

    procedure CreateRouting(var MachineCenter: array[2] of Record "Machine Center"; var WorkCenter: array[2] of Record "Work Center"): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // Create routing lines
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Machine Center", MachineCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Machine Center", MachineCenter[2]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '30', RoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '40', RoutingLine.Type::"Work Center", WorkCenter[2]."No.");

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        exit(RoutingHeader."No.");
    end;

    procedure UpdateProdBomAndRoutingWithRoutingLink(Item: Record Item; WorkCenterNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
    begin
        // Create routing link
        LibraryManufacturing.CreateRoutingLink(RoutingLink);

        // Update routing
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenterNo);
        if RoutingLine.FindFirst() then begin
            RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
            RoutingLine.Modify(true);
        end;

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // Update production BOM
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        if ProductionBOMLine.FindLast() then begin
            ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
            ProductionBOMLine.Modify(true);
        end;

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    procedure UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item: Record Item; var WorkCenter: array[2] of Record "Work Center")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink1: Record "Routing Link";
        RoutingLink2: Record "Routing Link";
    begin
        // Create routing links for both operations
        LibraryManufacturing.CreateRoutingLink(RoutingLink1);
        LibraryManufacturing.CreateRoutingLink(RoutingLink2);

        // Update routing
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);

        // Update first operation (intermediate)
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.SetRange(Type, RoutingLine.Type::"Work Center");
        RoutingLine.SetRange("No.", WorkCenter[1]."No.");
        if RoutingLine.FindFirst() then begin
            RoutingLine.Validate("Routing Link Code", RoutingLink1.Code);
            RoutingLine.Modify(true);
        end;

        // Update second operation (last)
        RoutingLine.SetRange("No.", WorkCenter[2]."No.");
        if RoutingLine.FindFirst() then begin
            RoutingLine.Validate("Routing Link Code", RoutingLink2.Code);
            RoutingLine.Modify(true);
        end;

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // Update production BOM
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        if ProductionBOMLine.FindFirst() then begin
            ProductionBOMLine.Validate("Routing Link Code", RoutingLink1.Code);
            ProductionBOMLine.Modify(true);
        end;
        if ProductionBOMLine.FindLast() then begin
            ProductionBOMLine.Validate("Routing Link Code", RoutingLink2.Code);
            ProductionBOMLine.Modify(true);
        end;

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    // ========================================
    // LOCATION & WAREHOUSE SETUP FUNCTIONS
    // ========================================

    procedure CreateLocationWithWarehouseHandling(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, true, false);
        Location."Require Receive" := true;
        Location."Require Put-away" := true;
        Location.Modify(true);
        LibraryERMCountryData.UpdateInventoryPostingSetup();
    end;

    procedure CreateLocationWithRequireReceiveOnly(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        Location."Require Receive" := true;
        Location."Require Put-away" := false;
        Location.Modify(true);
        LibraryERMCountryData.UpdateInventoryPostingSetup();
    end;

    procedure CreateLocationWithBinMandatoryOnly(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        Location."Require Receive" := false;
        Location."Require Put-away" := false;
        Location.Modify(true);
        LibraryERMCountryData.UpdateInventoryPostingSetup();
    end;

    procedure CreateLocationWithWarehouseHandlingAndBinMandatory(var Location: Record Location)
    begin
        // Creates location with Bin Mandatory = true, Require Receive = true, Require Put-away = true
        // This creates Take/Place warehouse activity lines with Bin Code
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, true, false);
        Location."Require Receive" := true;
        Location."Require Put-away" := true;
        Location.Modify(true);
        LibraryERMCountryData.UpdateInventoryPostingSetup();
    end;

    procedure CreateLocationWithWarehouseHandlingAndBins(var Location: Record Location; var ReceiveBin: Record Bin; var PutAwayBin: Record Bin)
    begin
        // Creates location with Bin Mandatory = true, Require Receive = true, Require Put-away = true
        // Sets up both Receive Bin (for warehouse receipt) and Default Bin (for put-away destination)
        CreateLocationWithWarehouseHandlingAndBinMandatory(Location);

        // Create receive bin - used when posting warehouse receipt
        LibraryWarehouse.CreateBin(ReceiveBin, Location.Code, 'RECEIVE', '', '');
        Location.Validate("Receipt Bin Code", ReceiveBin.Code);

        // Create put-away bin - destination for put-away Place line
        LibraryWarehouse.CreateBin(PutAwayBin, Location.Code, 'PUTAWAY', '', '');
        Location.Validate("Default Bin Code", PutAwayBin.Code);

        Location.Modify(true);
    end;

    // ========================================
    // PRODUCTION ORDER FUNCTIONS
    // ========================================

    procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, Status, SourceType, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    procedure UpdateSubMgmtSetupWithReqWkshTemplate()
    begin
        SubcLibraryMfgManagement.CreateLaborReqWkshTemplateAndNameAndUpdateSetup();
    end;

    // ========================================
    // PURCHASE ORDER FUNCTIONS
    // ========================================

    procedure CreateSubcontractingOrderFromProdOrderRouting(RoutingNo: Code[20]; WorkCenterNo: Code[20]; var PurchaseLine: Record "Purchase Line")
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
    begin
        ProdOrderRtngLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRtngLine.SetRange(Type, ProdOrderRtngLine.Type::"Work Center");
        ProdOrderRtngLine.SetRange("Work Center No.", WorkCenterNo);
        ProdOrderRtngLine.FindFirst();

        SubcPurchaseOrderCreator.CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRtngLine);

        // Find the created purchase line
        PurchaseLine.SetRange("Routing No.", RoutingNo);
        PurchaseLine.SetRange("Work Center No.", WorkCenterNo);
        PurchaseLine.FindFirst();
    end;

    procedure CreateSubcontractingOrdersViaWorksheet(ProductionOrderNo: Code[20]; var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        SubMgmtSetup: Record "Subc. Management Setup";
        CalculateSubContract: Report "Calculate Subcontracts";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        // Get worksheet template and batch from setup
        SubMgmtSetup.Get();

        // Initialize requisition line for the Calculate Subcontracts report
        RequisitionLine."Worksheet Template Name" := SubMgmtSetup."Subcontracting Template Name";
        RequisitionLine."Journal Batch Name" := SubMgmtSetup."Subcontracting Batch Name";

        // Calculate subcontracting lines to fill the worksheet
        CalculateSubContract.SetWkShLine(RequisitionLine);
        CalculateSubContract.UseRequestPage(false);
        CalculateSubContract.RunModal();

        // Find requisition lines for the production order
        RequisitionLine.SetRange("Worksheet Template Name", SubMgmtSetup."Subcontracting Template Name");
        RequisitionLine.SetRange("Journal Batch Name", SubMgmtSetup."Subcontracting Batch Name");
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProductionOrderNo);
#pragma warning restore AA0210
        RequisitionLine.FindFirst();

        // Create purchase orders from the worksheet - combines lines for same vendor into one PO
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();

        // Find the created purchase header
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
#pragma warning disable AA0210
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrderNo);
#pragma warning restore AA0210
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    // ========================================
    // WAREHOUSE DOCUMENT FUNCTIONS
    // ========================================

    procedure CreateWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
    end;

    procedure CreateWarehouseReceiptUsingGetSourceDocuments(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);

        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, LocationCode);
    end;

    procedure PostWarehouseReceipt(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    begin
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WarehouseReceiptHeader."No.");
        PostedWhseReceiptHeader.FindFirst();
    end;

    procedure PostPartialWarehouseReceipt(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; PartialQuantity: Decimal; var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("No.", WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptLine.Validate("Qty. to Receive", PartialQuantity);
        WarehouseReceiptLine.Modify(true);

        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WarehouseReceiptHeader."No.");
        PostedWhseReceiptHeader.FindLast();
    end;

    // ========================================
    // PUT-AWAY FUNCTIONS
    // ========================================

    procedure CreatePutAwayFromPostedWhseReceipt(PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header"; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        PostedWhseReceiptLine.SetRange("No.", PostedWhseReceiptHeader."No.");
        PostedWhseReceiptLine.FindFirst();

        WarehouseActivityLine.SetRange("Location Code", PostedWhseReceiptHeader."Location Code");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Source Type", PostedWhseReceiptLine."Source Type");
        WarehouseActivityLine.SetRange("Source No.", PostedWhseReceiptLine."Source No.");

        if WarehouseActivityLine.IsEmpty() then begin
            PostedWhseReceiptLine.SetHideValidationDialog(true);
            PostedWhseReceiptLine.CreatePutAwayDoc(PostedWhseReceiptLine, PostedWhseReceiptHeader."Assigned User ID");
        end;

        if WarehouseActivityLine.FindLast() then
            WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    procedure PostPartialPutAway(var WarehouseActivityHeader: Record "Warehouse Activity Header"; PartialQuantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.Validate("Qty. to Handle", PartialQuantity);
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;

        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    // ========================================
    // PUT-AWAY WORKSHEET FUNCTIONS
    // ========================================

    procedure CreatePutAwayWorksheet(var WhseWorksheetTemplate: Record "Whse. Worksheet Template"; var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    begin
        EnsurePutAwayWorksheetTemplate(WhseWorksheetTemplate);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
    end;

    local procedure EnsurePutAwayWorksheetTemplate(var WhseWorksheetTemplate: Record "Whse. Worksheet Template")
    begin
        // Try to find existing put-away template
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::"Put-away");
        if WhseWorksheetTemplate.FindFirst() then
            exit;

        // No template exists, create one
        WhseWorksheetTemplate.Init();
        WhseWorksheetTemplate.Validate(Name,
            CopyStr(LibraryUtility.GenerateRandomCode(WhseWorksheetTemplate.FieldNo(Name), Database::"Whse. Worksheet Template"),
                1, MaxStrLen(WhseWorksheetTemplate.Name)));
        WhseWorksheetTemplate.Validate(Type, WhseWorksheetTemplate.Type::"Put-away");
        WhseWorksheetTemplate.Validate(Description, 'Put-away Worksheet');
        WhseWorksheetTemplate.Validate("Page ID", Page::"Put-away Worksheet");
        WhseWorksheetTemplate.Insert(true);
    end;

    procedure GetWarehouseDocumentsForPutAwayWorksheet(WhseWorksheetTemplateName: Code[10]; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhsePutAwayRequest: Record "Whse. Put-away Request";
    begin
        WhsePutAwayRequest.SetRange("Completely Put Away", false);
        WhsePutAwayRequest.SetRange("Location Code", LocationCode);
        LibraryWarehouse.GetInboundSourceDocuments(WhsePutAwayRequest, WhseWorksheetName, LocationCode);
    end;

    procedure CreatePutAwayFromWorksheet(WhseWorksheetName: Record "Whse. Worksheet Name"; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", WhseWorksheetName."Location Code");
        WhseWorksheetLine.FindFirst();

        // Create put-away from worksheet lines using correct function
        LibraryWarehouse.WhseSourceCreateDocument(
            WhseWorksheetLine,
            "Whse. Activity Sorting Method"::None,
            false,
            false,
            false);

        WarehouseActivityHeader.SetRange("Location Code", WhseWorksheetName."Location Code");
        WarehouseActivityHeader.SetRange(Type, WarehouseActivityHeader.Type::"Put-away");
        WarehouseActivityHeader.FindLast();
    end;

    // ========================================
    // VERIFICATION FUNCTIONS
    // ========================================

    procedure VerifyItemLedgerEntry(ItemNo: Code[20]; ExpectedQuantity: Decimal; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Assert: Codeunit Assert;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);

        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(ExpectedQuantity, ItemLedgerEntry.Quantity,
            'Item Ledger Entry should have correct output quantity');
    end;

    procedure VerifyCapacityLedgerEntry(WorkCenterNo: Code[20]; ExpectedQuantity: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Assert: Codeunit Assert;
    begin
        CapacityLedgerEntry.SetRange(Type, CapacityLedgerEntry.Type::"Work Center");
        CapacityLedgerEntry.SetRange("No.", WorkCenterNo);
        Assert.RecordIsNotEmpty(CapacityLedgerEntry);

        CapacityLedgerEntry.CalcSums("Output Quantity");
        Assert.AreEqual(ExpectedQuantity, CapacityLedgerEntry."Output Quantity",
            'Capacity Ledger Entry should have correct output quantity');
    end;

    procedure VerifyBinContents(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        BinContent: Record "Bin Content";
        Assert: Codeunit Assert;
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        Assert.RecordIsNotEmpty(BinContent);

        BinContent.FindFirst();
        BinContent.CalcFields(Quantity);
        Assert.AreEqual(ExpectedQuantity, BinContent.Quantity,
            'Bin contents should show correct quantity after put-away posting');
    end;

    // ========================================
    // COMPLETE SCENARIO SETUP FUNCTIONS
    // ========================================

    procedure SetupCompleteSubcontractingWarehouseScenario(var Item: Record Item; var Location: Record Location; var ProductionOrder: Record "Production Order"; var PurchaseHeader: Record "Purchase Header"; Quantity: Decimal)
    var
        MachineCenter: array[2] of Record "Machine Center";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // Complete setup for most common warehouse scenarios
        CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        UpdateProdBomAndRoutingWithRoutingLink(Item, WorkCenter[2]."No.");
        CreateLocationWithWarehouseHandling(Location);

        // Configure vendor with location
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subcontr. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // Create production order
        CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", Quantity, Location.Code);

        // Setup subcontracting
        UpdateSubMgmtSetupWithReqWkshTemplate();

        // Create purchase order
        CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    procedure CreateLotTrackedItemForProductionWithSetup(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        LotNoSeries: Record "No. Series";
        LotNoSeriesLine: Record "No. Series Line";
    begin
        // Implemented by Copilot - Create lot tracking components internally
        LibraryUtility.CreateNoSeries(LotNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(LotNoSeriesLine, LotNoSeries.Code,
            PadStr(Format(CurrentDateTime(), 0, 'L<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'),
            PadStr(Format(CurrentDateTime(), 0, 'L<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, false);

        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LotNoSeries.Code);
        Item.Modify(true);
    end;

    procedure CreateSerialTrackedItemForProductionWithSetup(var Item: Record Item; var WorkCenter: array[2] of Record "Work Center"; var MachineCenter: array[2] of Record "Machine Center")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        SerialNoSeries: Record "No. Series";
        SerialNoSeriesLine: Record "No. Series Line";
    begin
        // Create serial tracking components internally
        LibraryUtility.CreateNoSeries(SerialNoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(SerialNoSeriesLine, SerialNoSeries.Code,
            PadStr(Format(CurrentDateTime(), 0, 'S<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '0'),
            PadStr(Format(CurrentDateTime(), 0, 'S<Year><Month,2><Day,2><Hours24><Minutes><Seconds>'), 19, '9'));
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false, false);

        CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", SerialNoSeries.Code);
        Item.Modify(true);
    end;
}
