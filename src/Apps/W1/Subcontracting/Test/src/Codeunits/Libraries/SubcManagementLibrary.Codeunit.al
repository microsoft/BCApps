// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

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
using Microsoft.Purchases.Vendor;

codeunit 139983 "Subc. Management Library"
{
    procedure Initialize()
    begin
        CreateSubcontractingManagementSetup();
    end;

    procedure CreateSubcontractingManagementSetup()
    var
        SubcontractingManagementSetup: Record "Subc. Management Setup";
    begin
        SubcontractingManagementSetup.Reset();
        if not SubcontractingManagementSetup.Get() then begin
            SubcontractingManagementSetup.Init();
            SubcontractingManagementSetup.Insert(true);
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

    procedure UpdateProdBomWithSubcontractingType(Item: Record Item; SubcontractingType: Enum "Subcontracting Type")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::New);
        ProductionBOMHeader.Modify(true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindLast();
        ProductionBOMLine."Subcontracting Type" := SubcontractingType;
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
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
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
        Vendor."Subcontr. Location Code" := Location.Code;
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

    procedure UpdateSubMgmtSetupDirectTransfer(DirectTransfer: Boolean)
    var
        SubcMgmtSetup: Record "Subc. Management Setup";
    begin
        SubcMgmtSetup.Get();
        SubcMgmtSetup."Direct Transfer" := DirectTransfer;
        SubcMgmtSetup.Modify();
    end;

    procedure UpdateSubMgmtSetup_ComponentAtLocation(CompAtLocation: Enum "Components at Location")
    var
        SubcMgmtSetup: Record "Subc. Management Setup";
    begin
        SubcMgmtSetup.Get();
        SubcMgmtSetup."Component at Location" := CompAtLocation;
        SubcMgmtSetup.Modify();
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
        Location: Record Location;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        if not InventorySetup.Get() then
            InventorySetup.Init();

        LibraryInventory.NoSeriesSetup(InventorySetup);
        InventorySetup."Inventory Put-away Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        InventorySetup."Direct Transfer Posting Type" := InventorySetup."Direct Transfer Posting Type"::"Direct Transfer";
        InventorySetup.Modify();
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
        ProdOrderComp.SetRange("Subcontracting Type", ProdOrderComp."Subcontracting Type"::Transfer);
#pragma warning restore AA0210
        ProdOrderComp.FindFirst();
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, ProdOrderComp."Location Code", Vendor."Subcontr. Location Code", TransitLocation.Code, '', '');
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
        WIPLedgerEntry."Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        WIPLedgerEntry.Insert();
    end;
}