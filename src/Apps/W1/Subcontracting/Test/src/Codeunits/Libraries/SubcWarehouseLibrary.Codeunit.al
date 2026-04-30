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

    /// <summary>
    /// Creates and calculates needed work and machine centers.
    /// </summary>
    /// <param name="WorkCenter">The array of work centers which will be created</param>
    /// <param name="MachineCenter">The array of machine centers which will be created</param>
    /// <param name="Subcontracting">Indicates if the work centers are subcontracting work centers</param>
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

    /// <summary>
    /// Creates and calculates needed work and machine centers for the same vendor
    /// </summary>
    /// <param name="WorkCenter">The Work Center which has been created</param>
    /// <param name="MachineCenter">The Machine Center which has been created</param>
    /// <param name="Subcontracting">Indicates if the work center is a subcontracting work center</param>
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

    /// <summary>
    /// Creates an item with a production BOM and routing, where the routing has both in-house and subcontracting operations. The subcontracting operations are linked to the provided work centers and machine centers.
    /// The item created is a finished good item which can be used for end-to-end testing of the subcontracting flow from production order creation to warehouse receipt.
    /// This function is used to set up the data for testing the scenario where a production order has both in-house and subcontracting operations, and the impact on warehouse receipts when posting the production order.
    /// </summary>
    /// <param name="Item">The item record which will be created</param>
    /// <param name="WorkCenter">The array of work centers which will be linked to the subcontracting operations in the routing</param>
    /// <param name="MachineCenter">The array of machine centers which will be linked to the in-house operations in the routing</param>
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

    /// <summary>
    /// Creates a routing with the specified machine centers and work centers.
    /// </summary>
    /// <param name="MachineCenter">The array of machine centers to be used in the routing</param>
    /// <param name="WorkCenter">The array of work centers to be used in the routing</param>
    /// <returns>The routing number of the created routing</returns>
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

    /// <summary>
    /// Updates the production BOM and routing with the specified routing link.
    /// </summary>
    /// <param name="Item">The item record which will be updated</param>
    /// <param name="WorkCenterNo">The work center number to be linked to the routing</param>
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

    /// <summary>
    /// Updates the production BOM and routing with the specified routing links for both operations.
    /// </summary>
    /// <param name="Item">The item record which will be updated</param>
    /// <param name="WorkCenter">The array of work centers to be linked to the routing</param>
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

    /// <summary>
    /// Creates a location with warehouse handling enabled.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    procedure CreateLocationWithWarehouseHandling(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, true, false);
        Location."Require Receive" := true;
        Location."Require Put-away" := true;
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    /// <summary>
    /// Creates a location with warehouse handling enabled and require receive only (not put-away).
    /// This is used to test scenarios where the location requires a warehouse receipt but does not require
    /// a warehouse put-away. The expected behavior in this case is that when receiving into this location, a warehouse receipt will be created,
    /// but no put-away will be required and the item will be received directly into the location without needing to be put away to another location.
    /// This allows testing of the system's handling of warehouse receipts when put-away is not required.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    procedure CreateLocationWithRequireReceiveOnly(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, false);
        Location."Require Receive" := true;
        Location."Require Put-away" := false;
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    /// <summary>
    /// Creates a location with bin mandatory enabled only.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    procedure CreateLocationWithBinMandatoryOnly(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        Location."Require Receive" := false;
        Location."Require Put-away" := false;
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    /// <summary>
    /// Creates a location with warehouse handling enabled and bin mandatory. This is used to test scenarios where the location requires a warehouse receipt and put-away,
    /// and also requires that items be placed in bins within the location.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    procedure CreateLocationWithWarehouseHandlingAndBinMandatory(var Location: Record Location)
    begin
        // Creates location with Bin Mandatory = true, Require Receive = true, Require Put-away = true
        // This creates Take/Place warehouse activity lines with Bin Code
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, true, false);
        Location."Require Receive" := true;
        Location."Require Put-away" := true;
        Location.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    /// <summary>
    /// Creates a location with warehouse handling enabled and bins for both receiving and put-away.
    /// </summary>
    /// <param name="Location">The location record which will be created and updated</param>
    /// <param name="ReceiveBin">The bin record which will be created and updated for receiving</param>
    /// <param name="PutAwayBin">The bin record which will be created and updated for put-away</param>
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

    /// <summary>
    /// Creates and refreshes a production order with the specified parameters. This function is used to set up production orders for testing scenarios that involve production orders and their impact on warehouse receipts.
    /// </summary>
    /// <param name="ProductionOrder">The production order record which will be created and updated</param>
    /// <param name="Status">The status of the production order</param>
    /// <param name="SourceType">The source type of the production order</param>
    /// <param name="SourceNo">The source number of the production order</param>
    /// <param name="Quantity">The quantity of the production order</param>
    /// <param name="LocationCode">The location code of the production order</param>
    procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, Status, SourceType, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    /// <summary>
    /// Updates the subcontracting management setup with a labor requirement worksheet template and name. This is used to set up the subcontracting management parameters for testing scenarios that involve subcontracting and the use of labor requirement worksheets in the subcontracting process.
    /// </summary>
    procedure UpdateSubMgmtSetupWithReqWkshTemplate()
    begin
        SubcLibraryMfgManagement.CreateLaborReqWkshTemplateAndNameAndUpdateSetup();
    end;

    // ========================================
    // PURCHASE ORDER FUNCTIONS
    // ========================================

    /// <summary>
    /// Creates a subcontracting purchase order from a production order routing line with the specified routing number and work center number, and finds the created purchase line.
    /// This function is used to set up subcontracting purchase orders for testing scenarios that involve the creation of subcontracting purchase orders from production order routings and
    /// their impact on warehouse receipts.
    /// </summary>
    /// <param name="RoutingNo">The routing number of the production order</param>
    /// <param name="WorkCenterNo">The work center number of the production order</param>
    /// <param name="PurchaseLine">The purchase line record which will be created and updated</param>
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

    /// <summary>
    /// Creates subcontracting purchase orders from worksheet lines for the specified production order.
    /// </summary>
    /// <param name="ProductionOrderNo">The production order number used to filter worksheet and resulting purchase lines</param>
    /// <param name="PurchaseHeader">The purchase header record which will be found for the created purchase order</param>
    procedure CreateSubcontractingOrdersViaWorksheet(ProductionOrderNo: Code[20]; var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        SubMgmtSetup: Record "Subc. Management Setup";
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        // Get worksheet template and batch from setup
        SubMgmtSetup.Get();

        // Initialize requisition line for the Calculate Subcontracts report
        RequisitionLine."Worksheet Template Name" := SubMgmtSetup."Subcontracting Template Name";
        RequisitionLine."Journal Batch Name" := SubMgmtSetup."Subcontracting Batch Name";

        // Calculate subcontracting lines to fill the worksheet
        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

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

    /// <summary>
    /// Creates a warehouse receipt from a released purchase order.
    /// </summary>
    /// <param name="PurchaseHeader">The purchase header record that is released and used as source</param>
    /// <param name="WarehouseReceiptHeader">The warehouse receipt header record that will be found after creation</param>
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

    /// <summary>
    /// Creates a warehouse receipt header and populates it using get source documents for the given location.
    /// </summary>
    /// <param name="WarehouseReceiptHeader">The warehouse receipt header record which will be created and populated</param>
    /// <param name="LocationCode">The location code used to retrieve source documents</param>
    procedure CreateWarehouseReceiptUsingGetSourceDocuments(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);

        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, LocationCode);
    end;

    /// <summary>
    /// Posts a warehouse receipt and finds the resulting posted warehouse receipt header.
    /// </summary>
    /// <param name="WarehouseReceiptHeader">The warehouse receipt header to post</param>
    /// <param name="PostedWhseReceiptHeader">The posted warehouse receipt header found after posting</param>
    procedure PostWarehouseReceipt(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header")
    begin
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        PostedWhseReceiptHeader.SetRange("Whse. Receipt No.", WarehouseReceiptHeader."No.");
        PostedWhseReceiptHeader.FindFirst();
    end;

    /// <summary>
    /// Posts a partial warehouse receipt for the specified quantity and finds the latest posted warehouse receipt header.
    /// </summary>
    /// <param name="WarehouseReceiptHeader">The warehouse receipt header to post partially</param>
    /// <param name="PartialQuantity">The quantity to receive on the warehouse receipt line</param>
    /// <param name="PostedWhseReceiptHeader">The posted warehouse receipt header found after posting</param>
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

    /// <summary>
    /// Creates a put-away document from a posted warehouse receipt if none exists and returns the latest put-away header.
    /// </summary>
    /// <param name="PostedWhseReceiptHeader">The posted warehouse receipt header used as source for put-away creation</param>
    /// <param name="WarehouseActivityHeader">The warehouse activity header for the created or existing put-away</param>
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

    /// <summary>
    /// Posts a partial put-away by setting quantity to handle on all lines and registering the warehouse activity.
    /// </summary>
    /// <param name="WarehouseActivityHeader">The warehouse activity header for the put-away to register</param>
    /// <param name="PartialQuantity">The quantity to handle assigned to each warehouse activity line</param>
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

    /// <summary>
    /// Creates a put-away worksheet name for the specified location, ensuring a put-away worksheet template exists.
    /// </summary>
    /// <param name="WhseWorksheetTemplate">The worksheet template record that is found or created</param>
    /// <param name="WhseWorksheetName">The worksheet name record that is created</param>
    /// <param name="LocationCode">The location code assigned to the worksheet name</param>
    procedure CreatePutAwayWorksheet(var WhseWorksheetTemplate: Record "Whse. Worksheet Template"; var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    begin
        EnsurePutAwayWorksheetTemplate(WhseWorksheetTemplate);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
    end;

    /// <summary>
    /// Ensures that a put-away worksheet template exists by finding an existing one or creating a new one.
    /// </summary>
    /// <param name="WhseWorksheetTemplate">The worksheet template record that is found or created</param>
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

    /// <summary>
    /// Retrieves inbound source documents for the put-away worksheet at the specified location.
    /// </summary>
    /// <param name="WhseWorksheetTemplateName">The worksheet template name used by the worksheet context</param>
    /// <param name="WhseWorksheetName">The worksheet name record used to populate worksheet lines</param>
    /// <param name="LocationCode">The location code used to filter put-away requests</param>
    procedure GetWarehouseDocumentsForPutAwayWorksheet(WhseWorksheetTemplateName: Code[10]; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhsePutAwayRequest: Record "Whse. Put-away Request";
    begin
        WhsePutAwayRequest.SetRange("Completely Put Away", false);
        WhsePutAwayRequest.SetRange("Location Code", LocationCode);
        LibraryWarehouse.GetInboundSourceDocuments(WhsePutAwayRequest, WhseWorksheetName, LocationCode);
    end;

    /// <summary>
    /// Creates a put-away document from worksheet lines and returns the latest put-away warehouse activity header.
    /// </summary>
    /// <param name="WhseWorksheetName">The worksheet name containing the worksheet lines to process</param>
    /// <param name="WarehouseActivityHeader">The warehouse activity header found after document creation</param>
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

    /// <summary>
    /// Verifies that output item ledger entries exist for the item and location and match the expected quantity.
    /// </summary>
    /// <param name="ItemNo">The item number to verify</param>
    /// <param name="ExpectedQuantity">The expected summed output quantity</param>
    /// <param name="LocationCode">The location code to verify</param>
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

    /// <summary>
    /// Verifies that capacity ledger entries exist for the work center and match the expected output quantity.
    /// </summary>
    /// <param name="WorkCenterNo">The work center number to verify</param>
    /// <param name="ExpectedQuantity">The expected summed output quantity</param>
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

    /// <summary>
    /// Verifies that bin content exists for the given location, bin, and item and matches the expected quantity.
    /// </summary>
    /// <param name="LocationCode">The location code to verify</param>
    /// <param name="BinCode">The bin code to verify</param>
    /// <param name="ItemNo">The item number to verify</param>
    /// <param name="ExpectedQuantity">The expected bin content quantity</param>
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

    /// <summary>
    /// Sets up a complete subcontracting warehouse scenario including item, location, production order, and purchase order.
    /// </summary>
    /// <param name="Item">The item record that is created and configured for the scenario</param>
    /// <param name="Location">The location record that is created and configured for warehouse handling</param>
    /// <param name="ProductionOrder">The production order record that is created and refreshed</param>
    /// <param name="PurchaseHeader">The purchase header record found for the created subcontracting purchase order</param>
    /// <param name="Quantity">The production order quantity used in the setup</param>
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

    /// <summary>
    /// Creates a production item with lot tracking setup using generated number series and routing/BOM configuration.
    /// </summary>
    /// <param name="Item">The item record that is created and updated with lot tracking setup</param>
    /// <param name="WorkCenter">The work centers used when creating routing data for the item</param>
    /// <param name="MachineCenter">The machine centers used when creating routing data for the item</param>
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

    /// <summary>
    /// Creates a production item with serial tracking setup using generated number series and routing/BOM configuration.
    /// </summary>
    /// <param name="Item">The item record that is created and updated with serial tracking setup</param>
    /// <param name="WorkCenter">The work centers used when creating routing data for the item</param>
    /// <param name="MachineCenter">The machine centers used when creating routing data for the item</param>
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
