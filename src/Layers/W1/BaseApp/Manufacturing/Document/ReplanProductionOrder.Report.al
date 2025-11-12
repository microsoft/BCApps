// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;

report 99001026 "Replan Production Order"
{
    Caption = 'Replan Production Order';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.") where(Status = filter(.. Released));
            dataitem("Prod. Order Line"; "Prod. Order Line")
            {
                DataItemLink = Status = field(Status), "Prod. Order No." = field("No.");
                DataItemTableView = sorting(Status, "Prod. Order No.", "Planning Level Code");
                dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
                {
                    DataItemLink = Status = field(Status), "Prod. Order No." = field("Prod. Order No."), "Routing No." = field("Routing No.");
                    DataItemTableView = sorting(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");

                    trigger OnAfterGetRecord()
                    var
                        ProdOrderLine: Record "Prod. Order Line";
                        CalcProdOrderRtngLine: Codeunit "Calculate Routing Line";
                        PlanLevel: Integer;
                    begin
                        if "Routing Status" = "Routing Status"::Finished then
                            CurrReport.Skip();

                        PlanLevel := "Prod. Order Line"."Planning Level Code";

                        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Routing No.");
                        ProdOrderLine.SetRange(Status, Status);
                        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
                        ProdOrderLine.SetRange("Routing No.", "Routing No.");
                        if ProdOrderLine.Find('-') then
                            repeat
                                if PlanLevel < ProdOrderLine."Planning Level Code" then
                                    PlanLevel := ProdOrderLine."Planning Level Code";
                            until (ProdOrderLine.Next() = 0) or (PlanLevel > "Prod. Order Line"."Planning Level Code");

                        ProdOrderLine.Reset();

                        if PlanLevel = "Prod. Order Line"."Planning Level Code" then begin
                            if Direction = Direction::Forward then begin
                                "Starting Date" := "Prod. Order Line"."Starting Date";
                                "Starting Time" := "Prod. Order Line"."Starting Time";
                                Modify();
                            end else begin
                                "Ending Date" := "Prod. Order Line"."Ending Date";
                                "Ending Time" := "Prod. Order Line"."Ending Time";
                                Modify();
                            end;
                            CalcProdOrderRtngLine.ReplanRoutingLine("Prod. Order Routing Line", Direction, true);
                        end;
                        Modify();
                    end;

                    trigger OnPostDataItem()
                    begin
                        CalcProdOrder.CalculateProdOrderDates("Prod. Order Line", true);
                        OnAfterLastProdOrderRtngLine("Prod. Order Line");
                    end;

                    trigger OnPreDataItem()
                    begin
                        if Direction = Direction::Forward then
                            SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Sequence No. (Forward)")
                        else
                            SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Sequence No. (Backward)");
                    end;
                }
                dataitem("Prod. Order Component"; "Prod. Order Component")
                {
                    DataItemLink = Status = field(Status), "Prod. Order No." = field("Prod. Order No."), "Prod. Order Line No." = field("Line No.");
                    DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        TempSKU: Record "Stockkeeping Unit" temporary;
                        StockkeepingUnit: Record "Stockkeeping Unit";
                        CompItem: Record Item;
                        MainProdOrder: Record "Production Order";
                        ProdOrder: Record "Production Order";
                        ProdOrderLine: Record "Prod. Order Line";
                        AvailabilityMgt: Codeunit "Available Management";
                        CreateProdOrderLines: Codeunit "Create Prod. Order Lines";
                        GetPlanningParameters: Codeunit "Planning-Get Parameters";
                        InvtProfileOffsetting: Codeunit "Inventory Profile Offsetting";
                        ReqQty: Decimal;
                        WithInventory: Boolean;
                        UpdateProdOrder: Boolean;
                        IsHandled: Boolean;
                    begin
                        BlockDynamicTracking(true);
                        Validate("Routing Link Code");
                        Modify();

                        CalcFields("Reserved Qty. (Base)");
                        if "Reserved Qty. (Base)" = "Remaining Qty. (Base)" then
                            exit;

                        CompItem.Get("Item No.");

                        if CalcMethod = CalcMethod::"No Levels" then
                            CurrReport.Break();

                        CompItem.SetRange("Variant Filter", "Variant Code");
                        CompItem.SetRange("Location Filter", "Location Code");
                        CompItem.SetRange("Date Filter", 0D, "Due Date");

                        if StockkeepingUnit.Get("Location Code", "Item No.", "Variant Code") then
                            WithInventory := StockkeepingUnit."Include Inventory"
                        else
                            WithInventory := CompItem."Include Inventory";

                        if WithInventory then
                            CompItem.CalcFields(Inventory);

                        OnProdOrderCompOnBeforeCalcExpectedQtyOnHand("Prod. Order Component", CompItem, WithInventory);
                        AvailabilityMgt.ExpectedQtyOnHand(CompItem, true, 0, ReqQty, "Due Date");

                        if ReqQty >= 0 then
                            CurrReport.Skip();

                        ReqQty := Abs(ReqQty);
                        if ReqQty > "Remaining Qty. (Base)" then
                            ReqQty := "Remaining Qty. (Base)";

                        GetPlanningParameters.AtSKU(TempSKU, "Item No.", "Variant Code", "Location Code");
                        ReqQty += InvtProfileOffsetting.AdjustReorderQty(ReqQty, TempSKU, 0, 0);

                        if ReqQty = 0 then
                            CurrReport.Skip();

                        MainProdOrder.Get("Production Order".Status, "Prod. Order No.");

                        UpdateProdOrder := CompItem.IsMfgItem();
                        OnProdOrderCompOnAfterGetRecordOnAfterCalcUpdateProdOrder(CompItem, UpdateProdOrder);
                        if UpdateProdOrder then begin
                            ProdOrder.Status := MainProdOrder.Status;
                            ProdOrder."Replan Ref. No." := MainProdOrder."Replan Ref. No.";
                            ProdOrder."Replan Ref. Status" := MainProdOrder."Replan Ref. Status";
                            ProdOrder.Insert(true);

                            ProdOrder."Starting Date" := WorkDate();
                            ProdOrder."Creation Date" := WorkDate();
                            ProdOrder."Starting Time" := MfgSetup."Normal Starting Time";
                            ProdOrder."Ending Time" := MfgSetup."Normal Ending Time";
                            ProdOrder."Due Date" := "Due Date";
                            ProdOrder."Ending Date" := "Due Date";
                            ProdOrder."Low-Level Code" := MainProdOrder."Low-Level Code" + 1;
                            ProdOrder."Source Type" := ProdOrder."Source Type"::Item;
                            ProdOrder."Location Code" := "Location Code";
                            ProdOrder.Validate("Source No.", "Item No.");
                            ProdOrder.Validate(Quantity, ReqQty);
                            ProdOrder.Validate("Variant Code", "Variant Code");
                            OnProdOrderCompOnAfterGetRecordOnBeforeProdOrderModify(ProdOrder, MainProdOrder, "Prod. Order Component");
                            ProdOrder.Modify();

                            IsHandled := false;
                            OnProdOrderCompOnAfterGetRecordOnBeforeCreateProdOrderLines(ProdOrder, IsHandled);
                            if not IsHandled then
                                CreateProdOrderLines.Copy(ProdOrder, 1, "Variant Code", true);
                            ProdOrderLine.SetRange(Status, ProdOrder.Status);
                            ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
                            ProdOrderLine.Find('-');

                            Modify();
                            ProdOrderLine.Modify();

                            ProdOrderLine.SetRange(Status, Status);
                            ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");

                            if ProdOrderLine.Find('-') then
                                repeat
                                    CalcProdOrder.BlockDynamicTracking(true);
                                    CalcProdOrder.Recalculate(ProdOrderLine, 1, true);
                                until ProdOrderLine.Next() = 0;

                            Modify();
                        end;
                        ReservMgt.SetReservSource("Prod. Order Component");
                        ReservMgt.AutoTrack("Remaining Qty. (Base)");
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetFilter("Item No.", '<>%1', '');
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    Item: Record Item;
                    ProdOrderRouteMgt: Codeunit "Prod. Order Route Management";
                begin
                    BlockDynamicTracking(true);
                    Item.CheckItemAndVariantForProdBlocked("Prod. Order Line"."Item No.", "Prod. Order Line"."Variant Code", Item."Production Blocked"::Output);

                    if "Routing No." = '' then begin
                        CalcProdOrder.BlockDynamicTracking(true);
                        CalcProdOrder.Recalculate("Prod. Order Line", Direction, true);

                        Modify();
                    end else
                        ProdOrderRouteMgt.Calculate("Prod. Order Line");
                end;
            }

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
            begin
                if (CalcMethod = CalcMethod::"One level") and not First then
                    CurrReport.Break();

                Window.Update(1, Status);
                Window.Update(2, "No.");

                if "Production Order"."Source Type" = "Production Order"."Source Type"::Item then
                    Item.CheckItemAndVariantForProdBlocked("Production Order"."Source No.", "Production Order"."Variant Code", Item."Production Blocked"::Output);

                if "Replan Ref. No." = '' then begin
                    "Replan Ref. No." := "No.";
                    "Replan Ref. Status" := Status;
                    Modify();
                end;
                if First then begin
                    Reset();
                    SetRange("Replan Ref. No.", "Replan Ref. No.");
                    SetRange("Replan Ref. Status", "Replan Ref. Status");
                    First := false;
                    if CalcMethod <> CalcMethod::"No Levels" then
                        DeleteProdOrders("Production Order", "Low-Level Code", CalcMethod = CalcMethod::"All levels");
                end;

                DeleteUnreservedLowLevelProdOrderLines("Production Order");

                CreateProdOrderLines.CheckStructure(Status.AsInteger(), "No.", Direction, true, true);
            end;

            trigger OnPreDataItem()
            begin
                First := true;
                MfgSetup.Get();

                Window.Open(
                  Text000 +
                  Text001 +
                  Text002);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Direction; Direction)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Scheduling Direction';
                        OptionCaption = 'Forward,Back';
                        ToolTip = 'Specifies if you want the scheduling to be replanned forward or backward.';
                    }
                    field(CalcMethod; CalcMethod)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Plan';
                        OptionCaption = 'No Levels,One Level,All Levels';
                        ToolTip = 'Specifies whether the planning is to take place over one or all levels of the production BOM.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Direction := Direction::Backward;
        OnAfterInitReport();
    end;

    trigger OnPreReport()
    begin
        MfgSetup.Get();
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'Replanning Production Orders...\\';
#pragma warning disable AA0470
        Text001: Label 'Status         #1##########\';
        Text002: Label 'No.            #2##########';
#pragma warning restore AA0470
#pragma warning restore AA0074
        MfgSetup: Record "Manufacturing Setup";
        CalcProdOrder: Codeunit "Calculate Prod. Order";
        CreateProdOrderLines: Codeunit "Create Prod. Order Lines";
        ReservMgt: Codeunit "Reservation Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        Direction: Option Forward,Backward;
        CalcMethod: Option "No Levels","One level","All levels";
        First: Boolean;

    procedure InitializeRequest(NewDirection: Option; NewCalcMethod: Option)
    begin
        Direction := NewDirection;
        CalcMethod := NewCalcMethod;
    end;

    local procedure DeleteProdOrders(ProdOrder: Record "Production Order"; LowLevelCode: Integer; AllLevels: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if LowLevelCode > 99 then
            exit;

        ProdOrder.SetCurrentKey("Low-Level Code");
        ProdOrder.SetRange("Replan Ref. No.", ProdOrder."Replan Ref. No.");
        ProdOrder.SetRange("Replan Ref. Status", ProdOrder."Replan Ref. Status");
        ProdOrder.SetRange("Low-Level Code", LowLevelCode + 1);

        ProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderComponent.FindSet() then
            repeat
                ProdOrder.SetRange("Source No.", ProdOrderComponent."Item No.");
                if ProdOrder.FindFirst() then begin
                    if AllLevels then
                        DeleteProdOrders(ProdOrder, LowLevelCode + 1, AllLevels);
                    ProdOrder.Delete(true);
                end;
            until ProdOrderComponent.Next() = 0;
    end;

    local procedure DeleteUnreservedLowLevelProdOrderLines(ProdOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ExtReservedQtyBase: Decimal;
    begin
        ProdOrderLine.SetCalledFromComponent(true);
        ProdOrderLine.LockTable();
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderLine.Find('-') then
            repeat
                if ProdOrderLine."Planning Level Code" > 0 then begin
                    ProdOrderLine.CalcFields("Reserved Qty. (Base)");
                    if ProdOrderLine."Reserved Qty. (Base)" = 0 then
                        ProdOrderLine.Delete(true)
                    else begin
                        ExtReservedQtyBase := CalcQtyReservedFromExternalDemand(ProdOrderLine, Database::"Prod. Order Component");
                        ProdOrderLine.Validate(
                          Quantity,
                          UOMMgt.CalcQtyFromBase(
                            ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Unit of Measure Code", ExtReservedQtyBase, ProdOrderLine."Qty. per Unit of Measure"));
                        if ProdOrderLine.Quantity > 0 then
                            ProdOrderLine.Modify(true)
                        else
                            ProdOrderLine.Delete(true);
                    end;
                end;
            until ProdOrderLine.Next() = 0;
    end;

    local procedure CalcQtyReservedFromExternalDemand(ProdOrderLine: Record "Prod. Order Line"; SourceType: Integer) ReservedQtyBase: Decimal
    var
        ReservEntry: Record "Reservation Entry";
        ReservEntryFrom: Record "Reservation Entry";
    begin
        ReservedQtyBase := 0;

        ReservEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ProdOrderLine.SetReservationFilters(ReservEntry);

        if ReservEntry.FindSet() then
            repeat
                ReservEntryFrom.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
                if (ReservEntryFrom."Source Type" <> SourceType) or (ReservEntryFrom."Source ID" <> ProdOrderLine."Prod. Order No.") or
                   (ReservEntryFrom."Source Subtype" <> ProdOrderLine.Status.AsInteger())
                then
                    ReservedQtyBase += ReservEntry."Quantity (Base)";
            until ReservEntry.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLastProdOrderRtngLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderCompOnAfterGetRecordOnAfterCalcUpdateProdOrder(var CompItem: Record Item; var UpdateProdOrder: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderCompOnAfterGetRecordOnBeforeProdOrderModify(var ProdOrder: Record "Production Order"; MainProdOrder: Record "Production Order"; ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderCompOnAfterGetRecordOnBeforeCreateProdOrderLines(var ProdOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderCompOnBeforeCalcExpectedQtyOnHand(ProdOrderComponent: Record "Prod. Order Component"; var CompItem: Record Item; WithInventory: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitReport()
    begin
    end;
}

