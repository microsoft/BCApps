// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.CrossDock;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Ledger;

codeunit 5996 "Prod. Order Warehouse Mgt."
{
    var
        Bin: Record Bin;
        Location: Record Location;
        WhseManagement: Codeunit "Whse. Management";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        WMSManagement: Codeunit "WMS Management";

        LocationMustBeBinMandatoryErr: Label 'Location %1 must be set up with Bin Mandatory if the Work Center %2 uses it.', Comment = '%1 - location code,  %2 = Object No.';
        CannotPostConsumptionErr: Label 'You cannot post consumption for order no. %1 because a quantity of %2 remains to be picked.', Comment = '%1 - order number, %2 - quantity';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocLine', '', false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Prod. Order Component" then begin
            ProdOrderComponent.Reset();
            ProdOrderComponent.SetRange(Status, SourceSubType);
            ProdOrderComponent.SetRange("Prod. Order No.", SourceNo);
            ProdOrderComponent.SetRange("Prod. Order Line No.", SourceLineNo);
            ProdOrderComponent.SetRange("Line No.", SourceSubLineNo);
            IsHandled := false;
            OnBeforeShowProdOrderComponents(ProdOrderComponent, SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo, IsHandled);
            if not IsHandled then
                case SourceSubType of
                    3: // Released
                        PAGE.RunModal(PAGE::"Prod. Order Comp. Line List", ProdOrderComponent);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocCard', '', false, false)]
    local procedure OnShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        if SourceType in [Database::"Prod. Order Line", Database::"Prod. Order Component"] then
            if ProductionOrder.Get(SourceSubType, SourceNo) then begin
                ProductionOrder.SetRange(Status, SourceSubType);
                PAGE.RunModal(PAGE::"Released Production Order", ProductionOrder);
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowWhseActivityDocLine', '', false, false)]
    local procedure OnAfterShowWhseActivityDocLine(WhseActivityDocType: Enum "Warehouse Activity Document Type"; WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    begin
        if WhseActivityDocType = WhseActivityDocType::Production then
            ShowProdOrderLine(WhseDocNo, WhseDocLineNo);
    end;

    procedure ShowProdOrderLine(WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", WhseDocNo);
        ProdOrderLine.SetRange("Line No.", WhseDocLineNo);
        PAGE.RunModal(PAGE::"Prod. Order Line List", ProdOrderLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnCheckIfBinIsEligible', '', false, false)]
    local procedure OnCheckIfBinIsEligible(ItemJournalLine: Record "Item Journal Line"; var BinIsEligible: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if ItemJournalLine."Order Type" = ItemJournalLine."Order Type"::Production then begin
            if (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Output) then
                if ProdOrderLine.Get(ProdOrderLine.Status::Released, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.") then
                    BinIsEligible := (ItemJournalLine."Location Code" = ProdOrderLine."Location Code") and (ItemJournalLine."Bin Code" = ProdOrderLine."Bin Code");
            if (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Consumption) then
                if ProdOrderComponent.Get(ProdOrderComponent.Status::Released, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.", ItemJournalLine."Prod. Order Comp. Line No.") then
                    BinIsEligible := (ItemJournalLine."Location Code" = ProdOrderComponent."Location Code") and (ItemJournalLine."Bin Code" = ProdOrderComponent."Bin Code");
        end;
    end;

    procedure CreateWhseJnlLineFromConsumptionJournal(ItemJournalLine: Record "Item Journal Line"; var WarehouseJournalLine: Record "Warehouse Journal Line"): Boolean
    begin
        if ItemJournalLine.Adjustment or
           (ItemJournalLine."Value Entry Type" in [ItemJournalLine."Value Entry Type"::Rounding, ItemJournalLine."Value Entry Type"::Revaluation])
        then
            exit(false);

        ItemJournalLine.TestField("Order Type", ItemJournalLine."Order Type"::Production);
        GetLocation(ItemJournalLine."Location Code");
        ItemJournalLine.TestField("Unit of Measure Code");
        WMSManagement.InitWhseJnlLine(ItemJournalLine, WarehouseJournalLine, ItemJournalLine."Quantity (Base)");
        SetZoneAndBinsForConsumption(ItemJournalLine, WarehouseJournalLine);
        WarehouseJournalLine.SetSource(DATABASE::"Item Journal Line", 4, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.", ItemJournalLine."Prod. Order Comp. Line No.");
        // Consumption Journal
        WarehouseJournalLine."Source Document" := WhseManagement.GetWhseJnlSourceDocument(WarehouseJournalLine."Source Type", WarehouseJournalLine."Source Subtype");
        WarehouseJournalLine.SetWhseDocument(WarehouseJournalLine."Whse. Document Type"::Production, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.");
        WarehouseJournalLine."Reference Document" := WarehouseJournalLine."Reference Document"::"Prod.";
        WarehouseJournalLine."Reference No." := ItemJournalLine."Order No.";
        WMSManagement.TransferWhseItemTracking(WarehouseJournalLine, ItemJournalLine);
        OnAfterCreateWhseJnlLineFromConsumptionJournal(WarehouseJournalLine, ItemJournalLine);
    end;

    procedure CreateWhseJnlLineFromOutputJournal(ItemJournalLine: Record "Item Journal Line"; var WarehouseJournalLine: Record "Warehouse Journal Line"): Boolean
    begin
        OnBeforeCreateWhseJnlLineFromOutputJournal(ItemJournalLine);
        if ItemJournalLine.Adjustment or
           (ItemJournalLine."Value Entry Type" in [ItemJournalLine."Value Entry Type"::Rounding, ItemJournalLine."Value Entry Type"::Revaluation])
        then
            exit(false);

        ItemJournalLine.TestField("Order Type", ItemJournalLine."Order Type"::Production);
        GetLocation(ItemJournalLine."Location Code");
        ItemJournalLine.TestField("Unit of Measure Code");
        WMSManagement.InitWhseJnlLine(ItemJournalLine, WarehouseJournalLine, ItemJournalLine."Output Quantity (Base)");
        OnCreateWhseJnlLineFromOutputJournalOnAfterInitWhseJnlLine(WarehouseJournalLine, ItemJournalLine);
        SetZoneAndBinsForOutput(ItemJournalLine, WarehouseJournalLine);
        WarehouseJournalLine.SetSource(DATABASE::"Item Journal Line", 5, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.", 0);
        // Output Journal
        WarehouseJournalLine."Source Document" := WhseManagement.GetWhseJnlSourceDocument(WarehouseJournalLine."Source Type", WarehouseJournalLine."Source Subtype");
        WarehouseJournalLine.SetWhseDocument(WarehouseJournalLine."Whse. Document Type"::Production, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.");
        WarehouseJournalLine."Reference Document" := WarehouseJournalLine."Reference Document"::"Prod.";
        WarehouseJournalLine."Reference No." := ItemJournalLine."Order No.";
        WMSManagement.TransferWhseItemTracking(WarehouseJournalLine, ItemJournalLine);
        OnAfterCreateWhseJnlLineFromOutputJournal(WarehouseJournalLine, ItemJournalLine);
    end;

    local procedure SetZoneAndBinsForConsumption(ItemJournalLine: Record "Item Journal Line"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetZoneAndBinsForConsumption(ItemJournalLine, ProdOrderComponent, WarehouseJournalLine, Location, IsHandled);
        if IsHandled then
            exit;

        if GetProdOrderCompLine(
                 ProdOrderComponent, ProdOrderComponent.Status::Released, ItemJournalLine."Order No.", ItemJournalLine."Order Line No.", ItemJournalLine."Prod. Order Comp. Line No.")
            then
            if ItemJournalLine.Quantity > 0 then begin
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Negative Adjmt.";
                WarehouseJournalLine."From Bin Code" := ItemJournalLine."Bin Code";
                if Location."Bin Mandatory" and (Location."Prod. Consump. Whse. Handling" = Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)") then begin
                    OnSetZoneAndBinsForConsumptionOnBeforeCheckQtyPicked(ItemJournalLine, ProdOrderComponent);
                    if (ProdOrderComponent."Planning Level Code" = 0) and
                       FlushingMethodRequiresPick(ProdOrderComponent."Flushing Method")
                    then
                        CheckProdOrderCompLineQtyPickedBase(ProdOrderComponent, ItemJournalLine);
                    GetBin(ItemJournalLine."Location Code", WarehouseJournalLine."From Bin Code");
                    WarehouseJournalLine."From Zone Code" := Bin."Zone Code";
                    WarehouseJournalLine."From Bin Type Code" := Bin."Bin Type Code";
                end;
                if WarehouseJournalLine."From Zone Code" = '' then
                    WarehouseJournalLine."From Zone Code" := GetZoneCode(ItemJournalLine."Location Code", WarehouseJournalLine."From Bin Code");
                if WarehouseJournalLine."From Bin Type Code" = '' then
                    WarehouseJournalLine."From Bin Type Code" := GetBinTypeCode(ItemJournalLine."Location Code", WarehouseJournalLine."From Bin Code");
            end else begin
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Positive Adjmt.";
                WarehouseJournalLine."To Bin Code" := ItemJournalLine."Bin Code";
                if Location."Directed Put-away and Pick" then begin
                    GetBin(ItemJournalLine."Location Code", WarehouseJournalLine."To Bin Code");
                    WarehouseJournalLine."To Zone Code" := Bin."Zone Code";
                end;
                if WarehouseJournalLine."To Zone Code" = '' then
                    WarehouseJournalLine."To Zone Code" := GetZoneCode(ItemJournalLine."Location Code", WarehouseJournalLine."To Bin Code");
            end
        else
            if ItemJournalLine.Quantity > 0 then begin
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Negative Adjmt.";
                WarehouseJournalLine."From Bin Code" := ItemJournalLine."Bin Code";
                if Location."Directed Put-away and Pick" then begin
                    GetBin(ItemJournalLine."Location Code", WarehouseJournalLine."From Bin Code");
                    WarehouseJournalLine."From Zone Code" := Bin."Zone Code";
                    WarehouseJournalLine."From Bin Type Code" := Bin."Bin Type Code";
                end;
                if WarehouseJournalLine."From Zone Code" = '' then
                    WarehouseJournalLine."From Zone Code" := GetZoneCode(ItemJournalLine."Location Code", WarehouseJournalLine."From Bin Code");
                if WarehouseJournalLine."From Bin Type Code" = '' then
                    WarehouseJournalLine."From Bin Type Code" := GetBinTypeCode(ItemJournalLine."Location Code", WarehouseJournalLine."From Bin Code");
            end else begin
                WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Positive Adjmt.";
                WarehouseJournalLine."To Bin Code" := ItemJournalLine."Bin Code";
                if Location."Directed Put-away and Pick" then begin
                    GetBin(ItemJournalLine."Location Code", WarehouseJournalLine."To Bin Code");
                    WarehouseJournalLine."To Zone Code" := Bin."Zone Code";
                end;
                if WarehouseJournalLine."To Zone Code" = '' then
                    WarehouseJournalLine."To Zone Code" := GetZoneCode(ItemJournalLine."Location Code", WarehouseJournalLine."To Bin Code");
            end;
    end;

    local procedure SetZoneAndBinsForOutput(ItemJournalLine: Record "Item Journal Line"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        if ItemJournalLine."Output Quantity" >= 0 then begin
            WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Positive Adjmt.";
            WarehouseJournalLine."To Bin Code" := ItemJournalLine."Bin Code";
            if Location."Directed Put-away and Pick" then begin
                GetBin(ItemJournalLine."Location Code", WarehouseJournalLine."To Bin Code");
                WarehouseJournalLine."To Zone Code" := Bin."Zone Code";
            end;
            if WarehouseJournalLine."To Zone Code" = '' then
                WarehouseJournalLine."To Zone Code" := GetZoneCode(ItemJournalLine."Location Code", WarehouseJournalLine."To Bin Code");
        end else begin
            WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Negative Adjmt.";
            WarehouseJournalLine."From Bin Code" := ItemJournalLine."Bin Code";
            if Location."Directed Put-away and Pick" then begin
                GetBin(ItemJournalLine."Location Code", WarehouseJournalLine."From Bin Code");
                WarehouseJournalLine."From Zone Code" := Bin."Zone Code";
            end;
            if WarehouseJournalLine."From Zone Code" = '' then
                WarehouseJournalLine."From Zone Code" := GetZoneCode(ItemJournalLine."Location Code", WarehouseJournalLine."From Bin Code");
        end;
    end;

    procedure GetPlanningRtngLastOperationFromBinCode(WkshTemplateName: Code[10]; WkshBatchName: Code[10]; WkshLineNo: Integer; LocationCode: Code[10]): Code[20]
    var
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        PlanningRoutingLine.SetRange(PlanningRoutingLine."Worksheet Template Name", WkshTemplateName);
        PlanningRoutingLine.SetRange(PlanningRoutingLine."Worksheet Batch Name", WkshBatchName);
        PlanningRoutingLine.SetRange(PlanningRoutingLine."Worksheet Line No.", WkshLineNo);
        if PlanningRoutingLine.FindLast() then
            exit(GetProdCenterBinCode(PlanningRoutingLine.Type, PlanningRoutingLine."No.", LocationCode, false, Enum::"Flushing Method Routing"::Manual));
    end;

    procedure GetProdCenterLocationCode(Type: Enum "Capacity Type"; No: Code[20]): Code[10]
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        case Type of
            Type::"Work Center":
                begin
                    WorkCenter.Get(No);
                    exit(WorkCenter."Location Code");
                end;
            Type::"Machine Center":
                begin
                    MachineCenter.Get(No);
                    exit(MachineCenter."Location Code");
                end;
        end;
    end;

    procedure GetProdCenterBinCode(Type: Enum "Capacity Type"; No: Code[20]; LocationCode: Code[10]; UseFlushingMethod: Boolean; FlushingMethod: Enum "Flushing Method"): Code[20]
    begin
        case Type of
            Type::"Work Center":
                exit(GetWorkCenterBinCode(No, LocationCode, UseFlushingMethod, FlushingMethod));
            Type::"Machine Center":
                exit(GetMachineCenterBinCode(No, LocationCode, UseFlushingMethod, FlushingMethod));
        end;
    end;

    local procedure GetMachineCenterBinCode(MachineCenterNo: Code[20]; LocationCode: Code[10]; UseFlushingMethod: Boolean; FlushingMethod: Enum "Flushing Method") Result: Code[20]
    var
        MachineCenter: Record "Machine Center";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetMachineCenterBinCode(MachineCenterNo, LocationCode, UseFlushingMethod, FlushingMethod, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if MachineCenter.Get(MachineCenterNo) then begin
            if MachineCenter."Location Code" = LocationCode then
                exit(MachineCenter.GetBinCodeForFlushingMethod(UseFlushingMethod, FlushingMethod));

            exit(GetWorkCenterBinCode(MachineCenter."Work Center No.", LocationCode, UseFlushingMethod, FlushingMethod));
        end;
    end;

    local procedure GetWorkCenterBinCode(WorkCenterNo: Code[20]; LocationCode: Code[10]; UseFlushingMethod: Boolean; FlushingMethod: Enum "Flushing Method"): Code[20]
    var
        WorkCenter: Record "Work Center";
    begin
        if WorkCenter.Get(WorkCenterNo) then
            if WorkCenter."Location Code" = LocationCode then
                exit(WorkCenter.GetBinCodeForFlushingMethod(UseFlushingMethod, FlushingMethod));
    end;

    procedure GetDefaultBin(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var BinCode: Code[20]) Result: Boolean
    begin
        exit(WMSManagement.GetDefaultBin(ItemNo, VariantCode, LocationCode, BinCode));
    end;

    local procedure GetProdOrderCompLine(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; ProdOrdCompLineNo: Integer): Boolean
    begin
        if (ProdOrderNo = '') or
           (ProdOrderLineNo = 0) or
           (ProdOrdCompLineNo = 0)
        then
            exit(false);
        if (ProdOrderComponent.Status <> Status) or
            (ProdOrderComponent."Prod. Order No." <> ProdOrderNo) or
            (ProdOrderComponent."Prod. Order Line No." <> ProdOrderLineNo) or
            (ProdOrderComponent."Line No." <> ProdOrdCompLineNo)
        then begin
            if ProdOrderComponent.Get(Status, ProdOrderNo, ProdOrderLineNo, ProdOrdCompLineNo) then
                exit(true);
            exit(false);
        end;
        exit(true);
    end;

    local procedure CheckProdOrderCompLineQtyPickedBase(var ProdOrderComponent: Record "Prod. Order Component"; ItemJournalLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderComponentQtyPickedBase(ProdOrderComponent, ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if ProdOrderComponent."Qty. Picked (Base)" < ItemJournalLine."Quantity (Base)" then
            ProdOrderComponent.FieldError("Qty. Picked (Base)");
    end;

    procedure GetLastOperationFromBinCode(RoutingNo: Code[20]; RoutingVersionCode: Code[20]; LocationCode: Code[10]; UseFlushingMethod: Boolean; FlushingMethod: Enum "Flushing Method"): Code[20]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Version Code", RoutingVersionCode);
        if RoutingLine.FindLast() then
            exit(GetProdCenterBinCode(RoutingLine.Type, RoutingLine."No.", LocationCode, UseFlushingMethod, FlushingMethod));
    end;

    procedure GetLastOperationLocationCode(RoutingNo: Code[20]; RoutingVersionCode: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Version Code", RoutingVersionCode);
        if RoutingLine.FindLast() then
            exit(GetProdCenterLocationCode(RoutingLine.Type, RoutingLine."No."));
    end;

    procedure GetProdRoutingLastOperationFromBinCode(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; RoutingRefNo: Integer; RoutingNo: Code[20]; LocationCode: Code[10]): Code[20]
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderStatus);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", RoutingRefNo);
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        if ProdOrderRoutingLine.FindLast() then
            exit(
                GetProdCenterBinCode(
                    ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.", LocationCode, false, Enum::"Flushing Method"::Manual));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (Bin."Location Code" <> LocationCode) or
           (Bin.Code <> BinCode)
        then
            Bin.Get(LocationCode, BinCode);
        Bin.TestField(Code);

        GetLocation(LocationCode);
        if Location."Directed Put-away and Pick" then
            Bin.TestField("Zone Code");
    end;

    local procedure GetZoneCode(LocationCode: Code[10]; BinCode: Code[20]): Code[10]
    var
        Bin2: Record Bin;
    begin
        if Bin2.Get(LocationCode, BinCode) then
            exit(Bin2."Zone Code");
    end;

    local procedure GetBinTypeCode(LocationCode: Code[10]; BinCode: Code[20]): Code[10]
    var
        Bin2: Record Bin;
    begin
        if Bin2.Get(LocationCode, BinCode) then
            exit(Bin2."Bin Type Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowProdOrderComponents(var ProdOrderComponent: Record "Prod. Order Component"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLineFromConsumptionJournal(var WarehouseJournalLine: Record "Warehouse Journal Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetZoneAndBinsForConsumption(ItemJournalLine: Record "Item Journal Line"; var ProdOrderComponent: Record "Prod. Order Component"; var WarehouseJournalLine: Record "Warehouse Journal Line"; Location: Record Location; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseJnlLineFromOutputJournal(ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetZoneAndBinsForConsumptionOnBeforeCheckQtyPicked(ItemJournalLine: Record "Item Journal Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseJnlLineFromOutputJournalOnAfterInitWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderComponentQtyPickedBase(var ProdOrderComponent: Record "Prod. Order Component"; ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseJnlLineFromOutputJournal(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    procedure ProdComponentVerifyChange(var NewProdOrderComponent: Record "Prod. Order Component"; var OldProdOrderComponent: Record "Prod. Order Component")
    var
        NewRecordRef: RecordRef;
        OldRecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProdComponentVerifyChange(NewProdOrderComponent, OldProdOrderComponent, IsHandled);
        if IsHandled then
            exit;

        if NewProdOrderComponent."Line No." = 0 then
            exit;

        if not WhseValidateSourceLine.WhseLinesExist(
             Database::"Prod. Order Component", OldProdOrderComponent.Status.AsInteger(), OldProdOrderComponent."Prod. Order No.",
             OldProdOrderComponent."Prod. Order Line No.", OldProdOrderComponent."Line No.", OldProdOrderComponent.Quantity)
        then begin
            NewRecordRef.GetTable(NewProdOrderComponent);
            OldRecordRef.GetTable(OldProdOrderComponent);
            if WhseValidateSourceLine.FieldValueIsChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(Status)) then begin
                if not WhseValidateSourceLine.WhseWorkSheetLinesExist(
                    Database::"Prod. Order Component", OldProdOrderComponent.Status.AsInteger(), OldProdOrderComponent."Prod. Order No.",
                    OldProdOrderComponent."Prod. Order Line No.", OldProdOrderComponent."Line No.", OldProdOrderComponent.Quantity)
                then
                    exit;
            end else
                exit;
        end;

        NewRecordRef.GetTable(NewProdOrderComponent);
        OldRecordRef.GetTable(OldProdOrderComponent);
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(NewProdOrderComponent.Status));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(NewProdOrderComponent."Prod. Order No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(NewProdOrderComponent."Prod. Order Line No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(NewProdOrderComponent."Line No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(NewProdOrderComponent."Item No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(NewProdOrderComponent."Variant Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(NewProdOrderComponent."Location Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(NewProdOrderComponent."Unit of Measure Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(NewProdOrderComponent."Due Date"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(NewProdOrderComponent.Quantity));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(NewProdOrderComponent."Quantity per"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderComponent.FieldNo(NewProdOrderComponent."Expected Quantity"));

        OnAfterProdComponentVerifyChange(NewRecordRef, OldRecordRef);
    end;

    procedure ProdComponentDelete(var ProdOrderComponent: Record "Prod. Order Component")
    begin
        if WhseValidateSourceLine.WhseLinesExist(
             Database::"Prod. Order Component",
             ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.",
             ProdOrderComponent."Line No.", ProdOrderComponent.Quantity)
        then
            WhseValidateSourceLine.RaiseCannotbeDeletedErr(ProdOrderComponent.TableCaption());

        if WhseValidateSourceLine.WhseWorkSheetLinesExist(
            Database::"Prod. Order Component",
            ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.",
            ProdOrderComponent."Line No.", ProdOrderComponent.Quantity)
        then
            WhseValidateSourceLine.RaiseCannotbeDeletedErr(ProdOrderComponent.TableCaption());

        OnAfterProdComponentDelete(ProdOrderComponent);
    end;

    procedure ProdOrderLineVerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line")
    var
        NewRecordRef: RecordRef;
        OldRecordRef: RecordRef;
    begin
        if not WhseValidateSourceLine.WhseLinesExist(
             Database::"Prod. Order Line", OldProdOrderLine.Status.AsInteger(), OldProdOrderLine."Prod. Order No.",
             OldProdOrderLine."Line No.", 0, OldProdOrderLine.Quantity)
        then
            exit;

        NewRecordRef.GetTable(NewProdOrderLine);
        OldRecordRef.GetTable(OldProdOrderLine);
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderLine.FieldNo(NewProdOrderLine.Status));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderLine.FieldNo(NewProdOrderLine."Prod. Order No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderLine.FieldNo(NewProdOrderLine."Line No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderLine.FieldNo(NewProdOrderLine."Item No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderLine.FieldNo(NewProdOrderLine."Variant Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderLine.FieldNo(NewProdOrderLine."Location Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderLine.FieldNo(NewProdOrderLine."Unit of Measure Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderLine.FieldNo(NewProdOrderLine."Due Date"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewProdOrderLine.FieldNo(NewProdOrderLine.Quantity));

        OnAfterProdOrderLineVerifyChange(NewProdOrderLine, OldProdOrderLine, NewRecordRef, OldRecordRef);
    end;

    procedure ProdOrderLineDelete(var ProdOrderLine: Record "Prod. Order Line")
    begin
        if WhseValidateSourceLine.WhseLinesExist(
                 Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", 0, ProdOrderLine.Quantity)
            then
            WhseValidateSourceLine.RaiseCannotbeDeletedErr(ProdOrderLine.TableCaption());

        OnAfterProdOrderLineDelete(ProdOrderLine);
    end;

    procedure ValidateWarehousePutAwayLocation(ProdOrderLine: Record "Prod. Order Line")
    var
        PutAwayProdOrderLine: Record "Prod. Order Line";
        LocationCode: Code[10];
    begin
        if Location.RequireWhsePutAwayForProdOutput(ProdOrderLine."Location Code") then
            LocationCode := ProdOrderLine."Location Code";

        PutAwayProdOrderLine.SetLoadFields(Status, "Prod. Order No.", "Location Code", "Line No.");
        PutAwayProdOrderLine.SetRange(Status, ProdOrderLine.Status);
        PutAwayProdOrderLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");

        if LocationCode <> '' then begin
            CompareProdOrderLinesForWarehouse(PutAwayProdOrderLine, ProdOrderLine);
            exit;
        end;

        if PutAwayProdOrderLine.FindSet() then
            repeat
                if Location.RequireWhsePutAwayForProdOutput(PutAwayProdOrderLine."Location Code") then begin
                    LocationCode := PutAwayProdOrderLine."Location Code";

                    if LocationCode <> ProdOrderLine."Location Code" then
                        ProdOrderLine.TestField("Location Code", LocationCode);
                end;
            until PutAwayProdOrderLine.Next() = 0;
    end;

    local procedure CompareProdOrderLinesForWarehouse(var PutAwayProdOrderLine: Record "Prod. Order Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        PutAwayProdOrderLine.SetFilter("Line No.", '<>%1', ProdOrderLine."Line No.");
        PutAwayProdOrderLine.SetFilter("Location Code", '<>%1', ProdOrderLine."Location Code");
        if PutAwayProdOrderLine.FindFirst() then
            PutAwayProdOrderLine.TestField("Location Code", ProdOrderLine."Location Code");
    end;

    procedure CompareProdOrderWithProdOrderLinesForLocation(ProductionOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line")
    begin
        if ProductionOrder."Location Code" = ProdOrderLine."Location Code" then
            exit;

        if Location.RequireWhsePutAwayForProdOutput(ProductionOrder."Location Code") then
            ProdOrderLine.TestField("Location Code", ProductionOrder."Location Code");

        if Location.RequireWhsePutAwayForProdOutput(ProdOrderLine."Location Code") then
            ProdOrderLine.TestField("Location Code", ProductionOrder."Location Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderLineDelete(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdComponentDelete(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderLineVerifyChange(var NewProdOrderLine: Record "Prod. Order Line"; var OldProdOrderLine: Record "Prod. Order Line"; var NewRecordRef: RecordRef; var OldRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdComponentVerifyChange(var NewRecordRef: RecordRef; var OldRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdComponentVerifyChange(var NewProdOrderComponent: Record "Prod. Order Component"; var OldProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Request", 'OnShowSourceDocumentCard', '', false, false)]
    local procedure OnShowSourceDocumentCard(var WarehouseRequest: Record "Warehouse Request")
    var
        ProductionOrder: Record "Production Order";
    begin
        case WarehouseRequest."Source Document" of
            Enum::"Warehouse Request Source Document"::"Prod. Consumption", Enum::"Warehouse Request Source Document"::"Prod. Output":
                begin
                    ProductionOrder.Get(WarehouseRequest."Source Subtype", WarehouseRequest."Source No.");
                    PAGE.Run(PAGE::"Released Production Order", ProductionOrder);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetSrcDocLineQtyOutstanding', '', false, false)]
    local procedure OnAfterGetSrcDocLineQtyOutstanding(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var QtyBaseOutstanding: Decimal; var QtyOutstanding: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        case SourceType of
            Database::"Prod. Order Component":
                if ProdOrderComp.Get(SourceSubType, SourceNo, SourceLineNo, SourceSubLineNo) then begin
                    QtyOutstanding := ProdOrderComp."Remaining Quantity";
                    QtyBaseOutstanding := ProdOrderComp."Remaining Qty. (Base)";
                end;
            Database::"Prod. Order Line":
                if ProdOrderLine.Get(SourceSubType, SourceNo, SourceLineNo) then begin
                    QtyOutstanding := ProdOrderLine."Remaining Quantity";
                    QtyBaseOutstanding := ProdOrderLine."Remaining Qty. (Base)";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetSourceDocumentType', '', false, false)]
    local procedure WhseManagementGetSourceDocumentType(SourceType: Integer; SourceSubType: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
        case SourceType of
            Database::"Prod. Order Component":
                begin
                    SourceDocument := "Warehouse Journal Source Document"::"Prod. Consumption";
                    IsHandled := true;
                end;
            Database::"Prod. Order Line":
                begin
                    SourceDocument := "Warehouse Journal Source Document"::"Prod. Output";
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetJournalSourceDocument', '', false, false)]
    local procedure WhseManagementGetJournalSourceDocument(SourceType: Integer; SourceSubType: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
        if SourceType = Database::"Prod. Order Component" then begin
            SourceDocument := SourceDocument::"Prod. Consumption";
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnBeforeGetSourceType', '', false, false)]
    local procedure WhseManagementOnBeforeGetSourceType(WhseWorksheetLine: Record "Whse. Worksheet Line"; var SourceType: Integer; var IsHandled: Boolean)
    begin
        if WhseWorksheetLine."Whse. Document Type" = WhseWorksheetLine."Whse. Document Type"::Production then
            if SourceType = 0 then begin
                SourceType := Database::"Prod. Order Component";
                IsHandled := true;
            end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Create Pick", 'OnCheckSourceDocument', '', false, false)]
    local procedure CreatePickOnCheckSourceDocument(var PickWhseWkshLine: Record "Whse. Worksheet Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if PickWhseWkshLine."Source Type" = Database::"Prod. Order Component" then begin
            ProdOrderComponent.SetRange(Status, PickWhseWkshLine."Source Subtype");
            ProdOrderComponent.SetRange("Prod. Order No.", PickWhseWkshLine."Source No.");
            ProdOrderComponent.SetRange("Prod. Order Line No.", PickWhseWkshLine."Source Line No.");
            ProdOrderComponent.SetRange("Line No.", PickWhseWkshLine."Source Subline No.");
            if ProdOrderComponent.IsEmpty() then
                Error(WhseManagement.GetSourceDocumentDoesNotExistErr(), ProdOrderComponent.TableCaption(), ProdOrderComponent.GetFilters());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Cross-Dock Management", 'OnCalcCrossDockToProdOrderComponent', '', false, false)]
    local procedure OnCalcCrossDockToProdOrderComponent(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer; var sender: Codeunit "Whse. Cross-Dock Management")
    begin
        CalcCrossDockToProdOrderComponent(WhseCrossDockOpportunity, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo, sender);
    end;

    local procedure CalcCrossDockToProdOrderComponent(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer; var sender: Codeunit "Whse. Cross-Dock Management")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.SetRange("Variant Code", VariantCode);
        ProdOrderComponent.SetRange("Location Code", LocationCode);
        ProdOrderComponent.SetRange("Due Date", 0D, CrossDockDate);
        ProdOrderComponent.SetRange("Planning Level Code", 0);
        ProdOrderComponent.SetFilter("Remaining Qty. (Base)", '>0');
        if ProdOrderComponent.Find('-') then
            repeat
                ProdOrderComponent.CalcFields("Pick Qty. (Base)");
#if not CLEAN25
                sender.RunOnCalcCrossDockToProdOrderComponentOnBeforeInsertCrossDockLine(ProdOrderComponent);
#endif
                OnCalcCrossDockToProdOrderComponentOnBeforeInsertCrossDockLine(ProdOrderComponent);
                sender.InsertCrossDockOpp(
                    WhseCrossDockOpportunity,
                    Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.",
                    ProdOrderComponent."Line No.", ProdOrderComponent."Prod. Order Line No.",
                    ProdOrderComponent."Remaining Quantity", ProdOrderComponent."Remaining Qty. (Base)",
                    ProdOrderComponent."Pick Qty.", ProdOrderComponent."Pick Qty. (Base)", ProdOrderComponent."Qty. Picked", ProdOrderComponent."Qty. Picked (Base)",
                    ProdOrderComponent."Unit of Measure Code", ProdOrderComponent."Qty. per Unit of Measure", ProdOrderComponent."Due Date",
                    ProdOrderComponent."Item No.", ProdOrderComponent."Variant Code", LineNo);
            until ProdOrderComponent.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToProdOrderComponentOnBeforeInsertCrossDockLine(ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetMachineCenterBinCode(MachineCenterNo: Code[20]; LocationCode: Code[10]; UseFlushingMethod: Boolean; FlushingMethod: Enum "Flushing Method"; var Result: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Integration Management", 'OnCheckBinTypeAndCode', '', false, false)]
    local procedure OnCheckBinTypeAndCode(BinType: Record "Bin Type"; AdditionalIdentifier: Option; SourceTable: Integer; BinCodeFieldCaption: Text)
    begin
        CheckBinTypeAndCode(BinType, AdditionalIdentifier, SourceTable, BinCodeFieldCaption);
    end;

    procedure CheckBinTypeAndCode(BinType: Record "Bin Type"; AdditionalIdentifier: Option; SourceTable: Integer; BinCodeFieldCaption: Text)
    var
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
    begin
        case SourceTable of
            Database::"Production Order",
            Database::"Prod. Order Line":
                BinType.AllowPutawayPickOrQCBinsOnly();
            Database::"Prod. Order Component":
                BinType.AllowPutawayOrQCBinsOnly();
            Database::"Machine Center":
                case BinCodeFieldCaption of
                    MachineCenter.FieldCaption("Open Shop Floor Bin Code"),
                    MachineCenter.FieldCaption("To-Production Bin Code"):
                        BinType.AllowPutawayOrQCBinsOnly();
                    MachineCenter.FieldCaption("From-Production Bin Code"):
                        BinType.AllowPutawayPickOrQCBinsOnly();
                end;
            Database::"Work Center":
                case BinCodeFieldCaption of
                    WorkCenter.FieldCaption("Open Shop Floor Bin Code"),
                    WorkCenter.FieldCaption("To-Production Bin Code"):
                        BinType.AllowPutawayOrQCBinsOnly();
                    WorkCenter.FieldCaption("From-Production Bin Code"):
                        BinType.AllowPutawayPickOrQCBinsOnly();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Integration Management", 'OnAfterIsOpenShopFloorBin', '', false, false)]
    local procedure OnAfterIsOpenShopFloorBin(LocationCode: Code[10]; BinCode: Code[20]; var Result: Boolean)
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        WorkCenter.SetRange("Location Code", LocationCode);
        WorkCenter.SetRange("Open Shop Floor Bin Code", BinCode);
        if not WorkCenter.IsEmpty() then
            Result := true;

        if not Result then begin
            MachineCenter.SetRange("Location Code", LocationCode);
            MachineCenter.SetRange("Open Shop Floor Bin Code", BinCode);
            if not MachineCenter.IsEmpty() then
                Result := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Location, 'OnValidateBinMandatoryOnAfterCheckBins', '', false, false)]
    local procedure OnValidateBinMandatoryOnAfterCheckBins(Location: Record Location)
    begin
        CheckLocationOnBins(Location);
    end;

    internal procedure CheckLocationOnBins(Location: Record Location)
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetRange("Location Code", Location.Code);
        if WorkCenter.FindSet(false) then
            repeat
                if not Location."Bin Mandatory" then
                    Error(LocationMustBeBinMandatoryErr, Location.Code, WorkCenter."No.");
            until WorkCenter.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'CheckWhseDocLineOnCheckSourceDocument', '', false, false)]
    local procedure CheckWhseDocLineOnCheckSourceDocument(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseDocType: Enum "Warehouse Activity Document Type")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case WhseDocType of
            "Warehouse Activity Document Type"::Production:
                begin
                    GetLocation(WarehouseActivityLine."Location Code");
                    if Location."Directed Put-away and Pick" then begin
                        ProdOrderComponent.Get(
                            WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.");
                        CheckBinCodeFromProdOrderCompLine(WarehouseActivityLine, ProdOrderComponent);
                    end;
                end;
        end;
    end;

    local procedure CheckBinCodeFromProdOrderCompLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderComponent: Record "Prod. Order Component")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBinCodeFromProdOrderCompLine(WarehouseActivityLine, ProdOrderComponent, IsHandled);
#if not CLEAN26
        WarehouseActivityLine.RunOnBeforeCheckBinCodeFromProdOrderCompLine(WarehouseActivityLine, ProdOrderComponent, IsHandled);
#endif
        if IsHandled then
            exit;

        WarehouseActivityLine.TestField("Bin Code", ProdOrderComponent."Bin Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinCodeFromProdOrderCompLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderCompLine: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnCheckBinInSourceDoc', '', false, false)]
    local procedure OnCheckBinInSourceDoc(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case WarehouseActivityLine."Source Type" of
            Database::"Prod. Order Component":
                begin
                    ProdOrderComponent.SetLoadFields("Bin Code");
                    ProdOrderComponent.Get(
                        WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.");
                    WarehouseActivityLine.TestField("Bin Code", ProdOrderComponent."Bin Code");
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnShowWhseDoc', '', false, false)]
    local procedure WarehouseActivityLineOnShowWhseDoc(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        ReleasedProductionOrder: Record "Production Order";
    begin
        case WarehouseActivityLine."Whse. Document Type" of
            WarehouseActivityLine."Whse. Document Type"::Production:
                begin
                    ReleasedProductionOrder.SetRange(Status, WarehouseActivityLine."Source Subtype");
                    ReleasedProductionOrder.SetRange("No.", WarehouseActivityLine."Source No.");
                    Page.RunModal(Page::"Released Production Order", ReleasedProductionOrder);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnUpdateRelatedItemTrkgForInvtMovement', '', false, false)]
    local procedure OnUpdateRelatedItemTrkgForInvtMovement(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        case WarehouseActivityLine."Source Type" of
            Database::"Prod. Order Component":
                begin
                    WhseItemTrackingLine.SetRange("Source Type", Database::"Prod. Order Component");
                    WhseItemTrackingLine.SetRange("Source Subtype", WarehouseActivityLine."Source Subtype");
                    WhseItemTrackingLine.SetRange("Source ID", WarehouseActivityLine."Source No.");
                    WhseItemTrackingLine.SetRange("Source Prod. Order Line", WarehouseActivityLine."Source Line No.");
                    WhseItemTrackingLine.SetRange("Source Ref. No.", WarehouseActivityLine."Source Subline No.");
                end;
        end;
    end;

    procedure TransferFromCompLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderCompLine: Record "Prod. Order Component")
    begin
        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::Pick;
        WarehouseActivityLine."Source Type" := Database::"Prod. Order Component";
        WarehouseActivityLine."Source Subtype" := ProdOrderCompLine.Status.AsInteger();
        WarehouseActivityLine."Source No." := ProdOrderCompLine."Prod. Order No.";
        WarehouseActivityLine."Source Line No." := ProdOrderCompLine."Prod. Order Line No.";
        WarehouseActivityLine."Source Subline No." := ProdOrderCompLine."Line No.";
        WarehouseActivityLine."Item No." := ProdOrderCompLine."Item No.";
        WarehouseActivityLine."Variant Code" := ProdOrderCompLine."Variant Code";
        WarehouseActivityLine.Description := ProdOrderCompLine.Description;
        WarehouseActivityLine."Due Date" := ProdOrderCompLine."Due Date";
        WarehouseActivityLine."Whse. Document Type" := WarehouseActivityLine."Whse. Document Type"::Production;
        WarehouseActivityLine."Whse. Document No." := ProdOrderCompLine."Prod. Order No.";
        WarehouseActivityLine."Whse. Document Line No." := ProdOrderCompLine."Prod. Order Line No.";

        OnAfterTransferFromCompLine(WarehouseActivityLine, ProdOrderCompLine);
    end;

    procedure TransferFromOutputLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        WarehouseActivityLine."Activity Type" := WarehouseActivityLine."Activity Type"::"Put-away";
        WarehouseActivityLine."Source Type" := Database::"Prod. Order Line";
        WarehouseActivityLine."Source Subtype" := ProdOrderLine.Status.AsInteger();
        WarehouseActivityLine."Source No." := ProdOrderLine."Prod. Order No.";
        WarehouseActivityLine."Source Line No." := ProdOrderLine."Line No.";
        WarehouseActivityLine."Item No." := ProdOrderLine."Item No.";
        WarehouseActivityLine."Variant Code" := ProdOrderLine."Variant Code";
        WarehouseActivityLine.Description := ProdOrderLine.Description;
        WarehouseActivityLine."Due Date" := ProdOrderLine."Due Date";
        WarehouseActivityLine."Whse. Document Type" := WarehouseActivityLine."Whse. Document Type"::Production;
        WarehouseActivityLine."Whse. Document No." := ProdOrderLine."Prod. Order No.";
        WarehouseActivityLine."Whse. Document Line No." := ProdOrderLine."Line No.";

        OnAfterTransferFromOutputLine(WarehouseActivityLine, ProdOrderLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromCompLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Header", 'OnValidateSourceDocumentOnAssignSourceType', '', false, false)]
    local procedure OnValidateSourceDocumentOnAssignSourceType(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
        case WarehouseActivityHeader."Source Document" of
            WarehouseActivityHeader."Source Document"::"Prod. Consumption":
                begin
                    WarehouseActivityHeader."Source Type" := Database::"Prod. Order Component";
                    WarehouseActivityHeader."Source Subtype" := 3;
                end;
            WarehouseActivityHeader."Source Document"::"Prod. Output":
                begin
                    WarehouseActivityHeader."Source Type" := Database::"Prod. Order Line";
                    WarehouseActivityHeader."Source Subtype" := 3;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Registered Whse. Activity Line", 'OnShowWhseDoc', '', false, false)]
    local procedure RegisteredWhseActivityLineOnShowWhseDoc(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line")
    var
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: Page "Released Production Order";
    begin
        case RegisteredWhseActivityLine."Whse. Document Type" of
            RegisteredWhseActivityLine."Whse. Document Type"::Production:
                begin
                    ProductionOrder.SetRange(Status, RegisteredWhseActivityLine."Source Subtype");
                    ProductionOrder.SetRange("No.", RegisteredWhseActivityLine."Source No.");
                    ReleasedProductionOrder.SetTableView(ProductionOrder);
                    ReleasedProductionOrder.RunModal();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Cross-Dock Opportunity", 'OnShowReservation', '', false, false)]
    local procedure OnShowReservation(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case WhseCrossDockOpportunity."To Source Type" of
            Database::"Prod. Order Component":
                begin
                    ProdOrderComponent.Get(WhseCrossDockOpportunity."To Source Subtype", WhseCrossDockOpportunity."To Source No.", WhseCrossDockOpportunity."To Source Subline No.", WhseCrossDockOpportunity."To Source Line No.");
                    ProdOrderComponent.ShowReservation();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnGetDestinationEntityName', '', false, false)]
    local procedure OnGetDestinationEntityName(DestinationType: Enum "Warehouse Destination Type"; DestNo: Code[20]; var DestinationName: Text[100])
    var
        Family: Record Family;
    begin
        case DestinationType of
            DestinationType::Family:
                if Family.Get(DestNo) then
                    DestinationName := Family.Description;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnGetCaptionClass', '', false, false)]
    local procedure OnGetCaptionClass(DestinationType: Enum "Warehouse Destination Type"; Selection: Integer; var CaptionClass: Text[50])
    var
        Family: Record Family;
    begin
        case Selection of
            0:
                if DestinationType = DestinationType::Family then
                    CaptionClass := Family.TableCaption() + ' ' + Family.FieldCaption("No.");
            1:
                if DestinationType = DestinationType::Family then
                    CaptionClass := Family.TableCaption() + ' ' + Family.FieldCaption(Description);
        end;
    end;

    procedure SetDestinationType(ProdOrder: Record "Production Order"; var WarehouseRequest: Record "Warehouse Request")
    begin
        case ProdOrder."Source Type" of
            ProdOrder."Source Type"::Item:
                WarehouseRequest."Destination Type" := WarehouseRequest."Destination Type"::Item;
            ProdOrder."Source Type"::Family:
                WarehouseRequest."Destination Type" := WarehouseRequest."Destination Type"::Family;
            ProdOrder."Source Type"::"Sales Header":
                WarehouseRequest."Destination Type" := WarehouseRequest."Destination Type"::"Sales Order";
        end;

        OnAfterSetDestinationType(WarehouseRequest, ProdOrder);
#if not CLEAN26
        WarehouseRequest.RunOnAfterSetDestinationType(WarehouseRequest, ProdOrder);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDestinationType(var WhseRequest: Record "Warehouse Request"; ProdOrder: Record "Production Order")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Pick Request", 'OnLookupDocumentNo', '', false, false)]
    local procedure OnLookupDocumentNo(var WhsePickRequest: Record "Whse. Pick Request")
    var
        ProdOrderHeader: Record "Production Order";
        ProdOrderList: Page "Production Order List";
    begin
        case WhsePickRequest."Document Type" of
            WhsePickRequest."Document Type"::Production:
                begin
                    if ProdOrderHeader.Get(WhsePickRequest."Document Subtype", WhsePickRequest."Document No.") then
                        ProdOrderList.SetRecord(ProdOrderHeader);
                    ProdOrderList.RunModal();
                    Clear(ProdOrderList);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnItemLineVerifyChangeOnCheckEntryType', '', false, false)]
    local procedure OnItemLineVerifyChangeOnCheckEntryType(NewItemJnlLine: Record "Item Journal Line"; OldItemJnlLine: Record "Item Journal Line"; var LinesExist: Boolean; var QtyChecked: Boolean)
    var
        ProdOrderComp: Record "Prod. Order Component";
        QtyRemainingToBePicked: Decimal;
        IsHandled: Boolean;
    begin
        case NewItemJnlLine."Entry Type" of
            NewItemJnlLine."Entry Type"::Consumption:
                begin
                    NewItemJnlLine.TestField("Order Type", NewItemJnlLine."Order Type"::Production);
                    IsHandled := false;
                    OnItemLineVerifyChangeOnBeforeCheckConsumptionQty(NewItemJnlLine, Location, QtyChecked, IsHandled);
#if not CLEAN26
                    WhseValidateSourceLine.RunOnItemLineVerifyChangeOnBeforeCheckConsumptionQty(NewItemJnlLine, Location, QtyChecked, IsHandled);
#endif
                    if not Ishandled then
                        if Location.Get(NewItemJnlLine."Location Code") and (Location."Prod. Consump. Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)") then
                            if ProdOrderComp.Get(
                                ProdOrderComp.Status::Released,
                                NewItemJnlLine."Order No.", NewItemJnlLine."Order Line No.", NewItemJnlLine."Prod. Order Comp. Line No.") and
                                FlushingMethodRequiresManualPick(ProdOrderComp."Flushing Method") and
                                (NewItemJnlLine.Quantity >= 0)
                            then begin
                                QtyRemainingToBePicked :=
                                    NewItemJnlLine.Quantity - CalcNextLevelProdOutput(ProdOrderComp) -
                                    ProdOrderComp."Qty. Picked" + ProdOrderComp."Expected Quantity" - ProdOrderComp."Remaining Quantity";
                                CheckQtyRemainingToBePickedForConsumption(NewItemJnlLine, OldItemJnlLine, ProdOrderComp, QtyRemainingToBePicked);
                                QtyChecked := true;
                            end;

                    LinesExist :=
                      WhseValidateSourceLine.WhseLinesExist(
                        Database::"Prod. Order Component", 3, NewItemJnlLine."Order No.", NewItemJnlLine."Order Line No.", NewItemJnlLine."Prod. Order Comp. Line No.", NewItemJnlLine.Quantity) or
                      WhseValidateSourceLine.WhseWorkSheetLinesExist(
                        Database::"Prod. Order Component", 3, NewItemJnlLine."Order No.", NewItemJnlLine."Order Line No.", NewItemJnlLine."Prod. Order Comp. Line No.", NewItemJnlLine.Quantity);
                end;
            NewItemJnlLine."Entry Type"::Output:
                begin
                    NewItemJnlLine.TestField("Order Type", NewItemJnlLine."Order Type"::Production);
                    LinesExist :=
                      WhseValidateSourceLine.WhseLinesExist(
                        Database::"Prod. Order Line", 3, NewItemJnlLine."Order No.", NewItemJnlLine."Order Line No.", 0, NewItemJnlLine.Quantity);
                    QtyChecked := LinesExist;
                end;
        end;
    end;

    procedure CalcNextLevelProdOutput(ProdOrderComp: Record "Prod. Order Component"): Decimal
    var
        Item: Record Microsoft.Inventory.Item.Item;
        WarehouseEntry: Record Microsoft.Warehouse.Ledger."Warehouse Entry";
        ProdOrderLine: Record "Prod. Order Line";
        OutputBase: Decimal;
    begin
        Item.SetLoadFields("Replenishment System");
        Item.Get(ProdOrderComp."Item No.");
        if Item."Replenishment System" = Item."Replenishment System"::Purchase then
            exit(0);

        ProdOrderLine.SetRange(Status, ProdOrderComp.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderComp."Prod. Order No.");
        ProdOrderLine.SetRange("Item No.", ProdOrderComp."Item No.");
        ProdOrderLine.SetRange("Planning Level Code", ProdOrderComp."Planning Level Code");
        ProdOrderLine.SetLoadFields("Item No.");
        if ProdOrderLine.FindFirst() then begin
            WarehouseEntry.SetSourceFilter(
              Database::"Item Journal Line", 5, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", true); // Output Journal
            WarehouseEntry.SetRange("Reference No.", ProdOrderLine."Prod. Order No.");
            WarehouseEntry.SetRange("Item No.", ProdOrderLine."Item No.");
            WarehouseEntry.CalcSums(Quantity);
            OutputBase := WarehouseEntry.Quantity;
        end;

        exit(OutputBase);
    end;

    local procedure CheckQtyRemainingToBePickedForConsumption(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line"; ProdOrderComp: Record "Prod. Order Component"; QtyRemainingToBePicked: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyRemainingToBePickedForConsumption(NewItemJnlLine, OldItemJnlLine, IsHandled, ProdOrderComp, QtyRemainingToBePicked);
#if not CLEAN26
        WhseValidateSourceLine.RunOnBeforeCheckQtyRemainingToBePickedForConsumption(NewItemJnlLine, OldItemJnlLine, IsHandled, ProdOrderComp, QtyRemainingToBePicked);
#endif
        if IsHandled then
            exit;

        if QtyRemainingToBePicked > 0 then
            Error(CannotPostConsumptionErr, NewItemJnlLine."Order No.", QtyRemainingToBePicked);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemLineVerifyChangeOnBeforeCheckConsumptionQty(NewItemJournalLine: Record "Item Journal Line"; Location: Record Location; var QtyChecked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyRemainingToBePickedForConsumption(var NewItemJnlLine: Record "Item Journal Line"; var OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; QtyRemainingToBePicked: Decimal)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"Whse. Item Tracking Lines", 'OnSetSourceFilters', '', false, false)]
    local procedure OnSetSourceFilters(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var WhseWorksheetLine: Record "Whse. Worksheet Line"; SourceType: Integer)
    begin
        case SourceType of
            Database::"Prod. Order Component":
                begin
                    WhseItemTrackingLine.SetRange("Source Subtype", WhseWorksheetLine."Source Subtype");
                    WhseItemTrackingLine.SetRange("Source ID", WhseWorksheetLine."Source No.");
                    WhseItemTrackingLine.SetRange("Source Prod. Order Line", WhseWorksheetLine."Source Line No.");
                    WhseItemTrackingLine.SetRange("Source Ref. No.", WhseWorksheetLine."Source Subline No.");
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Whse. Item Tracking Lines", 'OnCopyToReservEntryOnUpdate', '', false, false)]
    local procedure OnCopyToReservEntryOnUpdate(var TempSourceWhseItemTrackingLine: Record "Whse. Item Tracking Line" temporary; var DueDate: Date; var QuantityBase: Decimal; var Updated: Boolean; var IsHandled: Boolean; FormSourceType: Integer; sender: Page "Whse. Item Tracking Lines")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        case FormSourceType of
            Database::"Prod. Order Component":
                begin
                    ProdOrderComp.Get(TempSourceWhseItemTrackingLine."Source Subtype", TempSourceWhseItemTrackingLine."Source ID",
                      TempSourceWhseItemTrackingLine."Source Prod. Order Line", TempSourceWhseItemTrackingLine."Source Ref. No.");
                    QuantityBase := ProdOrderComp."Expected Qty. (Base)";
                    DueDate := ProdOrderComp."Due Date";
                    Updated := sender.UpdateReservEntry(
                        TempSourceWhseItemTrackingLine."Source Type",
                        TempSourceWhseItemTrackingLine."Source Subtype",
                        TempSourceWhseItemTrackingLine."Source ID",
                        TempSourceWhseItemTrackingLine."Source Prod. Order Line",
                        TempSourceWhseItemTrackingLine."Source Ref. No.",
                        TempSourceWhseItemTrackingLine, QuantityBase, DueDate);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Worksheet Line", 'OnWhseItemTrackingLinesSetSource', '', false, false)]
    local procedure OnWhseItemTrackingLinesSetSource(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var IsHandled: Boolean; var WhseItemTrackingLines: Page "Whse. Item Tracking Lines");
    begin
        case WhseWorksheetLine."Whse. Document Type" of
            WhseWorksheetLine."Whse. Document Type"::Production:
                WhseItemTrackingLines.SetSource(WhseWorksheetLine, Database::"Prod. Order Component");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Warehouse Availability Mgt.", 'OnCalcLineReservedQtyOnInvtOnSetSourceFilters', '', false, false)]
    local procedure OnCalcLineReservedQtyOnInvtOnSetSourceFilters(var ReservEntry: Record "Reservation Entry"; SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; var IsHandled: Boolean)
    begin
        case SourceType of
            Database::"Prod. Order Component":
                begin
                    ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceID, SourceSubLineNo, true);
                    ReservEntry.SetSourceFilter('', SourceLineNo);
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Warehouse Availability Mgt.", 'OnCalcLineReservQtyOnPicksShipsOnAfterCalcPickedNotYetShippedQty', '', false, false)]
    local procedure OnCalcLineReservQtyOnPicksShipsOnAfterCalcPickedNotYetShippedQty(SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceProdOrderLine: Integer; SourceRefNo: Integer; var PickedNotYetShippedQty: Decimal)
    begin
        if SourceType = Database::"Prod. Order Component" then
            PickedNotYetShippedQty := CalcQtyPickedOnProdOrderComponentLine(SourceSubType, SourceID, SourceProdOrderLine, SourceRefNo)
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Warehouse Availability Mgt.", 'OnBeforeCalcQtyRegisteredPick', '', false, false)]
    local procedure OnBeforeCalcQtyRegisteredPick(SourceType: Integer; SourceSubType: Option; SourceID: Code[20]; SourceRefNo: Integer; SourceProdOrderLine: Integer; var Quantity: Decimal; var IsHandled: Boolean)
    begin
        if SourceType = Database::"Prod. Order Component" then begin
            Quantity := CalcQtyPickedOnProdOrderComponentLine(SourceSubType, SourceID, SourceProdOrderLine, SourceRefNo);
            IsHandled := true;
        end;
    end;

    local procedure CalcQtyPickedOnProdOrderComponentLine(SourceSubtype: Option; SourceID: Code[20]; SourceProdOrderLineNo: Integer; SourceRefNo: Integer): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, SourceSubtype);
        ProdOrderComponent.SetRange("Prod. Order No.", SourceID);
        ProdOrderComponent.SetRange("Prod. Order Line No.", SourceProdOrderLineNo);
        ProdOrderComponent.SetRange("Line No.", SourceRefNo);
        ProdOrderComponent.SetLoadFields("Qty. Picked (Base)");
        if ProdOrderComponent.FindFirst() then
            exit(ProdOrderComponent."Qty. Picked (Base)");

        exit(0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Warehouse Availability Mgt.", 'OnGetOutboundBinsOnBasicWarehouseLocationOnAfterSetWarehouseEntryFilters', '', false, false)]
    local procedure OnGetOutboundBinsOnBasicWarehouseLocationOnAfterSetWarehouseEntryFilters(var WarehouseEntry: Record "Warehouse Entry")
    var
        FilterString: Text;
    begin
        FilterString := WarehouseEntry.GetFilter("Whse. Document Type");
        if FilterString <> '' then begin
            FilterString += StrSubstNo('|%1', Format(WarehouseEntry."Whse. Document Type"::Production));
            WarehouseEntry.SetFilter("Whse. Document Type", FilterString);
        end else
            WarehouseEntry.SetFilter("Whse. Document Type", '%1', WarehouseEntry."Whse. Document Type"::Production);
    end;


    procedure FromProdOrderCompLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; ToBinCode: Code[20]; ProdOrderCompLine: Record "Prod. Order Component"): Boolean
    var
        Bin: Record Bin;
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseManagement: Codeunit "Whse. Management";
        WhseWorksheetCreate: Codeunit "Whse. Worksheet-Create";
    begin
        WhseWkshLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
        WhseWkshLine.SetRange("Source Type", Database::"Prod. Order Component");
        WhseWkshLine.SetRange("Source Subtype", ProdOrderCompLine.Status);
        WhseWkshLine.SetRange("Source No.", ProdOrderCompLine."Prod. Order No.");
        WhseWkshLine.SetRange("Source Line No.", ProdOrderCompLine."Prod. Order Line No.");
        WhseWkshLine.SetRange("Source Subline No.", ProdOrderCompLine."Line No.");
        if not WhseWkshLine.IsEmpty() then
            exit;

        WhseWorksheetCreate.FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, LocationCode);

        WhseWkshLine.Init();
        WhseWkshLine.SetHideValidationDialog(true);
        WhseWkshLine."Line No." := WhseWkshLine."Line No." + 10000;
        WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::Production;
        WhseWkshLine."Whse. Document No." := ProdOrderCompLine."Prod. Order No.";
        WhseWkshLine."Whse. Document Line No." := ProdOrderCompLine."Prod. Order Line No.";
        WhseWkshLine."Source Type" := Database::"Prod. Order Component";
        WhseWkshLine."Source Subtype" := ProdOrderCompLine.Status.AsInteger();
        WhseWkshLine."Source No." := ProdOrderCompLine."Prod. Order No.";
        WhseWkshLine."Source Line No." := ProdOrderCompLine."Prod. Order Line No.";
        WhseWkshLine."Source Subline No." := ProdOrderCompLine."Line No.";
        WhseWkshLine."Source Document" := WhseManagement.GetWhseActivSourceDocument(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype");
        WhseWkshLine."Location Code" := ProdOrderCompLine."Location Code";
        WhseWkshLine."Item No." := ProdOrderCompLine."Item No.";
        WhseWkshLine."Variant Code" := ProdOrderCompLine."Variant Code";
        WhseWkshLine."Unit of Measure Code" := ProdOrderCompLine."Unit of Measure Code";
        WhseWkshLine."Qty. per Unit of Measure" := ProdOrderCompLine."Qty. per Unit of Measure";
        WhseWkshLine.Description := ProdOrderCompLine.Description;
        WhseWkshLine."Due Date" := ProdOrderCompLine."Due Date";
        WhseWkshLine."Qty. Handled" := ProdOrderCompLine."Qty. Picked" + ProdOrderCompLine."Pick Qty.";
        WhseWkshLine."Qty. Handled (Base)" := ProdOrderCompLine."Qty. Picked (Base)" + ProdOrderCompLine."Pick Qty. (Base)";
        WhseWkshLine.Validate(Quantity, ProdOrderCompLine."Expected Quantity");
        WhseWkshLine."To Bin Code" := ToBinCode;
        if (ProdOrderCompLine."Location Code" <> '') and (ToBinCode <> '') then begin
            Bin.Get(LocationCode, ToBinCode);
            WhseWkshLine."To Zone Code" := Bin."Zone Code";
        end;
        OnAfterFromProdOrderCompLineCreateWhseWkshLine(WhseWkshLine, ProdOrderCompLine, LocationCode, ToBinCode);
#if not CLEAN26
        OnAfterFromProdOrderCompLineCreateWhseWkshLine(WhseWkshLine, ProdOrderCompLine, LocationCode, ToBinCode);
#endif
        if WhseWorksheetCreate.CreateWhseWkshLine(WhseWkshLine, ProdOrderCompLine) then
            exit(true);
    end;

    procedure FromProdOrderLine(WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; FromBinCode: Code[20]; ProdOrderLine: Record "Prod. Order Line"): Boolean
    var
        Bin: Record Bin;
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseManagement: Codeunit "Whse. Management";
        WhseWorksheetCreate: Codeunit "Whse. Worksheet-Create";
    begin
        WhseWkshLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
        WhseWkshLine.SetRange("Source Type", Database::"Prod. Order Component");
        WhseWkshLine.SetRange("Source Subtype", ProdOrderLine.Status);
        WhseWkshLine.SetRange("Source No.", ProdOrderLine."Prod. Order No.");
        WhseWkshLine.SetRange("Source Line No.", ProdOrderLine."Line No.");
        if not WhseWkshLine.IsEmpty() then
            exit;

        WhseWorksheetCreate.FindLastWhseWkshLine(WhseWkshLine, WhseWkshTemplateName, WhseWkshName, LocationCode);

        WhseWkshLine.Init();
        WhseWkshLine.SetHideValidationDialog(true);
        WhseWkshLine."Line No." := WhseWkshLine."Line No." + 10000;
        WhseWkshLine."Whse. Document Type" := WhseWkshLine."Whse. Document Type"::Production;
        WhseWkshLine."Whse. Document No." := ProdOrderLine."Prod. Order No.";
        WhseWkshLine."Whse. Document Line No." := ProdOrderLine."Line No.";
        WhseWkshLine."Source Type" := Database::"Prod. Order Line";
        WhseWkshLine."Source Subtype" := ProdOrderLine.Status.AsInteger();
        WhseWkshLine."Source No." := ProdOrderLine."Prod. Order No.";
        WhseWkshLine."Source Line No." := ProdOrderLine."Line No.";
        WhseWkshLine."Source Subline No." := ProdOrderLine."Line No.";
        WhseWkshLine."Source Document" := WhseManagement.GetWhseActivSourceDocument(WhseWkshLine."Source Type", WhseWkshLine."Source Subtype");
        WhseWkshLine."Location Code" := ProdOrderLine."Location Code";
        WhseWkshLine."Item No." := ProdOrderLine."Item No.";
        WhseWkshLine."Variant Code" := ProdOrderLine."Variant Code";
        WhseWkshLine."Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        WhseWkshLine."From Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        WhseWkshLine."Qty. per Unit of Measure" := ProdOrderLine."Qty. per Unit of Measure";
        WhseWkshLine.Description := ProdOrderLine.Description;
        WhseWkshLine."Due Date" := ProdOrderLine."Due Date";
        WhseWkshLine.Validate(Quantity, (ProdOrderLine."Finished Quantity" - (ProdOrderLine."Qty. Put Away" + ProdOrderLine."Put-away Qty.")));
        WhseWkshLine.Validate("Qty. Handled", ProdOrderLine."Qty. Put Away" + ProdOrderLine."Put-away Qty.");
        WhseWkshLine."From Bin Code" := FromBinCode;
        if (ProdOrderLine."Location Code" <> '') and (FromBinCode <> '') then begin
            Bin.Get(LocationCode, FromBinCode);
            WhseWkshLine."From Zone Code" := Bin."Zone Code";
        end;
        if WhseWorksheetCreate.CreateWhseWkshLine(WhseWkshLine, ProdOrderLine) then
            exit(true);
    end;

    local procedure FlushingMethodRequiresPick(FlushingMethod: Enum "Flushing Method"): Boolean
#if not CLEAN26
    var
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
    begin
#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            exit(FlushingMethod in [FlushingMethod::Manual, FlushingMethod::"Pick + Manual", FlushingMethod::"Pick + Backward", FlushingMethod::"Pick + Forward"])
        else
#endif
        exit(FlushingMethod in [FlushingMethod::"Pick + Manual", FlushingMethod::"Pick + Backward", FlushingMethod::"Pick + Forward"]);
    end;

    local procedure FlushingMethodRequiresManualPick(FlushingMethod: Enum "Flushing Method"): Boolean
#if not CLEAN26
    var
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
    begin
#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            exit(FlushingMethod in [FlushingMethod::Manual, FlushingMethod::"Pick + Manual"])
        else
#endif
        exit(FlushingMethod = FlushingMethod::"Pick + Manual");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFromProdOrderCompLineCreateWhseWkshLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ProdOrderComponent: Record "Prod. Order Component"; LocationCode: Code[10]; ToBinCode: Code[20])
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetWhseRqstSourceDocument', '', false, false)]
    local procedure OnAfterGetWhseRqstSourceDocument(WhseJournalSourceDocument: Enum "Warehouse Journal Source Document"; var SourceDocument: Enum "Warehouse Request Source Document")
    begin
        case WhseJournalSourceDocument of
            WhseJournalSourceDocument::"Prod. Consumption":
                SourceDocument := "Warehouse Request Source Document"::"Prod. Consumption";
            WhseJournalSourceDocument::"Item Jnl.":
                SourceDocument := "Warehouse Request Source Document"::"Prod. Output";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Header", 'OnProdWhseHandlingIsInventoryPutaway', '', false, false)]
    local procedure OnProdWhseHandlingIsInventoryPutaway(Location: Record Location; var Result: Boolean)
    begin
        Result := Location."Prod. Output Whse. Handling" = Location."Prod. Output Whse. Handling"::"Inventory Put-away";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromOutputLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;
}
