// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;

tableextension 99000829 "Mfg. Planning Component" extends "Planning Component"
{
    fields
    {
        field(19; "Routing Link Code"; Code[10])
        {
            Caption = 'Routing Link Code';
            DataClassification = CustomerContent;
            TableRelation = "Routing Link";

            trigger OnValidate()
            var
                PlanningRtngLine: Record "Planning Routing Line";
            begin
                if "Calculation Formula" = "Calculation Formula"::"Fixed Quantity" then
                    Validate("Expected Quantity", Quantity)
                else
                    UpdateExpectedQuantityForPlanningNeeds();

                "Due Date" := ReqLine."Starting Date";
                "Due Time" := ReqLine."Starting Time";
                if "Routing Link Code" <> '' then begin
                    PlanningRtngLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
                    PlanningRtngLine.SetRange("Worksheet Batch Name", "Worksheet Batch Name");
                    PlanningRtngLine.SetRange("Worksheet Line No.", "Worksheet Line No.");
                    PlanningRtngLine.SetRange("Routing Link Code", "Routing Link Code");
                    if PlanningRtngLine.FindFirst() then begin
                        "Due Date" := PlanningRtngLine."Starting Date";
                        "Due Time" := PlanningRtngLine."Starting Time";
                    end;
                end;
                if Format("Lead-Time Offset") <> '' then begin
                    if "Due Date" = 0D then
                        "Due Date" := ReqLine."Ending Date";
                    "Due Date" :=
                      "Due Date" -
                      (CalcDate("Lead-Time Offset", WorkDate()) - WorkDate());
                    "Due Time" := 0T;
                end;

                OnValidateRoutingLinkCodeOnBeforeValidateDueDate(Rec, ReqLine, PlanningRtngLine);
                Validate("Due Date");
            end;
        }
        field(20; "Scrap %"; Decimal)
        {
            BlankNumbers = BlankNeg;
            Caption = 'Scrap %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;

            trigger OnValidate()
            begin
                UpdateExpectedQuantityForPlanningNeeds();
            end;
        }
    }

    procedure PlanningNeeds(): Decimal
    var
        PlanningRtngLine: Record "Planning Routing Line";
        NeededQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePlanningNeeds(Rec, NeededQty, IsHandled);
        if IsHandled then
            exit(NeededQty);

        GetReqLine();

        "Due Date" := ReqLine."Starting Date";

        PlanningRtngLine.Reset();
        PlanningRtngLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", "Worksheet Batch Name");
        PlanningRtngLine.SetRange("Worksheet Line No.", "Worksheet Line No.");
        if "Routing Link Code" <> '' then
            PlanningRtngLine.SetRange("Routing Link Code", "Routing Link Code");
        if PlanningRtngLine.FindFirst() then
            NeededQty :=
              ReqLine.Quantity * (1 + ReqLine."Scrap %" / 100) *
              (1 + PlanningRtngLine."Scrap Factor % (Accumulated)") * (1 + "Scrap %" / 100) +
              PlanningRtngLine."Fixed Scrap Qty. (Accum.)"
        else
            if ReqLine."Replenishment System" = ReqLine."Replenishment System"::Assembly then
                NeededQty := ReqLine.Quantity
            else
                NeededQty := ReqLine.Quantity * (1 + ReqLine."Scrap %" / 100) * (1 + "Scrap %" / 100);

        OnAfterPlanningNeeds(Rec, ReqLine, PlanningRtngLine, NeededQty);
        exit(NeededQty);
    end;

    procedure TransferFromComponent(var ProdOrderComp: Record "Prod. Order Component")
    begin
        "Ref. Order Type" := "Ref. Order Type"::"Prod. Order";
        "Ref. Order Status" := ProdOrderComp.Status;
        "Ref. Order No." := ProdOrderComp."Prod. Order No.";
        "Ref. Order Line No." := ProdOrderComp."Prod. Order Line No.";
        "Line No." := ProdOrderComp."Line No.";
        "Item No." := ProdOrderComp."Item No.";
        Description := ProdOrderComp.Description;
        "Unit of Measure Code" := ProdOrderComp."Unit of Measure Code";
        "Quantity per" := ProdOrderComp."Quantity per";
        Quantity := ProdOrderComp.Quantity;
        Position := ProdOrderComp.Position;
        "Position 2" := ProdOrderComp."Position 2";
        "Position 3" := ProdOrderComp."Position 3";
        "Lead-Time Offset" := ProdOrderComp."Lead-Time Offset";
        "Routing Link Code" := ProdOrderComp."Routing Link Code";
        "Scrap %" := ProdOrderComp."Scrap %";
        "Variant Code" := ProdOrderComp."Variant Code";
        "Expected Quantity" := ProdOrderComp."Expected Quantity";
        "Location Code" := ProdOrderComp."Location Code";
        "Dimension Set ID" := ProdOrderComp."Dimension Set ID";
        "Shortcut Dimension 1 Code" := ProdOrderComp."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := ProdOrderComp."Shortcut Dimension 2 Code";
        "Bin Code" := ProdOrderComp."Bin Code";
        Length := ProdOrderComp.Length;
        Width := ProdOrderComp.Width;
        Weight := ProdOrderComp.Weight;
        Depth := ProdOrderComp.Depth;
        "Calculation Formula" := ProdOrderComp."Calculation Formula";
        "Planning Level Code" := ProdOrderComp."Planning Level Code";
        "Unit Cost" := ProdOrderComp."Unit Cost";
        "Cost Amount" := ProdOrderComp."Cost Amount";
        "Due Date" := ProdOrderComp."Due Date";
        "Direct Unit Cost" := ProdOrderComp."Direct Unit Cost";
        "Indirect Cost %" := ProdOrderComp."Indirect Cost %";
        "Overhead Rate" := ProdOrderComp."Overhead Rate";
        "Direct Cost Amount" := ProdOrderComp."Direct Cost Amount";
        "Overhead Amount" := ProdOrderComp."Overhead Amount";
        "Qty. per Unit of Measure" := ProdOrderComp."Qty. per Unit of Measure";
        "Qty. Rounding Precision" := ProdOrderComp."Qty. Rounding Precision";
        "Qty. Rounding Precision (Base)" := ProdOrderComp."Qty. Rounding Precision (Base)";
        "Quantity (Base)" := ProdOrderComp."Quantity (Base)";
        "Expected Quantity (Base)" := ProdOrderComp."Expected Qty. (Base)";
        "Original Expected Qty. (Base)" := ProdOrderComp."Expected Qty. (Base)";
        UpdateDatetime();

        OnAfterTransferFromComponent(Rec, ProdOrderComp);
    end;

    local procedure FindFirstRtngLine(var PlanningRoutingLine: Record "Planning Routing Line"; ReqLine: Record "Requisition Line"): Boolean
    begin
        PlanningRoutingLine.Reset();
        PlanningRoutingLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", ReqLine."Line No.");
        PlanningRoutingLine.SetFilter("No.", '<>%1', '');
        PlanningRoutingLine.SetRange("Previous Operation No.", '');
        if "Routing Link Code" <> '' then begin
            PlanningRoutingLine.SetRange("Routing Link Code", "Routing Link Code");
            PlanningRoutingLine.SetRange("Previous Operation No.");
            if PlanningRoutingLine.Count = 0 then begin
                PlanningRoutingLine.SetRange("Routing Link Code");
                PlanningRoutingLine.SetRange("Previous Operation No.", '');
            end;
        end;

        exit(PlanningRoutingLine.FindFirst());
    end;

    procedure GetRefOrderTypeBin() BinCode: Code[20]
    var
        PlanningRoutingLine: Record "Planning Routing Line";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRefOrderTypeBin(Rec, ReqLine, Location, BinCode, IsHandled);
        if IsHandled then
            exit;

        case ReqLine."Ref. Order Type" of
            ReqLine."Ref. Order Type"::"Prod. Order":
                begin
                    if "Location Code" = ReqLine."Location Code" then
                        if FindFirstRtngLine(PlanningRoutingLine, ReqLine) then
                            BinCode :=
                                ProdOrderWarehouseMgt.GetProdCenterBinCode(
                                    PlanningRoutingLine.Type, PlanningRoutingLine."No.", "Location Code", true, "Flushing Method");
                    OnGetRefOrderTypeBinOnAfterGetBinCodeFromRoutingLine(Rec, PlanningRoutingLine, ReqLine, BinCode);
                    if BinCode <> '' then
                        exit(BinCode);
                    BinCode := GetFlushingMethodBin();
                end;
            ReqLine."Ref. Order Type"::Assembly:
                BinCode := Location."To-Assembly Bin Code";
        end;
    end;

    local procedure GetFlushingMethodBin(): Code[20]
#if not CLEAN26
    var
        ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
#endif
    begin
#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            case "Flushing Method" of
                "Flushing Method"::Manual,
                "Flushing Method"::"Pick + Manual",
                "Flushing Method"::"Pick + Forward",
                "Flushing Method"::"Pick + Backward":
                    exit(Location."To-Production Bin Code");
                "Flushing Method"::Forward,
                "Flushing Method"::Backward:
                    exit(Location."Open Shop Floor Bin Code");
            end
        else
#endif
        case "Flushing Method" of
            "Flushing Method"::"Pick + Manual",
            "Flushing Method"::"Pick + Forward",
            "Flushing Method"::"Pick + Backward":
                exit(Location."To-Production Bin Code");
            "Flushing Method"::Manual,
            "Flushing Method"::Forward,
            "Flushing Method"::Backward:
                exit(Location."Open Shop Floor Bin Code");
            end;
    end;

    procedure UpdateExpectedQuantityForPlanningNeeds()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateExpectedQuantityForPlanningNeeds(Rec, IsHandled);
        if IsHandled then
            exit;

        Validate("Expected Quantity", Quantity * PlanningNeeds());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPlanningNeeds(PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line"; PlanningRoutingLine: Record "Planning Routing Line"; var NeededQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromComponent(var PlanningComponent: Record "Planning Component"; var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRoutingLinkCodeOnBeforeValidateDueDate(var PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line"; var PlanningRoutingLine: Record "Planning Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRefOrderTypeBin(PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line"; Location: Record Location; var BinCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRefOrderTypeBinOnAfterGetBinCodeFromRoutingLine(var PlanningComponent: Record "Planning Component"; var PlanningRoutingLine: Record "Planning Routing Line"; var RequisitionLine: Record "Requisition Line"; var BinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePlanningNeeds(var PlanningComponent: Record "Planning Component"; var NeededQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateExpectedQuantityForPlanningNeeds(var PlanningComponent: Record "Planning Component"; var IsHandled: Boolean)
    begin
    end;
}
