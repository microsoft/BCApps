// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Planning;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 5431 "Calc. Item Plan - Plan Wksh."
{
    TableNo = Item;

    trigger OnRun()
    begin
        Item.Copy(Rec);
        Code();
        Rec := Item;
    end;

    var
        Item: Record Item;
        TempPlanningCompList: Record "Planning Component" temporary;
        TempItemList: Record Item temporary;
        InvtProfileOffsetting: Codeunit "Inventory Profile Offsetting";
        MPS: Boolean;
        MRP: Boolean;
        NetChange: Boolean;
        PeriodLength: Integer;
        CurrTemplateName: Code[10];
        CurrWorksheetName: Code[10];
        UseForecast: Code[10];
        FromDate: Date;
        ToDate: Date;
#pragma warning disable AA0074
        Text000: Label 'You must decide what to calculate.';
        Text001: Label 'Enter a starting date.';
        Text002: Label 'Enter an ending date.';
        Text003: Label 'The ending date must not be before the order date.';
#pragma warning restore AA0074
        ExcludeForecastBefore: Date;
        RespectPlanningParm: Boolean;

    local procedure "Code"()
    var
        ReqLineExtern: Record "Requisition Line";
        PlanningAssignment: Record "Planning Assignment";
        IsHandled: Boolean;
    begin
        if not PlanThisItem() then
            exit;

        ReqLineExtern.SetCurrentKey(Type, "No.", "Variant Code", "Location Code");
        Item.CopyFilter("Variant Filter", ReqLineExtern."Variant Code");
        Item.CopyFilter("Location Filter", ReqLineExtern."Location Code");
        ReqLineExtern.SetRange(Type, ReqLineExtern.Type::Item);
        ReqLineExtern.SetRange("No.", Item."No.");
        OnCodeOnAfterSetReqLineFilters(ReqLineExtern, CurrTemplateName, CurrWorksheetName, FromDate, ToDate);
        if ReqLineExtern.Find('-') then
            repeat
                ReqLineExtern.Delete(true);
            until ReqLineExtern.Next() = 0;

        OnAfterReqLineExternDelete(Item);

        Commit();

        OnCodeOnBeforeInvtProfileOffsettingSetParm(Item);

        CalculateAndGetPlanningCompList();

        Item.CopyFilter(Item."Variant Filter", PlanningAssignment."Variant Code");
        Item.CopyFilter(Item."Location Filter", PlanningAssignment."Location Code");
        PlanningAssignment.SetRange("Item No.", Item."No.");
        PlanningAssignment.SetRange(Inactive, false);
        PlanningAssignment.SetRange("Net Change Planning", true);
        PlanningAssignment.SetFilter("Latest Date", '..%1', ToDate);
        if not PlanningAssignment.IsEmpty() then
            PlanningAssignment.ModifyAll(Inactive, true);

        OnCodeOnAfterGetPlanningComponents(Item);

        Commit();

        TempItemList := Item;

        IsHandled := false;
        OnCodeOnBeforeTempItemListInsert(TempItemList, IsHandled);
        if not IsHandled then
            TempItemList.Insert();

        OnAfterCode(TempItemList, FromDate, ToDate);
    end;

    local procedure CalculateAndGetPlanningCompList()
    var
#if not CLEAN27
        MfgSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
#endif
        CurrWorksheetType: Option Requisition,Planning;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateAndGetPlanningComponents(Item, CurrTemplateName, CurrWorksheetName, ToDate, FromDate, UseForecast, ExcludeForecastBefore, MRP, RespectPlanningParm, TempPlanningCompList, IsHandled, InvtProfileOffsetting);
#if not CLEAN27
        MfgSetup.Get();
        OnBeforeCalculateAndGetPlanningCompList(Item, CurrTemplateName, CurrWorksheetName, ToDate, FromDate, UseForecast, ExcludeForecastBefore, MfgSetup, MRP, RespectPlanningParm, TempPlanningCompList, IsHandled, InvtProfileOffsetting);
#endif
        if IsHandled then
            exit;

        InvtProfileOffsetting.SetParm(UseForecast, ExcludeForecastBefore, CurrWorksheetType::Planning);
        InvtProfileOffsetting.CalculatePlanFromWorksheet(Item, CurrTemplateName, CurrWorksheetName, FromDate, ToDate, MRP, RespectPlanningParm);

        // Retrieve list of Planning Components handled:
        InvtProfileOffsetting.GetPlanningCompList(TempPlanningCompList);
    end;

    procedure Initialize(NewFromDate: Date; NewToDate: Date; NewMPS: Boolean; NewMRP: Boolean; NewRespectPlanningParm: Boolean)
    begin
        FromDate := NewFromDate;
        ToDate := NewToDate;
        MPS := NewMPS;
        MRP := NewMRP;
        RespectPlanningParm := NewRespectPlanningParm;

        CheckPreconditions();
    end;

    procedure Finalize()
    var
        PlanningComponent: Record "Planning Component";
        RequisitionLine: Record "Requisition Line";
        ReservMgt: Codeunit "Reservation Management";
    begin
        // Items already planned for removed from temporary list:
        if TempPlanningCompList.Find('-') then
            repeat
                if TempPlanningCompList."Planning Level Code" > 0 then begin
                    RequisitionLine.SetRange("Worksheet Template Name", CurrTemplateName);
                    RequisitionLine.SetRange("Journal Batch Name", CurrWorksheetName);
                    RequisitionLine.SetRange("Ref. Order Type", TempPlanningCompList."Ref. Order Type");
                    RequisitionLine.SetRange("Ref. Order No.", TempPlanningCompList."Ref. Order No.");
                    RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
                    RequisitionLine.SetRange("No.", TempPlanningCompList."Item No.");
                    if RequisitionLine.IsEmpty() then begin
                        PlanningComponent := TempPlanningCompList;
                        PlanningComponent.Find();
                        PlanningComponent.Validate("Planning Level Code", 0);
                        PlanningComponent.Modify(true);
                    end;
                end;
                if TempItemList.Get(TempPlanningCompList."Item No.") then
                    TempPlanningCompList.Delete();
            until TempPlanningCompList.Next() = 0;

        // Dynamic tracking is run for the remaining Planning Components:
        if TempPlanningCompList.Find('-') then
            repeat
                ReservMgt.SetReservSource(TempPlanningCompList);
                ReservMgt.AutoTrack(TempPlanningCompList."Net Quantity (Base)");
            until TempPlanningCompList.Next() = 0;

        Commit();
    end;

    local procedure CheckPreconditions()
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckPreconditions(Item, MPS, MRP, FromDate, ToDate, IsHandled);
        if IsHandled then
            exit;

        if not MPS and not MRP then
            Error(Text000);

        if FromDate = 0D then
            Error(Text001);
        if ToDate = 0D then
            Error(Text002);
        PeriodLength := ToDate - FromDate + 1;
        if PeriodLength <= 0 then
            Error(Text003);
    end;

    procedure SetTemplAndWorksheet(TemplateName: Code[10]; WorksheetName: Code[10]; NetChange2: Boolean)
    begin
        CurrTemplateName := TemplateName;
        CurrWorksheetName := WorksheetName;
        NetChange := NetChange2;
    end;

    local procedure PlanThisItem() Result: Boolean
    var
        SKU: Record "Stockkeeping Unit";
        ForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        PlanningAssignment: Record "Planning Assignment";
        JobPlanningLine: Record "Job Planning Line";
        InventorySetup: Record "Inventory Setup";
        IsHandled: Boolean;
        DoExit: Boolean;
        LinesExist: Boolean;
    begin
        IsHandled := false;
        OnBeforePlanThisItem(Item, IsHandled, MPS, MRP, NetChange, FromDate, ToDate, UseForecast, RespectPlanningParm, Result);
        if IsHandled then
            exit(Result);

        SKU.SetCurrentKey("Item No.");
        Item.CopyFilter("Variant Filter", SKU."Variant Code");
        Item.CopyFilter("Location Filter", SKU."Location Code");
        SKU.SetRange("Item No.", Item."No.");
        if SKU.IsEmpty() and (Item."Reordering Policy" = Item."Reordering Policy"::" ") then
            exit(false);

        Item.CopyFilter("Variant Filter", PlanningAssignment."Variant Code");
        Item.CopyFilter("Location Filter", PlanningAssignment."Location Code");
        PlanningAssignment.SetRange(Inactive, false);
        PlanningAssignment.SetRange("Net Change Planning", true);
        PlanningAssignment.SetRange("Item No.", Item."No.");
        if NetChange and PlanningAssignment.IsEmpty() then
            exit(false);

        if MRP = MPS then
            exit(true);

        SalesLine.SetCurrentKey("Document Type", Type, "No.", "Variant Code", "Drop Shipment", "Location Code", "Shipment Date");
        SalesLine.SetFilter("Document Type", '%1|%2', SalesLine."Document Type"::Order, SalesLine."Document Type"::"Blanket Order");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        Item.CopyFilter("Variant Filter", SalesLine."Variant Code");
        Item.CopyFilter("Location Filter", SalesLine."Location Code");
        SalesLine.SetRange("No.", Item."No.");
        SalesLine.SetFilter("Outstanding Qty. (Base)", '<>0');
        if not SalesLine.IsEmpty() then
            exit(MPS);

        ForecastEntry.SetCurrentKey("Production Forecast Name", "Item No.", "Location Code", "Forecast Date", "Component Forecast");
        ForecastEntry.SetRange("Production Forecast Name", UseForecast);
        InventorySetup.Get();
        if InventorySetup."Use Forecast on Locations" then
            Item.CopyFilter("Location Filter", ForecastEntry."Location Code");
        if InventorySetup."Use Forecast on Variants" then
            Item.CopyFilter("Variant Filter", ForecastEntry."Variant Code");
        ForecastEntry.SetRange("Item No.", Item."No.");
        if ForecastEntry.FindFirst() then begin
            ForecastEntry.CalcSums("Forecast Quantity (Base)");
            if ForecastEntry."Forecast Quantity (Base)" > 0 then
                exit(MPS);
        end;

        IsHandled := false;
        DoExit := false;
        OnPlanThisItemOnBeforeCheckServJobPlanningLines(Item, IsHandled, MPS, MRP, NetChange, FromDate, ToDate, UseForecast, RespectPlanningParm, Result, DoExit);
        if not IsHandled then begin
            LinesExist := false;
            OnPlanThisItemOnBeforeExitMPS(Item, LinesExist);
            if LinesExist then
                exit(MPS);

            if JobPlanningLine.LinesWithItemToPlanExist(Item) then
                exit(MPS);
        end else
            if DoExit then
                exit(Result);

        if not ProdOrderLineIsEmpty() then
            exit(MPS);

        PurchaseLine.SetCurrentKey("Document Type", Type, "No.");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("MPS Order", true);
        PurchaseLine.SetRange("No.", Item."No.");
        if not PurchaseLine.IsEmpty() then
            exit(MPS);

        exit(MRP);
    end;

    procedure SetParm(Forecast: Code[10]; ExclBefore: Date; var Item2: Record Item)
    begin
        UseForecast := Forecast;
        ExcludeForecastBefore := ExclBefore;
        Item.Copy(Item2);
    end;

    procedure SetResiliencyOn()
    begin
        InvtProfileOffsetting.SetResiliencyOn();
    end;

    procedure GetResiliencyError(var PlanningErrorLogEntry: Record "Planning Error Log"): Boolean
    begin
        exit(InvtProfileOffsetting.GetResiliencyError(PlanningErrorLogEntry));
    end;

    procedure ClearInvtProfileOffsetting()
    begin
        Clear(InvtProfileOffsetting);
    end;

    local procedure ProdOrderLineIsEmpty() Result: Boolean
    begin
        OnProdOrderLineIsEmpty(Item, Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPreconditions(var Item: Record Item; MPS: Boolean; MRP: Boolean; FromDate: Date; ToDate: Date; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('Replaced by event OnBeforeCalculateAndGetPlanningComponents()', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateAndGetPlanningCompList(var Item: Record Item; CurrTemplateName: Code[10]; CurrWorksheetName: Code[10]; ToDate: Date; FromDate: Date; UseForecast: Code[10]; ExcludeForecastBefore: Date; MfgSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup"; MRP: Boolean; RespectPlanningParm: Boolean; var TempPlanningCompList: Record "Planning Component" temporary; var IsHandled: Boolean; var InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateAndGetPlanningComponents(var Item: Record Item; CurrTemplateName: Code[10]; CurrWorksheetName: Code[10]; ToDate: Date; FromDate: Date; UseForecast: Code[10]; ExcludeForecastBefore: Date; MRP: Boolean; RespectPlanningParm: Boolean; var TempPlanningCompList: Record "Planning Component" temporary; var IsHandled: Boolean; var InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePlanThisItem(Item: Record Item; var IsHandled: Boolean; MPS: Boolean; MRP: Boolean; NetChange: Boolean; var FromDate: Date; ToDate: Date; UseForecast: Code[10]; RespectPlanningParm: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterGetPlanningComponents(Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterSetReqLineFilters(var ReqLineExtern: Record "Requisition Line"; CurrTemplateName: Code[10]; CurrWorksheetName: Code[10]; var FromDate: Date; var ToDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeInvtProfileOffsettingSetParm(Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeTempItemListInsert(TempItemList: Record Item temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanThisItemOnBeforeCheckServJobPlanningLines(var Item: Record Item; var IsHandled: Boolean; MPS: Boolean; MRP: Boolean; NetChange: Boolean; var FromDate: Date; ToDate: Date; UseForecast: Code[10]; RespectPlanningParm: Boolean; var Result: Boolean; var DoExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPlanThisItemOnBeforeExitMPS(var Item: Record Item; var LinesExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var TempItemList: Record Item temporary; var FromDate: Date; var ToDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReqLineExternDelete(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderLineIsEmpty(var Item: Record Item; var Result: Boolean)
    begin
    end;
}

