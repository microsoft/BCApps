// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Purchases.Vendor;

report 699 "Calculate Plan - Req. Wksh."
{
    Caption = 'Calculate Plan - Req. Wksh.';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("Low-Level Code") where(Type = const(Inventory), Blocked = const(false));
            RequestFilterFields = "No.", "Search Description", "Location Filter";

            trigger OnAfterGetRecord()
            var
                SkipPlanning: Boolean;
                IsHandled: Boolean;
            begin
                if GuiAllowed and (Counter mod 5 = 0) then
                    Window.Update(1, "No.");
                Counter := Counter + 1;

                if SkipPlanningForItemOnReqWksh(Item) then
                    CurrReport.Skip();

                ReqLine.LockTable();
                ActionMessageEntry.LockTable();

                IsHandled := false;
                OnBeforeDeleteReqLines(Item, PurchReqLine, ReqLineExtern, IsHandled, InventoryProfileOffsetting);
                if not IsHandled then begin
                    PurchReqLine.SetRange("No.", "No.");
                    PurchReqLine.ModifyAll("Accept Action Message", false);
                    PurchReqLine.DeleteAll(true);

                    ReqLineExtern.SetRange(Type, ReqLine.Type::Item);
                    ReqLineExtern.SetRange("No.", "No.");
                    if ReqLineExtern.Find('-') then
                        repeat
                            ReqLineExtern.Delete(true);
                        until ReqLineExtern.Next() = 0;
                end;
                SkipPlanning := false;
                OnItemOnAfterDeleteReqLines(Item, SkipPlanning);
                if SkipPlanning then
                    CurrReport.Skip();

                SetParamAndCalculatePlanFromWorksheet();

                PlanningAssignment.SetRange("Item No.", "No.");
                PlanningAssignment.SetFilter("Latest Date", '..%1', ToDate);
                if not PlanningAssignment.IsEmpty() then
                    PlanningAssignment.ModifyAll(Inactive, true);
                PlanningAssignment.SetRange("Latest Date");

                OnItemOnAfterGetRecordOnBeforeCommit(ReqLine, Item, CurrTemplateName, CurrWorksheetName, FromDate);
                Commit();
            end;

            trigger OnPostDataItem()
            begin
                OnAfterItemOnPostDataItem(Item, CurrTemplateName, CurrWorksheetName, FromDate, ToDate);
            end;

            trigger OnPreDataItem()
            begin
                SKU.SetCurrentKey("Item No.");
                CopyFilter("Variant Filter", SKU."Variant Code");
                CopyFilter("Location Filter", SKU."Location Code");

                CopyFilter("Variant Filter", PlanningAssignment."Variant Code");
                CopyFilter("Location Filter", PlanningAssignment."Location Code");
                PlanningAssignment.SetRange(Inactive, false);
                PlanningAssignment.SetRange("Net Change Planning", true);

                ReqLineExtern.SetCurrentKey(Type, "No.", "Variant Code", "Location Code");
                CopyFilter("Variant Filter", ReqLineExtern."Variant Code");
                CopyFilter("Location Filter", ReqLineExtern."Location Code");

                PurchReqLine.SetCurrentKey(
                  Type, "No.", "Variant Code", "Location Code", "Sales Order No.", "Planning Line Origin", "Due Date");
                PurchReqLine.SetRange(Type, PurchReqLine.Type::Item);
                CopyFilter("Variant Filter", PurchReqLine."Variant Code");
                CopyFilter("Location Filter", PurchReqLine."Location Code");
                PurchReqLine.SetFilter("Worksheet Template Name", ReqWkshTemplateFilter);
                PurchReqLine.SetFilter("Journal Batch Name", ReqWkshFilter);

                OnAfterItemOnPreDataItem(Item);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; FromDate)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date to use for new orders. This date is used to evaluate the inventory.';
                    }
                    field(EndingDate; ToDate)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date where the planning period ends. Demand is not included beyond this date.';
                    }
                    field(UseForecast; UseForecast)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Use Forecast';
                        TableRelation = Microsoft.Manufacturing.Forecast."Production Forecast Name".Name;
                        ToolTip = 'Specifies a forecast that should be included as demand when running the planning batch job.';
                    }
                    field(ExcludeForecastBefore; ExcludeForecastBefore)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Exclude Forecast Before';
                        ToolTip = 'Specifies how much of the selected forecast to include, by entering a date before which forecast demand is not included.';
                    }
                    field(RespectPlanningParm; RespectPlanningParm)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Respect Planning Parameters for Supply Triggered by Safety Stock';
                        ToolTip = 'Specifies that planning lines triggered by safety stock will respect the following planning parameters: Reorder Point, Reorder Quantity, Reorder Point, and Maximum Inventory in addition to all order modifiers. If you do not select this check box, planning lines triggered by safety stock will only cover the exact demand quantity.';
                    }
                    field(PriceCalcMethod; PriceCalculationMethod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Price Calculation Method';
                        ToolTip = 'Specifies the price calculation method.';
                        Visible = ExtendedPriceEnabled;

                        trigger OnValidate()
                        begin
                            ValidatePriceCalcMethod();
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        var
            PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        begin
            InitializeFromSetup();
            ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
            ValidatePriceCalcMethod();
            OnAfterOnOpenPage(FromDate, ToDate);
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        ProductionForecastEntry: Record Microsoft.Manufacturing.Forecast."Production Forecast Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnPreReport(CurrTemplateName, CurrWorksheetName, ReqLine, FromDate, ToDate, IsHandled);
        if IsHandled then
            exit;

        Counter := 0;
        if FromDate = 0D then
            Error(Text002);
        if ToDate = 0D then
            Error(Text003);
        PeriodLength := ToDate - FromDate + 1;
        if PeriodLength <= 0 then
            Error(Text004);

        if (Item.GetFilter("Variant Filter") <> '') and
           (InventorySetup."Current Demand Forecast" <> '')
        then begin
            ProductionForecastEntry.SetRange("Production Forecast Name", InventorySetup."Current Demand Forecast");
            Item.CopyFilter("No.", ProductionForecastEntry."Item No.");
            if InventorySetup."Use Forecast on Locations" then
                Item.CopyFilter("Location Filter", ProductionForecastEntry."Location Code");
            if InventorySetup."Use Forecast on Variants" then
                Item.CopyFilter("Variant Filter", ProductionForecastEntry."Variant Code");
            if not ProductionForecastEntry.IsEmpty() then
                Error(Text005);
        end;

        ReqLine.SetRange("Worksheet Template Name", CurrTemplateName);
        ReqLine.SetRange("Journal Batch Name", CurrWorksheetName);

        if GuiAllowed then
            Window.Open(Text006 + Text007);
    end;

    var
        ActionMessageEntry: Record "Action Message Entry";
        InventorySetup: Record "Inventory Setup";
        CurrWorksheetType: Option Requisition,Planning;
        PeriodLength: Integer;
        ReqWkshTemplateFilter: Code[50];
        ReqWkshFilter: Code[50];
        Counter: Integer;

#pragma warning disable AA0074
        Text002: Label 'Enter a starting date.';
        Text003: Label 'Enter an ending date.';
        Text004: Label 'The ending date must not be before the order date.';
        Text005: Label 'You must not use a variant filter when calculating MPS from a forecast.';
        Text006: Label 'Calculating the plan...\\';
#pragma warning disable AA0470
        Text007: Label 'Item No.  #1##################';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
#if not CLEAN27
        [Obsolete('Replaced by record Inventory Setup', '27.0')]
        MfgSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
#endif
        SKU: Record "Stockkeeping Unit";
        ReqLine: Record "Requisition Line";
        ReqLineExtern: Record "Requisition Line";
        PurchReqLine: Record "Requisition Line";
        PlanningAssignment: Record "Planning Assignment";
        InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting";
        Window: Dialog;
        CurrTemplateName: Code[10];
        CurrWorksheetName: Code[10];
        FromDate: Date;
        ToDate: Date;
        PriceCalculationMethod: Enum "Price Calculation Method";
        ExtendedPriceEnabled: Boolean;
        UseForecast: Code[10];
        ExcludeForecastBefore: Date;
        RespectPlanningParm: Boolean;

    procedure SetTemplAndWorksheet(TemplateName: Code[10]; WorksheetName: Code[10])
    begin
        CurrTemplateName := TemplateName;
        CurrWorksheetName := WorksheetName;
    end;

    procedure InitializeRequest(StartDate: Date; EndDate: Date)
    begin
        FromDate := StartDate;
        ToDate := EndDate;
    end;

    procedure InitializeFromSetup()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitializeFromSetup(UseForecast, IsHandled, InventorySetup);
#if not CLEAN27
        OnBeforeInitializeFromMfgSetup(UseForecast, IsHandled, MfgSetup);
#endif
        if IsHandled then
            exit;

        InventorySetup.Get();
        UseForecast := InventorySetup."Current Demand Forecast";
    end;

#if not CLEAN27
    [Obsolete('Replaced by procedure InitializeFromSetup()', '27.0')]
    procedure InitializeFromMfgSetup()
    begin
        InitializeFromSetup();
    end;
#endif

    procedure SetParamAndCalculatePlanFromWorksheet()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetParamAndCalculatePlanFromReqWorksheet(UseForecast, ExcludeForecastBefore, CurrWorksheetType, PriceCalculationMethod, Item, CurrTemplateName, CurrWorksheetName, FromDate, ToDate, RespectPlanningParm, IsHandled);
#if not CLEAN27
        OnBeforeSetParamAndCalculatePlanFromWorksheet(UseForecast, ExcludeForecastBefore, CurrWorksheetType, PriceCalculationMethod, Item, MfgSetup, CurrTemplateName, CurrWorksheetName, FromDate, ToDate, RespectPlanningParm, IsHandled);
#endif
        if IsHandled then
            exit;

        InventoryProfileOffsetting.SetParm(UseForecast, ExcludeForecastBefore, CurrWorksheetType, PriceCalculationMethod);
        InventoryProfileOffsetting.CalculatePlanFromWorksheet(Item, CurrTemplateName, CurrWorksheetName, FromDate, ToDate, true, RespectPlanningParm);
    end;

    procedure ValidatePriceCalcMethod()
    var
        Vendor: Record Vendor;
    begin
        if PriceCalculationMethod = PriceCalculationMethod::" " then
            PriceCalculationMethod := Vendor.GetPriceCalculationMethod();
    end;

    procedure SkipPlanningForItemOnReqWksh(Item: Record Item): Boolean
    var
        SkipPlanning: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        SkipPlanning := false;

        OnBeforeSkipPlanningForItemOnReqWksh(Item, SkipPlanning, IsHandled, SKU, CurrWorksheetType);
        if IsHandled then
            exit(SkipPlanning);

        if (CurrWorksheetType = CurrWorksheetType::Requisition) and
               (Item."Replenishment System" = Item."Replenishment System"::Purchase) and
               (Item."Reordering Policy" <> Item."Reordering Policy"::" ")
        then
            exit(false);

        SKU.SetRange(SKU."Item No.", Item."No.");
        if SKU.Find('-') then
            repeat
                if (CurrWorksheetType = CurrWorksheetType::Requisition) and
                   (SKU."Replenishment System" in [SKU."Replenishment System"::Purchase,
                                               SKU."Replenishment System"::Transfer]) and
                   (SKU."Reordering Policy" <> SKU."Reordering Policy"::" ")
                then
                    exit(false);
            until SKU.Next() = 0;

        SkipPlanning := true;
        OnAfterSkipPlanningForItemOnReqWksh(Item, SkipPlanning);
        exit(SkipPlanning);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnOpenPage(var FromDate: Date; var ToDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemOnPreDataItem(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemOnPostDataItem(var Item: Record Item; CurrTemplateName: Code[10]; CurrWorksheetName: Code[10]; FromDate: Date; ToDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSkipPlanningForItemOnReqWksh(Item: Record Item; var SkipPlanning: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSkipPlanningForItemOnReqWksh(Item: Record Item; var SkipPlanning: Boolean; var IsHandled: Boolean; StockkeepingUnit: Record "Stockkeeping Unit"; CurrWorksheetType: Option)
    begin
    end;

#if not CLEAN27
    [Obsolete('Replaced by OnBeforeSetParamAndCalculatePlanFromReqWorksheet', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetParamAndCalculatePlanFromWorksheet(UseForecast: Code[10]; ExcludeForecastBefore: Date; CurrWorksheetType: Option; PriceCalculationMethod: Enum "Price Calculation Method"; Item: Record Item; ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup"; CurrTemplateName: Code[10]; CurrWorksheetName: Code[10]; FromDate: Date; ToDate: Date; RespectPlanningParm: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetParamAndCalculatePlanFromReqWorksheet(UseForecast: Code[10]; ExcludeForecastBefore: Date; CurrWorksheetType: Option; PriceCalculationMethod: Enum "Price Calculation Method"; Item: Record Item; CurrTemplateName: Code[10]; CurrWorksheetName: Code[10]; FromDate: Date; ToDate: Date; RespectPlanningParm: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteReqLines(Item: Record Item; var PurchReqLine: Record "Requisition Line"; var ReqLineExtern: Record "Requisition Line"; var IsHandled: Boolean; InventoryProfileOffsetting: Codeunit "Inventory Profile Offsetting")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeFromSetup(var UseForecast: Code[10]; var IsHandled: Boolean; var InventorySetup: Record "Inventory Setup")
    begin
    end;

#if not CLEAN27
    [Obsolete('Replaced by event OnBeforeInitializeFromSetup', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeFromMfgSetup(var UseForecast: Code[10]; var IsHandled: Boolean; var MfgSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPreReport(var CurrTemplateName: code[10]; var CurrWorksheetName: Code[10]; var RequistionLine: Record "Requisition Line"; var FromDate: Date; var ToDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemOnAfterGetRecordOnBeforeCommit(var ReqLine: Record "Requisition Line"; var Item: Record Item; CurrTemplateName: Code[10]; CurrWorksheetName: Code[10]; FromDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemOnAfterDeleteReqLines(Item: Record Item; var SkipPlanning: Boolean)
    begin
    end;
}

