// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using System.Utilities;

report 99001025 "Refresh Production Order"
{
    Caption = 'Refresh Production Order';
    ProcessingOnly = true;
    TransactionType = Update;

    dataset
    {
        dataitem("Production Order"; "Production Order")
        {
            DataItemTableView = sorting(Status, "No.");
            RequestFilterFields = Status, "No.";

            trigger OnAfterGetRecord()
            var
                ProductionOrder: Record "Production Order";
                ProdOrderLine: Record "Prod. Order Line";
                ProdOrderRoutingLine: Record "Prod. Order Routing Line";
                ProdOrderComponent: Record "Prod. Order Component";
                ProdOrderStatusManagement: Codeunit "Prod. Order Status Management";
                WhseProductionRelease: Codeunit "Whse.-Production Release";
                WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
                ConfirmManagement: Codeunit "Confirm Management";
                RoutingNo: Code[20];
                ErrorOccured: Boolean;
                IsHandled: Boolean;
                Confirmed: Boolean;
            begin
                if Status = Status::Finished then
                    CurrReport.Skip();

                TestField("Due Date");

                if CalcLines then
                    if IsComponentPicked("Production Order") then begin
                        IsHandled := false;
                        OnProductionOrderOnAfterGetRecordOnBeforeAlreadyPickedLinesConfirm("Production Order", HideValidationDialog, Confirmed, IsHandled);
                        if not IsHandled then
                            if HideValidationDialog then
                                Confirmed := true
                            else
                                Confirmed := ConfirmManagement.GetResponseOrDefault(StrSubstNo(AlreadyPickedLinesQst, "No."), false);

                        if not Confirmed then
                            CurrReport.Skip();
                    end;

                if not HideValidationDialog then begin
                    ProgressDialog.Update(1, Status);
                    ProgressDialog.Update(2, "No.");
                end;

                RoutingNo := GetRoutingNo("Production Order");
                UpdateRoutingNo("Production Order", RoutingNo);

                ProdOrderLine.LockTable();
                OnBeforeCalcProdOrder("Production Order", Direction);
                CheckReservationExist();

                if CalcLines then begin
                    OnBeforeCalcProdOrderLines("Production Order", Direction, CalcLines, CalcRoutings, CalcComponents, IsHandled, ErrorOccured);
                    if not IsHandled then
                        if not CreateProdOrderLines.Copy("Production Order", Direction, "Production Order"."Variant Code", false) then
                            ErrorOccured := true;
                end else begin
                    ProdOrderLine.SetRange(Status, Status);
                    ProdOrderLine.SetRange("Prod. Order No.", "No.");
                    IsHandled := false;
                    OnBeforeCalcRoutingsOrComponents("Production Order", ProdOrderLine, CalcComponents, CalcRoutings, IsHandled);
                    if not IsHandled then
                        if CalcRoutings or CalcComponents then begin
                            if ProdOrderLine.Find('-') then
                                repeat
                                    if CalcRoutings then begin
                                        ProdOrderRoutingLine.SetRange(Status, Status);
                                        ProdOrderRoutingLine.SetRange("Prod. Order No.", "No.");
                                        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                                        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                                        if ProdOrderRoutingLine.FindSet(true) then
                                            repeat
                                                ProdOrderRoutingLine.SetSkipUpdateOfCompBinCodes(true);
                                                ProdOrderRoutingLine.Delete(true);
                                            until ProdOrderRoutingLine.Next() = 0;
                                    end;
                                    if CalcComponents then begin
                                        ProdOrderComponent.SetRange(Status, Status);
                                        ProdOrderComponent.SetRange("Prod. Order No.", "No.");
                                        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                                        ProdOrderComponent.DeleteAll(true);
                                    end;
                                until ProdOrderLine.Next() = 0;
                            if ProdOrderLine.Find('-') then
                                repeat
                                    if CalcComponents then
                                        CheckProductionBOMStatus(ProdOrderLine."Production BOM No.", ProdOrderLine."Production BOM Version Code");
                                    if CalcRoutings then
                                        CheckRoutingStatus(ProdOrderLine."Routing No.", ProdOrderLine."Routing Version Code");
                                    ProdOrderLine."Due Date" := "Due Date";
                                    IsHandled := false;
                                    OnBeforeCalcProdOrderLine(ProdOrderLine, Direction, CalcLines, CalcRoutings, CalcComponents, IsHandled, ErrorOccured);
                                    if not IsHandled then
                                        if not CalculateProdOrder.Calculate(ProdOrderLine, Direction, CalcRoutings, CalcComponents, false, false) then
                                            ErrorOccured := true;
                                until ProdOrderLine.Next() = 0;
                        end;
                end;
                OnProductionOrderOnAfterGetRecordOnAfterCalcRoutingsOrComponents("Production Order", CalcLines, CalcRoutings, CalcComponents, ErrorOccured);

                if (Direction = Direction::Backward) and ("Source Type" = "Source Type"::Family) then begin
                    SetUpdateEndDate();
                    Validate("Due Date", "Due Date");
                end;

                if Status = Status::Released then begin
                    ProdOrderStatusManagement.FlushProdOrder("Production Order", Status, WorkDate());
                    WhseProductionRelease.Release("Production Order");
                    if CreateInbRqst then
                        WhseOutputProdRelease.Release("Production Order");
                end;

                OnAfterRefreshProdOrder("Production Order", ErrorOccured);
                if ErrorOccured then
                    Message(SpecialWarehouseHandlingRequiredErr, ProductionOrder.TableCaption(), ProdOrderLine.FieldCaption("Bin Code"));
            end;

            trigger OnPreDataItem()
            begin
                if not HideValidationDialog then
                    ProgressDialog.Open(
                      ProcessingProgressTxt +
                      ProcessingProductionOrderStatusLbl +
                      ProcessingProductionOrderNoLbl);
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
                        Caption = 'Scheduling direction';
                        OptionCaption = 'Forward,Back';
                        ToolTip = 'Specifies whether you want the scheduling to be refreshed forward or backward.';
                    }
                    group(Calculate)
                    {
                        Caption = 'Calculate';
                        field(CalcLines; CalcLines)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Lines';
                            ToolTip = 'Specifies if you want to calculate the production order lines based on value of the Source No. field. If you use the Refresh function to recalculate production order lines, the old production order lines are deleted and new lines are calculated. If disabled, non-top-level lines in a Make-to-order environment will be deleted; use the Replan function to restore them.';

                            trigger OnValidate()
                            begin
                                if CalcLines then begin
                                    CalcRoutings := true;
                                    CalcComponents := true;
                                end;
                            end;
                        }
                        field(CalcRoutings; CalcRoutings)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Routings';
                            ToolTip = 'Specifies if you want the program to calculate the routing.';

                            trigger OnValidate()
                            begin
                                if not CalcRoutings then
                                    if CalcLines then
                                        Error(RoutingsMustBeCalculatedErr);
                            end;
                        }
                        field(CalcComponents; CalcComponents)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Component Need';
                            ToolTip = 'Specifies if you want the program to calculate the component requirement.';

                            trigger OnValidate()
                            begin
                                if not CalcComponents then
                                    if CalcLines then
                                        Error(ComponentNeedMustBeCalculatedErr);
                            end;
                        }
                    }
                    group(Warehouse)
                    {
                        Caption = 'Warehouse';
                        field(CreateInbRqst; CreateInbRqst)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Create Inbound Request';
                            ToolTip = 'Specifies if you want to create an inbound request when calculating and updating a production order.';
                        }
                    }
                }
            }
        }

        trigger OnInit()
        begin
            CalcLines := true;
            CalcRoutings := true;
            CalcComponents := true;

            OnAfterOnInit(Direction, CalcLines, CalcRoutings, CalcComponents, CreateInbRqst, HideValidationDialog);
        end;
    }

    trigger OnInitReport()
    begin
        Direction := Direction::Backward;
        if not GuiAllowed() then
            SetHideValidationDialog(true);

        OnAfterInitReport();
    end;

    var
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
        CreateProdOrderLines: Codeunit "Create Prod. Order Lines";
#pragma warning disable AA0204
        Direction: Option Forward,Backward;
        CalcLines: Boolean;
        CalcRoutings: Boolean;
        CalcComponents: Boolean;
        CreateInbRqst: Boolean;
#pragma warning restore AA0204
        HideValidationDialog: Boolean;
        ProgressDialog: Dialog;
        ProcessingProgressTxt: Label 'Refreshing Production Orders...\\';
        ProcessingProductionOrderStatusLbl: Label 'Status         #1##########\', Comment = '%1 = Production Order Status';
        ProcessingProductionOrderNoLbl: Label 'No.            #2##########', Comment = '%1 = Production Order No.';
        RoutingsMustBeCalculatedErr: Label 'Routings must be calculated, when lines are calculated.';
        ComponentNeedMustBeCalculatedErr: Label 'Component Need must be calculated, when lines are calculated.';
        SpecialWarehouseHandlingRequiredErr: Label 'One or more of the lines on this %1 require special warehouse handling. The %2 for these lines has been set to blank.', Comment = '%1 = Production Order caption, %2 = Bin Code';
        AlreadyPickedLinesQst: Label 'Components for production order %1 have already been picked. Do you want to continue?', Comment = '%1 = Production Order No.; Example: Components for production order 101001 have already been picked. Do you want to continue?';

    local procedure CheckReservationExist()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Not allowed to refresh if reservations exist
        if not (CalcLines or CalcComponents) then
            exit;

        ProdOrderLine.SetRange(Status, "Production Order".Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Production Order"."No.");
        if ProdOrderLine.Find('-') then
            repeat
                if CalcLines then begin
                    ProdOrderLine.CalcFields("Reserved Qty. (Base)");
                    if ProdOrderLine."Reserved Qty. (Base)" <> 0 then
                        if ShouldCheckReservedQty(
                             ProdOrderLine."Prod. Order No.", 0, Database::"Prod. Order Line",
                             ProdOrderLine.Status, ProdOrderLine."Line No.", Database::"Prod. Order Component")
                        then
                            ProdOrderLine.TestField("Reserved Qty. (Base)", 0);
                end;

                if CalcComponents then begin
                    ProdOrderComponent.SetRange(Status, ProdOrderLine.Status);
                    ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                    ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                    ProdOrderComponent.SetAutoCalcFields("Reserved Qty. (Base)");
                    if ProdOrderComponent.Find('-') then
                        repeat
                            OnCheckReservationExistOnBeforeCheckProdOrderComp2ReservedQtyBase(ProdOrderComponent);
                            if ProdOrderComponent."Reserved Qty. (Base)" <> 0 then
                                if ShouldCheckReservedQty(
                                     ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Line No.",
                                     Database::"Prod. Order Component", ProdOrderComponent.Status,
                                     ProdOrderComponent."Prod. Order Line No.", Database::"Prod. Order Line")
                                then
                                    ProdOrderComponent.TestField("Reserved Qty. (Base)", 0);
                        until ProdOrderComponent.Next() = 0;
                end;
            until ProdOrderLine.Next() = 0;
    end;

    local procedure ShouldCheckReservedQty(ProductionOrderNo: Code[20]; LineNo: Integer; SourceType: Integer; ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderLineNo: Integer; ReservationSourceType: Integer): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetSourceFilter(SourceType, ProductionOrderStatus.AsInteger(), ProductionOrderNo, LineNo, true);
        ReservationEntry.SetSourceFilter('', ProductionOrderLineNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetLoadFields("Source Type", "Source ID", "Source Subtype");
        if ReservationEntry.FindFirst() then begin
            ReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
            exit(
              not ((ReservationEntry."Source Type" = ReservationSourceType) and
                   (ReservationEntry."Source ID" = ProductionOrderNo) and (ReservationEntry."Source Subtype" = ProductionOrderStatus.AsInteger())));
        end;

        exit(false);
    end;

    local procedure UpdateRoutingNo(var ProductionOrder: Record "Production Order"; RoutingNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRoutingNo("Production Order", RoutingNo, IsHandled, CalcLines, CalcComponents, CalcRoutings);
        if IsHandled then
            exit;

        if RoutingNo <> ProductionOrder."Routing No." then begin
            ProductionOrder."Routing No." := RoutingNo;
            ProductionOrder.Modify();
        end;
    end;

    local procedure CheckProductionBOMStatus(ProductionBOMNo: Code[20]; ProductionBOMVersionNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        if ProductionBOMNo = '' then
            exit;

        if ProductionBOMVersionNo = '' then begin
            ProductionBOMHeader.SetLoadFields(Status);
            ProductionBOMHeader.Get(ProductionBOMNo);
            ProductionBOMHeader.TestField(Status, ProductionBOMHeader.Status::Certified);
        end else begin
            ProductionBOMVersion.SetLoadFields(Status);
            ProductionBOMVersion.Get(ProductionBOMNo, ProductionBOMVersionNo);
            ProductionBOMVersion.TestField(Status, ProductionBOMVersion.Status::Certified);
        end;
    end;

    local procedure CheckRoutingStatus(RoutingNo: Code[20]; RoutingVersionNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
    begin
        if RoutingNo = '' then
            exit;

        if RoutingVersionNo = '' then begin
            RoutingHeader.SetLoadFields(Status);
            RoutingHeader.Get(RoutingNo);
            RoutingHeader.TestField(Status, RoutingHeader.Status::Certified);
        end else begin
            RoutingVersion.SetLoadFields(Status);
            RoutingVersion.Get(RoutingNo, RoutingVersionNo);
            RoutingVersion.TestField(Status, RoutingVersion.Status::Certified);
        end;
    end;

    procedure InitializeRequest(Direction2: Option Forward,Backward; CalcLines2: Boolean; CalcRoutings2: Boolean; CalcComponents2: Boolean; CreateInbRqst2: Boolean)
    begin
        Direction := Direction2;
        CalcLines := CalcLines2;
        CalcRoutings := CalcRoutings2;
        CalcComponents := CalcComponents2;
        CreateInbRqst := CreateInbRqst2;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure IsComponentPicked(ProductionOrder: Record "Production Order"): Boolean
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetFilter("Qty. Picked", '<>0');
        exit(not ProdOrderComponent.IsEmpty());
    end;

    local procedure GetRoutingNo(ProductionOrder: Record "Production Order") RoutingNo: Code[20]
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        Family: Record Family;
    begin
        RoutingNo := ProductionOrder."Routing No.";
        case ProductionOrder."Source Type" of
            ProductionOrder."Source Type"::Item:
                begin
                    Item.SetLoadFields("Routing No.");
                    if Item.Get(ProductionOrder."Source No.") then
                        RoutingNo := Item."Routing No.";
                    StockkeepingUnit.SetLoadFields("Routing No.");
                    if StockkeepingUnit.Get(ProductionOrder."Location Code", ProductionOrder."Source No.", ProductionOrder."Variant Code") and
                        (StockkeepingUnit."Routing No." <> '')
                    then
                        RoutingNo := StockkeepingUnit."Routing No.";
                end;
            ProductionOrder."Source Type"::Family:
                begin
                    Family.SetLoadFields("Routing No.");
                    if Family.Get(ProductionOrder."Source No.") then
                        RoutingNo := Family."Routing No.";
                end;
        end;

        OnAfterGetRoutingNo(ProductionOrder, RoutingNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRoutingNo(var ProductionOrder: Record "Production Order"; var RoutingNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRefreshProdOrder(var ProductionOrder: Record "Production Order"; ErrorOccured: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInit(var Direction: Option; var CalcLines: Boolean; var CalcRoutings: Boolean; var CalcComponents: Boolean; var CreateInbRqst: Boolean; var HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdOrder(var ProductionOrder: Record "Production Order"; Direction: Option Forward,Backward)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var Direction: Option Forward,Backward; CalcLines: Boolean; CalcRoutings: Boolean; CalcComponents: Boolean; var IsHandled: Boolean; var ErrorOccured: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcProdOrderLines(var ProductionOrder: Record "Production Order"; Direction: Option Forward,Backward; CalcLines: Boolean; CalcRoutings: Boolean; CalcComponents: Boolean; var IsHandled: Boolean; var ErrorOccured: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRoutingsOrComponents(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var CalcComponents: Boolean; var CalcRoutings: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRoutingNo(var ProductionOrder: Record "Production Order"; RoutingNo: Code[20]; var IsHandled: Boolean; var CalcLines: Boolean; var CalcComponents: Boolean; var CalcRoutings: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckReservationExistOnBeforeCheckProdOrderComp2ReservedQtyBase(var ProdOrderComp2: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitReport()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProductionOrderOnAfterGetRecordOnAfterCalcRoutingsOrComponents(var ProductionOrder: Record "Production Order"; CalcLines: Boolean; CalcRoutings: Boolean; CalcComponents: Boolean; var ErrorOccured: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProductionOrderOnAfterGetRecordOnBeforeAlreadyPickedLinesConfirm(var ProductionOrder: Record "Production Order"; HideValidationDialog: Boolean; var Confirmed: Boolean; var IsHandled: Boolean)
    begin
    end;
}

