// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

tableextension 99000751 "Mfg. Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(5401; "Prod. Order No."; Code[20])
        {
            AccessByPermission = TableData "Machine Center" = R;
            Caption = 'Prod. Order No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Production Order"."No." where(Status = const(Released));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                CheckDropShipment();
                ValidateProdOrderOnPurchLine();
            end;
        }
        field(99000750; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";
        }
        field(99000751; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                              "Prod. Order No." = field("Prod. Order No."),
                                                                              "Routing No." = field("Routing No."));

            trigger OnValidate()
            var
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
            begin
                if "Operation No." = '' then
                    exit;

                TestField(Type, Type::Item);
                TestField("Prod. Order No.");
                TestField("Routing No.");

                ProdOrderRtngLine.Get(
                  ProdOrderRtngLine.Status::Released,
                  "Prod. Order No.",
                  "Routing Reference No.",
                  "Routing No.",
                  "Operation No.");

                ProdOrderRtngLine.TestField(
                  Type,
                  ProdOrderRtngLine.Type::"Work Center");

                "Expected Receipt Date" := ProdOrderRtngLine."Ending Date";
                Validate("Work Center No.", ProdOrderRtngLine."No.");
                Validate("Direct Unit Cost", ProdOrderRtngLine."Direct Unit Cost");
            end;
        }
        field(99000752; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Work Center";

            trigger OnValidate()
            var
                GenProductPostingGroup: Record "Gen. Product Posting Group";
            begin
                if Type = Type::"Charge (Item)" then
                    TestField("Work Center No.", '');
                if "Work Center No." = '' then
                    exit;

                WorkCenter.Get("Work Center No.");
                "Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
                "VAT Prod. Posting Group" := '';
                if GenProductPostingGroup.ValidateVatProdPostingGroup(GenProductPostingGroup, "Gen. Prod. Posting Group") then
                    "VAT Prod. Posting Group" := GenProductPostingGroup."Def. VAT Prod. Posting Group";
                Validate("VAT Prod. Posting Group");

                "Overhead Rate" := WorkCenter."Overhead Rate";
                Validate("Indirect Cost %", WorkCenter."Indirect Cost %");

                CreateDimFromDefaultDim(Rec.FieldNo("Work Center No."));
            end;
        }
        field(99000753; Finished; Boolean)
        {
            Caption = 'Finished';
            DataClassification = CustomerContent;
        }
        field(99000754; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Prod. Order Line"."Line No." where(Status = filter(Released ..),
                                                                 "Prod. Order No." = field("Prod. Order No."));
        }
        field(99000759; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key8; "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.")
        {
        }
    }

    var
        WorkCenter: Record "Work Center";
        CannotChangeAssociatedLineErr: Label 'You cannot change %1 because the order line is associated with sales order %2.', Comment = '%1 - Prod. Order No., %2 - Sales Order No.';

    procedure CheckDropShipment()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDropShipment(IsHandled, Rec);
        if IsHandled then
            exit;

        if "Drop Shipment" then
            Error(CannotChangeAssociatedLineErr, FieldCaption("Prod. Order No."), "Sales Order No.");
    end;

    procedure ValidateProdOrderOnPurchLine()
    var
        Item: Record Item;
        ProdOrder: Record Microsoft.Manufacturing.Document."Production Order";
        ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line";
#if not CLEAN27
        AddonIntegrManagement: Codeunit Microsoft.Inventory.AddOnIntegrManagement;
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateProdOrderOnPurchLine(Rec, IsHandled);
#if not CLEAN27
        AddonIntegrManagement.RunOnBeforeValidateProdOrderOnPurchLine(Rec, IsHandled);
#endif
        if IsHandled then
            exit;

        TestField(Type, Type::Item);

        if ProdOrder.Get(ProdOrder.Status::Released, "Prod. Order No.") then begin
            ProdOrder.TestField(Blocked, false);
            ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
            ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderLine.SetRange("Item No.", "No.");
            if ProdOrderLine.FindFirst() then
                "Routing No." := ProdOrderLine."Routing No.";
            Item.Get("No.");
            Validate("Unit of Measure Code", Item."Base Unit of Measure");
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckDropShipment(var IsHandled: Boolean; var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateProdOrderOnPurchLine(var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    procedure TransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; ReqLine: Record "Requisition Line")
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        ManufacturingSetup: Record "Manufacturing Setup";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        CostCalculationManagement: Codeunit "Cost Calculation Management";
#if not CLEAN27
        AddonIntegrManagement: Codeunit Microsoft.Inventory.AddOnIntegrManagement;
#endif
        RndgSetupRead: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferFromReqLineToPurchLine(PurchOrderLine, ReqLine, IsHandled);
#if not CLEAN27
        AddonIntegrManagement.RunOnBeforeTransferFromReqLineToPurchLine(PurchOrderLine, ReqLine, IsHandled);
#endif
        if not IsHandled then begin
            PurchOrderLine."Routing No." := ReqLine."Routing No.";
            PurchOrderLine."Routing Reference No." := ReqLine."Routing Reference No.";
            PurchOrderLine."Operation No." := ReqLine."Operation No.";
            PurchOrderLine.Validate("Work Center No.", ReqLine."Work Center No.");
            if ReqLine."Prod. Order No." <> '' then
                if ReqLine."Work Center No." <> '' then begin
                    OnTransferFromReqLineToPurchLineOnBeforeBeforeAssignOverheadRate(WorkCenter, ReqLine."Order Date");
#if not CLEAN27
                    AddonIntegrManagement.RunOnTransferFromReqLineToPurchLineOnBeforeBeforeAssignOverheadRate(WorkCenter, ReqLine."Order Date");
#endif
                    WorkCenter.Get(PurchOrderLine."Work Center No.");
                    if WorkCenter."Unit Cost Calculation" = WorkCenter."Unit Cost Calculation"::Time then begin
                        ProdOrderRoutingLine.Get(
                          ProdOrderRoutingLine.Status::Released, ReqLine."Prod. Order No.", ReqLine."Routing Reference No.", ReqLine."Routing No.", ReqLine."Operation No.");
                        ManufacturingSetup.Get();
                        CostCalculationManagement.GetRndgSetup(GLSetup, Currency, RndgSetupRead);
                        if ManufacturingSetup."Cost Incl. Setup" and (ReqLine.Quantity <> 0) then
                            PurchOrderLine."Overhead Rate" :=
                              Round(
                                WorkCenter."Overhead Rate" *
                                (ProdOrderRoutingLine."Setup Time" /
                                 ReqLine.Quantity +
                                 ProdOrderRoutingLine."Run Time"),
                                GLSetup."Unit-Amount Rounding Precision")
                        else
                            PurchOrderLine."Overhead Rate" :=
                              Round(
                                WorkCenter."Overhead Rate" * ProdOrderRoutingLine."Run Time",
                                GLSetup."Unit-Amount Rounding Precision");
                    end else
                        PurchOrderLine."Overhead Rate" := WorkCenter."Overhead Rate";
                    PurchOrderLine."Indirect Cost %" := WorkCenter."Indirect Cost %";
                    PurchOrderLine."Gen. Prod. Posting Group" := WorkCenter."Gen. Prod. Posting Group";
                    PurchOrderLine.Validate("Direct Unit Cost", ReqLine."Direct Unit Cost");
                end;
        end;

        OnAfterTransferFromReqLineToPurchLine(PurchOrderLine, ReqLine);
#if not CLEAN27
        AddonIntegrManagement.RunOnAfterTransferFromReqLineToPurchLine(PurchOrderLine, ReqLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFromReqLineToPurchLine(var PurchOrderLine: Record "Purchase Line"; var ReqLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromReqLineToPurchLineOnBeforeBeforeAssignOverheadRate(var WordCenter: Record Microsoft.Manufacturing.WorkCenter."Work Center"; var OrderDate: Date)
    begin
    end;
}
