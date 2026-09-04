// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Setup;

codeunit 139983 "Subc. Management Library"
{
    procedure Initialize()
    begin
        CreateSubcontractingManagementSetup();
    end;

    procedure CreateSubcontractingManagementSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert(true);
        end;
    end;

    procedure CreateSubContractingPrice(var SubcontractorPrices: Record "Subcontractor Price"; WorkCenterNo: Code[20]; VendorNo: Code[20]; ItemNo: Code[20]; StandardTaskCode: Code[10]; VariantCode: Code[10]; StartDate: Date; UnitOfMeasureCode: Code[10]; MinimumQuantity: Decimal; CurrencyCode: Code[10])
    begin
        SubcontractorPrices.Init();
        SubcontractorPrices.Validate("Work Center No.", WorkCenterNo);
        SubcontractorPrices.Validate("Vendor No.", VendorNo);
        SubcontractorPrices.Validate("Item No.", ItemNo);
        SubcontractorPrices.Validate("Standard Task Code", StandardTaskCode);
        SubcontractorPrices.Validate("Variant Code", VariantCode);
        SubcontractorPrices.Validate("Starting Date", StartDate);
        SubcontractorPrices.Validate("Unit of Measure Code", UnitOfMeasureCode);
        SubcontractorPrices.Validate("Minimum Quantity", MinimumQuantity);
        SubcontractorPrices.Validate("Currency Code", CurrencyCode);
        SubcontractorPrices.Insert(true);
    end;

    procedure CreateSubcontractorPrice(Item: Record Item; WorkCenterNo: Code[20]; var SubcontractorPrice: Record "Subcontractor Price")
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        LibraryRandom: Codeunit "Library - Random";
        i: Integer;
        NoOfLoops: Integer;
    begin
        SubcontractorPrice.DeleteAll();
        NoOfLoops := LibraryRandom.RandInt(20);

        WorkCenter.Get(WorkCenterNo);
        Vendor.Get(WorkCenter."Subcontractor No.");
        for i := 1 to NoOfLoops do begin
            SubcontractorPrice.Init();
            SubcontractorPrice."Vendor No." := Vendor."No.";
            SubcontractorPrice."Item No." := Item."No.";
            SubcontractorPrice."Work Center No." := WorkCenter."No.";
            SubcontractorPrice."Unit of Measure Code" := Item."Base Unit of Measure";
            SubcontractorPrice."Currency Code" := Vendor."Currency Code";
            SubcontractorPrice."Minimum Quantity" := i;
            SubcontractorPrice."Direct Unit Cost" := LibraryRandom.RandInt(100);
            SubcontractorPrice.Insert();
        end;
    end;

    procedure UpdateProdBomWithComponentSupplyMethod(Item: Record Item; ComponentSupplyMethod: Enum "Component Supply Method")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        ProductionBOMLine."Component Supply Method" := ComponentSupplyMethod;
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    procedure UpdateProdOrderCompWithLocationCode(ProdOrderNo: Code[20])
    var
        Location: Record Location;
        ProdOrderComp: Record "Prod. Order Component";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderNo);
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ProdOrderComp."Location Code" := Location.Code;
        ProdOrderComp.Modify();
    end;

    procedure UpdateVendorWithSubcontractingLocationCode(WorkCenter: Record "Work Center")
    var
        Location: Record Location;
        Vendor: Record Vendor;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Get(WorkCenter."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
    end;

    procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderSourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; Quantity: Decimal)
    var
        LibraryManufacturing: Codeunit "Library - Manufacturing";
    begin
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, ProdOrderStatus, ProdOrderSourceType, SourceNo, Quantity);
    end;

    procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderSourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        LibraryManufacturing: Codeunit "Library - Manufacturing";
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProdOrderStatus, ProdOrderSourceType, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify();

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    procedure UpdateSubMgmtSetup_ComponentAtLocation(CompAtLocation: Enum "Components at Location")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup."Subc. Default Comp. Location" := CompAtLocation;
        ManufacturingSetup.Modify();
    end;

    procedure CreateSubcontractingOrderFromProdOrderRtngPage(RoutingNo: Code[20]; WorkCenterNo: Code[20])
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

    procedure SetupInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        Location: Record Location;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        WarehouseSetup: Record "Warehouse Setup";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        if not InventorySetup.Get() then
            InventorySetup.Init();

        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'SUBC0000001', 'SUBC9999999');
        InventorySetup.Validate("Internal Movement Nos.", NoSeries.Code);
        InventorySetup.Validate("Inventory Movement Nos.", NoSeries.Code);
        InventorySetup.Validate("Inventory Pick Nos.", NoSeries.Code);
        InventorySetup.Validate("Inventory Put-away Nos.", NoSeries.Code);
        InventorySetup.Validate("Item Nos.", NoSeries.Code);
        InventorySetup.Validate("Posted Invt. Pick Nos.", NoSeries.Code);
        InventorySetup.Validate("Posted Transfer Rcpt. Nos.", NoSeries.Code);
        InventorySetup.Validate("Posted Transfer Shpt. Nos.", NoSeries.Code);
        InventorySetup.Validate("Registered Invt. Movement Nos.", NoSeries.Code);
        InventorySetup.Validate("Transfer Order Nos.", NoSeries.Code);
        InventorySetup.Validate("Posted Invt. Put-away Nos.", NoSeries.Code);
        InventorySetup."Direct Transfer Posting Type" := InventorySetup."Direct Transfer Posting Type"::"Direct Transfer";
        InventorySetup.Modify();

        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Purchases & Payables Setup", PurchasesPayablesSetup.FieldNo("Order Nos."));

        WarehouseSetup.Get();
        WarehouseSetup.Validate("Posted Whse. Receipt Nos.", NoSeries.Code);
        WarehouseSetup.Validate("Posted Whse. Shipment Nos.", NoSeries.Code);
        WarehouseSetup.Validate("Registered Whse. Movement Nos.", NoSeries.Code);
        WarehouseSetup.Validate("Registered Whse. Pick Nos.", NoSeries.Code);
        WarehouseSetup.Validate("Registered Whse. Put-away Nos.", NoSeries.Code);
        WarehouseSetup.Validate("Whse. Movement Nos.", NoSeries.Code);
        WarehouseSetup.Validate("Whse. Pick Nos.", NoSeries.Code);
        WarehouseSetup.Validate("Whse. Put-away Nos.", NoSeries.Code);
        WarehouseSetup.Validate("Whse. Receipt Nos.", NoSeries.Code);
        WarehouseSetup.Validate("Whse. Ship Nos.", NoSeries.Code);
        WarehouseSetup.Validate("Whse. Internal Pick Nos.", NoSeries.Code);
        WarehouseSetup.Validate("Whse. Internal Put-away Nos.", NoSeries.Code);
        WarehouseSetup.Modify(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
    end;

    procedure CreateTransferRoute(WorkCenter: Record "Work Center"; ProductionOrder: Record "Production Order")
    var
        TransitLocation: Record Location;
        ProdOrderComp: Record "Prod. Order Component";
        TransferRoute: Record "Transfer Route";
        Vendor: Record Vendor;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        Vendor.Get(WorkCenter."Subcontractor No.");
        ProdOrderComp.SetRange(Status, ProductionOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        ProdOrderComp.SetRange("Component Supply Method", ProdOrderComp."Component Supply Method"::"Transfer to Vendor");
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, ProdOrderComp."Location Code", Vendor."Subc. Location Code", TransitLocation.Code, '', '');
    end;

    procedure UpdateManufacturingSetupWithSubcontractingLocation()
    var
        Location: Record Location;
        ManufacturingSetup: Record "Manufacturing Setup";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ManufacturingSetup.Get();
        ManufacturingSetup."Components at Location" := Location.Code;
        ManufacturingSetup.Modify();
        UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Manufacturing);
    end;

    procedure CreateReqWkshTemplateAndName(var ReqWkshTemplate: Record "Req. Wksh. Template"; var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Subcontracting);
        ReqWkshTemplate.SetRange(Recurring, false);
        if not ReqWkshTemplate.FindFirst() then begin
            ReqWkshTemplate.Init();
            ReqWkshTemplate.Validate(
                Name, CopyStr(LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), Database::"Req. Wksh. Template"), 1, 10));
            ReqWkshTemplate.Insert(true);
            ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::Subcontracting);
            ReqWkshTemplate."Page ID" := Page::"Subc. Subcontracting Worksheet";
            ReqWkshTemplate.Modify(true);
        end;

        RequisitionWkshName.Init();
        RequisitionWkshName.Validate("Worksheet Template Name", ReqWkshTemplate.Name);
        RequisitionWkshName.Validate(
            Name,
            CopyStr(LibraryUtility.GenerateRandomCode(RequisitionWkshName.FieldNo(Name), Database::"Requisition Wksh. Name"),
                1, LibraryUtility.GetFieldLength(Database::"Requisition Wksh. Name", RequisitionWkshName.FieldNo(Name))));
        RequisitionWkshName.Insert(true);
    end;

    procedure CreateWIPLedgerEntry(var WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry"; ItemNo: Code[20]; LocationCode: Code[10]; ProductionOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenterNo: Code[20]; QuantityBase: Decimal; InTransit: Boolean)
    var
        Item: Record Item;
    begin
        if WIPLedgerEntry.FindLast() then;
        WIPLedgerEntry.Init();
        WIPLedgerEntry."Entry No." := WIPLedgerEntry.GetNextEntryNo();
        WIPLedgerEntry."Item No." := ItemNo;
        WIPLedgerEntry."Location Code" := LocationCode;
        WIPLedgerEntry."Prod. Order Status" := "Production Order Status"::Released;
        WIPLedgerEntry."Prod. Order No." := ProductionOrder."No.";
        WIPLedgerEntry."Prod. Order Line No." := ProdOrderLine."Line No.";
        WIPLedgerEntry."Routing No." := ProdOrderRoutingLine."Routing No.";
        WIPLedgerEntry."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        WIPLedgerEntry."Operation No." := ProdOrderRoutingLine."Operation No.";
        WIPLedgerEntry."Work Center No." := WorkCenterNo;
        WIPLedgerEntry."Quantity (Base)" := QuantityBase;
        WIPLedgerEntry."In Transit" := InTransit;
        Item.SetLoadFields("Base Unit of Measure");
        Item.Get(ItemNo);
        WIPLedgerEntry."Base Unit of Measure" := Item."Base Unit of Measure";
        WIPLedgerEntry.Insert();
    end;

    /// <summary>
    /// Updates the component supply method on all components of a production order.
    /// </summary>
    /// <param name="ProductionOrder">The production order whose components are updated.</param>
    /// <param name="ComponentSupplyMethod">The component supply method to assign.</param>
    procedure UpdateProdOrderComponentWithComponentSupplyMethod(ProductionOrder: Record "Production Order"; ComponentSupplyMethod: Enum "Component Supply Method")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComp.ModifyAll("Component Supply Method", ComponentSupplyMethod);
    end;

    /// <summary>
    /// Calculates subcontracts for a worksheet and finds the line for a production order.
    /// </summary>
    /// <param name="RequisitionWkshName">The subcontracting worksheet to calculate.</param>
    /// <param name="ProdOrderNo">The production order number to find.</param>
    /// <param name="RequisitionLine">Returns the calculated requisition line.</param>
    procedure CalculateSubcontractsAndFindReqLine(RequisitionWkshName: Record "Requisition Wksh. Name"; ProdOrderNo: Code[20]; var RequisitionLine: Record "Requisition Line")
    var
        SubcCalculateSubContract: Report "Subc. Calculate Subcontracts";
    begin
        Clear(RequisitionLine);
        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;

        SubcCalculateSubContract.SetWkShLine(RequisitionLine);
        SubcCalculateSubContract.UseRequestPage(false);
        SubcCalculateSubContract.RunModal();

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
#pragma warning disable AA0210
        RequisitionLine.SetRange("Prod. Order No.", ProdOrderNo);
#pragma warning restore AA0210
        RequisitionLine.FindFirst();
    end;

    /// <summary>
    /// Carries out the action message for a subcontracting requisition line.
    /// </summary>
    /// <param name="RequisitionLine">The requisition line whose action message is carried out.</param>
    procedure CarryOutSubcontractingAction(var RequisitionLine: Record "Requisition Line")
    var
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgReq.UseRequestPage(false);
        CarryOutActionMsgReq.RunModal();
    end;

    /// <summary>
    /// Finds a subcontracting purchase line for an item and production order.
    /// </summary>
    /// <param name="PurchaseLine">Returns the matching purchase line.</param>
    /// <param name="ItemNo">The item number to find.</param>
    /// <param name="ProdOrderNo">The production order number to find.</param>
    procedure FindSubcPurchLineForProdOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; ProdOrderNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.SetRange("Prod. Order No.", ProdOrderNo);
        PurchaseLine.FindFirst();
    end;

    /// <summary>
    /// Filters purchase lines to a component item on a purchase order.
    /// </summary>
    /// <param name="PurchaseLineComp">Returns the filtered purchase-line record.</param>
    /// <param name="DocumentNo">The purchase order number to filter by.</param>
    /// <param name="ComponentItemNo">The component item number to filter by.</param>
    procedure FindComponentPurchLine(var PurchaseLineComp: Record "Purchase Line"; DocumentNo: Code[20]; ComponentItemNo: Code[20])
    begin
        PurchaseLineComp.SetRange("Document Type", PurchaseLineComp."Document Type"::Order);
        PurchaseLineComp.SetRange("Document No.", DocumentNo);
        PurchaseLineComp.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLineComp.SetRange("No.", ComponentItemNo);
    end;
}