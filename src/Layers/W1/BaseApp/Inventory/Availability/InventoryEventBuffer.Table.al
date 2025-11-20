// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;

table 5530 "Inventory Event Buffer"
{
    Caption = 'Inventory Event Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(9; "Source Line ID"; RecordID)
        {
            Caption = 'Source Line ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = Item;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(12; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = Location;
        }
        field(14; "Availability Date"; Date)
        {
            Caption = 'Availability Date';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(15; Type; Enum "Inventory Event Buffer Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; "Remaining Quantity (Base)"; Decimal)
        {
            Caption = 'Remaining Quantity (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(21; Positive; Boolean)
        {
            Caption = 'Positive';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(22; "Transfer Direction"; Enum "Transfer Direction")
        {
            Caption = 'Transfer Direction';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(23; "Reserved Quantity (Base)"; Decimal)
        {
            Caption = 'Reserved Quantity (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(29; "Action Message"; Enum "Action Message Type")
        {
            Caption = 'Action Message';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(31; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(32; "Forecast Type"; Option)
        {
            Caption = 'Forecast Type';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionCaption = ',Sales,Component';
            OptionMembers = ,Sales,Component;
        }
        field(33; "Derived from Blanket Order"; Boolean)
        {
            Caption = 'Derived from Blanket Order';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(34; "Ref. Order No."; Code[20])
        {
            Caption = 'Ref. Order No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(35; "Orig. Quantity (Base)"; Decimal)
        {
            Caption = 'Orig. Quantity (Base)';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(37; "Ref. Order Type"; Option)
        {
            Caption = 'Ref. Order Type';
            DataClassification = SystemMetadata;
            Editable = false;
            OptionCaption = ' ,Purchase,Prod. Order,Assembly,Transfer';
            OptionMembers = " ",Purchase,"Prod. Order",Assembly,Transfer;
        }
        field(38; "Ref. Order Line No."; Integer)
        {
            Caption = 'Ref. Order Line No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Availability Date", Type)
        {
        }
    }

    fieldgroups
    {
    }

    var
        RecRef: RecordRef;

#if not CLEAN25
    [Obsolete('Moved to codeunit SalesAvailabilityMgt', '25.0')]
    procedure TransferFromSales(SalesLine: Record Microsoft.Sales.Document."Sales Line")
    var
        SalesAvailabilityMgt: Codeunit Microsoft.Sales.Document."Sales Availability Mgt.";
    begin
        SalesAvailabilityMgt.TransferFromSales(Rec, SalesLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit SalesAvailabilityMgt', '25.0')]
    procedure TransferFromSalesReturn(SalesLine: Record Microsoft.Sales.Document."Sales Line")
    var
        SalesAvailabilityMgt: Codeunit Microsoft.Sales.Document."Sales Availability Mgt.";
    begin
        SalesAvailabilityMgt.TransferFromSalesReturn(Rec, SalesLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ProdOrderAvailabilityMgt', '25.0')]
    procedure TransferFromProdComp(ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    var
        ProdOrderAvailabilityMgt: Codeunit Microsoft.Manufacturing.Document."Prod. Order Availability Mgt.";
    begin
        ProdOrderAvailabilityMgt.TransferFromProdComp(Rec, ProdOrderComp);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit JobPlanningAvailabilityMgt', '25.0')]
    procedure TransferFromJobNeed(JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    var
        JobPlanningAvailabilityMgt: Codeunit Microsoft.Projects.Project.Planning."Job Planning Availability Mgt.";
    begin
        JobPlanningAvailabilityMgt.TransferFromJobNeed(Rec, JobPlanningLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ServAvailabilityMgt', '25.0')]
    procedure TransferFromServiceNeed(ServiceLine: Record Microsoft.Service.Document."Service Line")
    var
        ServAvailabilityMgt: Codeunit Microsoft.Service.Document."Serv. Availability Mgt.";
    begin
        ServAvailabilityMgt.TransferFromServiceNeed(Rec, ServiceLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit TransferAvailabilityMgt', '25.0')]
    procedure TransferFromOutboundTransOrder(TransLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    var
        TransferAvailabilityMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Availability Mgt.";
    begin
        TransferAvailabilityMgt.TransferFromOutboundTransOrder(Rec, TransLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ReqLineAvailabilityMgt', '25.0')]
    procedure TransferFromPlanProdComp(PlngComp: Record Microsoft.Inventory.Planning."Planning Component")
    var
        ReqLineAvailabilityMgt: Codeunit Microsoft.Inventory.Requisition."Req. Line Availability Mgt.";
    begin
        ReqLineAvailabilityMgt.TransferFromPlanProdComp(Rec, PlngComp);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ReqLineAvailabilityMgt', '25.0')]
    procedure TransferFromReqLineTransDemand(ReqLine: Record Microsoft.Inventory.Requisition."Requisition Line")
    var
        ReqLineAvailabilityMgt: Codeunit Microsoft.Inventory.Requisition."Req. Line Availability Mgt.";
    begin
        ReqLineAvailabilityMgt.TransferFromReqLineTransDemand(Rec, ReqLine);
    end;
#endif

    procedure TransferInventoryQty(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        Init();
        RecRef.GetTable(ItemLedgEntry);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := ItemLedgEntry."Item No.";
        "Variant Code" := ItemLedgEntry."Variant Code";
        "Location Code" := ItemLedgEntry."Location Code";
        "Availability Date" := 0D;
        Type := Type::Inventory;
        "Remaining Quantity (Base)" := ItemLedgEntry."Remaining Quantity";

        "Reserved Quantity (Base)" := CalcReservedQuantity(ItemLedgEntry);

        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferInventoryQty(Rec, ItemLedgEntry);
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit PurchAvailabilityMgt', '25.0')]
    procedure TransferFromPurchase(PurchLine: Record Microsoft.Purchases.Document."Purchase Line")
    var
        PurchAvailabilityMgt: Codeunit Microsoft.Purchases.Document."Purch. Availability Mgt.";
    begin
        PurchAvailabilityMgt.TransferFromPurchase(Rec, PurchLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit PurchAvailabilityMgt', '25.0')]
    procedure TransferFromPurchReturn(PurchLine: Record Microsoft.Purchases.Document."Purchase Line")
    var
        PurchAvailabilityMgt: Codeunit Microsoft.Purchases.Document."Purch. Availability Mgt.";
    begin
        PurchAvailabilityMgt.TransferFromPurchReturn(Rec, PurchLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ProdOrderAvailabilityMgt', '25.0')]
    procedure TransferFromProdOrder(ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    var
        ProdOrderAvailabilityMgt: Codeunit Microsoft.Manufacturing.Document."Prod. Order Availability Mgt.";
    begin
        ProdOrderAvailabilityMgt.TransferFromProdOrder(Rec, ProdOrderLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit TransferAvailabilityMgt', '25.0')]
    procedure TransferFromInboundTransOrder(TransLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    var
        TransferAvailabilityMgt: Codeunit Microsoft.Inventory.Transfer."Transfer Availability Mgt.";
    begin
        TransferAvailabilityMgt.TransferFromInboundTransOrder(Rec, TransLine);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ReqLineAvailabilityMgt', '25.0')]
    procedure TransferFromReqLine(ReqLine: Record Microsoft.Inventory.Requisition."Requisition Line"; AtLocation: Code[10]; AtDate: Date; DeltaQtyBase: Decimal; RecID: RecordID)
    var
        ReqLineAvailabilityMgt: Codeunit Microsoft.Inventory.Requisition."Req. Line Availability Mgt.";
    begin
        ReqLineAvailabilityMgt.TransferFromReqLine(Rec, ReqLine, AtLocation, AtDate, DeltaQtyBase, RecID);
    end;
#endif

    procedure TransferFromForecast(ProdForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; UnconsumedQtyBase: Decimal; ForecastOnLocation: Boolean)
    begin
        TransferFromForecast(ProdForecastEntry, UnconsumedQtyBase, ForecastOnLocation, false);
    end;

    procedure TransferFromForecast(ProdForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry"; UnconsumedQtyBase: Decimal; ForecastOnLocation: Boolean; ForecastOnVariant: Boolean)
    var
        RecRef: RecordRef;
    begin
        Init();
        RecRef.GetTable(ProdForecastEntry);
        "Source Line ID" := RecRef.RecordId;
        "Item No." := ProdForecastEntry."Item No.";
        "Variant Code" := '';
        if ForecastOnLocation then
            "Location Code" := ProdForecastEntry."Location Code"
        else
            "Location Code" := '';
        if ForecastOnVariant then
            "Variant Code" := ProdForecastEntry."Variant Code"
        else
            "Variant Code" := '';
        "Availability Date" := ProdForecastEntry."Forecast Date";
        Type := Type::Forecast;
        if ProdForecastEntry."Component Forecast" then
            "Forecast Type" := "Forecast Type"::Component
        else
            "Forecast Type" := "Forecast Type"::Sales;
        "Remaining Quantity (Base)" := -UnconsumedQtyBase;
        "Reserved Quantity (Base)" := 0;
        "Orig. Quantity (Base)" := -ProdForecastEntry."Forecast Quantity (Base)";
        Positive := not ("Remaining Quantity (Base)" < 0);

        OnAfterTransferFromForecast(Rec, ProdForecastEntry);
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit SalesAvailabilityMgt', '25.0')]
    procedure TransferFromSalesBlanketOrder(SalesLine: Record Microsoft.Sales.Document."Sales Line"; UnconsumedQtyBase: Decimal)
    var
        SalesAvailabilityMgt: Codeunit Microsoft.Sales.Document."Sales Availability Mgt.";
    begin
        SalesAvailabilityMgt.TransferFromSalesBlanketOrder(Rec, SalesLine, UnconsumedQtyBase);
    end;
#endif

    procedure PlanRevertEntry(InvtEventBuf: Record "Inventory Event Buffer"; ParentActionMessage: Enum "Action Message Type")
    begin
        Rec := InvtEventBuf;
        Type := Type::"Plan Revert";
        "Remaining Quantity (Base)" := -"Remaining Quantity (Base)";
        "Reserved Quantity (Base)" := 0;
        Positive := not ("Remaining Quantity (Base)" < 0);
        "Action Message" := ParentActionMessage;
        "Attached to Line No." := InvtEventBuf."Entry No.";
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit AssemblyAvailabilityMgt', '25.0')]
    procedure TransferFromAsmOrder(AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    var
        AssemblyAvailabilityMgt: Codeunit Microsoft.Assembly.Document."Assembly Availability Mgt.";
    begin
        AssemblyAvailabilityMgt.TransferFromAsmOrder(Rec, AssemblyHeader);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit AssemblyAvailabilityMgt', '25.0')]
    procedure TransferFromAsmOrderLine(AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    var
        AssemblyAvailabilityMgt: Codeunit Microsoft.Assembly.Document."Assembly Availability Mgt.";
    begin
        AssemblyAvailabilityMgt.TransferFromAsmOrderLine(Rec, AssemblyLine);
    end;
#endif

    procedure CalcReservedQuantity(ItemLedgEntry: Record "Item Ledger Entry"): Decimal
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetRange("Source ID", '');
        ReservEntry.SetRange("Source Type", DATABASE::"Item Ledger Entry");
        ReservEntry.SetRange("Source Subtype", 0);
        ReservEntry.SetRange("Item No.", ItemLedgEntry."Item No.");
        ReservEntry.SetRange("Location Code", ItemLedgEntry."Location Code");
        ReservEntry.SetRange("Variant Code", ItemLedgEntry."Variant Code");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.CalcSums("Quantity (Base)");
        exit(ReservEntry."Quantity (Base)");
    end;

#if not CLEAN25
    internal procedure RunOnAfterTransferFromSales(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        OnAfterTransferFromSales(InventoryEventBuffer, SalesLine);
    end;

    [Obsolete('Moved to codeunit SalesAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSales(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromSalesReturn(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        OnAfterTransferFromSalesReturn(InventoryEventBuffer, SalesLine);
    end;

    [Obsolete('Moved to codeunit SalesAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSalesReturn(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromProdComp(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnAfterTransferFromProdComp(InventoryEventBuffer, ProdOrderComponent);
    end;

    [Obsolete('Moved to codeunit ProdOrderAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdComp(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromJobNeed(var InventoryEventBuffer: Record "Inventory Event Buffer"; JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    begin
        OnAfterTransferFromJobNeed(InventoryEventBuffer, JobPlanningLine);
    end;

    [Obsolete('Moved to codeunit JobPlanningAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromJobNeed(var InventoryEventBuffer: Record "Inventory Event Buffer"; JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromServiceNeed(var InventoryEventBuffer: Record "Inventory Event Buffer"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnAfterTransferFromServiceNeed(InventoryEventBuffer, ServiceLine);
    end;

    [Obsolete('Replaced by event in codeunit ServAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromServiceNeed(var InventoryEventBuffer: Record "Inventory Event Buffer"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromOutboundTransfer(var InventoryEventBuffer: Record "Inventory Event Buffer"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
        OnAfterTransferFromOutboundTransfer(InventoryEventBuffer, TransferLine);
    end;

    [Obsolete('Replaced by event in codeunit TransferAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromOutboundTransfer(var InventoryEventBuffer: Record "Inventory Event Buffer"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromPlanProdComp(var InventoryEventBuffer: Record "Inventory Event Buffer"; PlanningComponent: Record Microsoft.Inventory.Planning."Planning Component"; RequisitionLine: Record Microsoft.Inventory.Requisition."Requisition Line")
    begin
        OnAfterTransferFromPlanProdComp(InventoryEventBuffer, PlanningComponent, RequisitionLine);
    end;

    [Obsolete('Replaced by event in codeunit ReqLineAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPlanProdComp(var InventoryEventBuffer: Record "Inventory Event Buffer"; PlanningComponent: Record Microsoft.Inventory.Planning."Planning Component"; RequisitionLine: Record Microsoft.Inventory.Requisition."Requisition Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromReqLineTransDemand(var InventoryEventBuffer: Record "Inventory Event Buffer"; RequisitionLine: Record Microsoft.Inventory.Requisition."Requisition Line")
    begin
        OnAfterTransferFromReqLineTransDemand(InventoryEventBuffer, RequisitionLine);
    end;

    [Obsolete('Replaced by event in codeunit ReqLineAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromReqLineTransDemand(var InventoryEventBuffer: Record "Inventory Event Buffer"; RequisitionLine: Record Microsoft.Inventory.Requisition."Requisition Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferInventoryQty(var InventoryEventBuffer: Record "Inventory Event Buffer"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterTransferFromPurchase(var InventoryEventBuffer: Record "Inventory Event Buffer"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        OnAfterTransferFromPurchase(InventoryEventBuffer, PurchaseLine);
    end;

    [Obsolete('Replaced by event in codeunit PurchAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPurchase(var InventoryEventBuffer: Record "Inventory Event Buffer"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromPurchReturn(var InventoryEventBuffer: Record "Inventory Event Buffer"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
        OnAfterTransferFromPurchReturn(InventoryEventBuffer, PurchaseLine);
    end;

    [Obsolete('Replaced by event in codeunit PurchAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPurchReturn(var InventoryEventBuffer: Record "Inventory Event Buffer"; PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromProdOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        OnAfterTransferFromProdOrder(InventoryEventBuffer, ProdOrderLine);
    end;

    [Obsolete('Replaced by event in codeunit ProdOrderAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromInboundTransOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
        OnAfterTransferFromInboundTransOrder(InventoryEventBuffer, TransferLine);
    end;

    [Obsolete('Replaced by event in codeunit TransferAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromInboundTransOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; TransferLine: Record Microsoft.Inventory.Transfer."Transfer Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromReqLine(var InventoryEventBuffer: Record "Inventory Event Buffer"; RequisitionLine: Record Microsoft.Inventory.Requisition."Requisition Line")
    begin
        OnAfterTransferFromReqLine(InventoryEventBuffer, RequisitionLine);
    end;

    [Obsolete('Replaced by event in codeunit ReqLineAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromReqLine(var InventoryEventBuffer: Record "Inventory Event Buffer"; RequisitionLine: Record Microsoft.Inventory.Requisition."Requisition Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromForecast(var InventoryEventBuffer: Record "Inventory Event Buffer"; ProdForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterTransferFromSalesBlanketOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
        OnAfterTransferFromSalesBlanketOrder(InventoryEventBuffer, SalesLine);
    end;

    [Obsolete('Replaced by event in codeunit SalesAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromSalesBlanketOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; SalesLine: Record Microsoft.Sales.Document."Sales Line")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromAsmOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
        OnAfterTransferFromAsmOrder(InventoryEventBuffer, AssemblyHeader);
    end;

    [Obsolete('Replaced by event in codeunit AssemblyAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmOrder(var InventoryEventBuffer: Record "Inventory Event Buffer"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferFromAsmOrderLine(var InventoryEventBuffer: Record "Inventory Event Buffer"; AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
        OnAfterTransferFromAsmOrderLine(InventoryEventBuffer, AssemblyLine);
    end;

    [Obsolete('Replaced by event in codeunit AssemblyAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmOrderLine(var InventoryEventBuffer: Record "Inventory Event Buffer"; AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
    end;
#endif
}

