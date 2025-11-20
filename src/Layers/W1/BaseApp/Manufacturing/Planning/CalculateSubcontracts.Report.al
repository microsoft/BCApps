// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Planning;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;

report 99001015 "Calculate Subcontracts"
{
    Caption = 'Calculate Subcontracts';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Work Center"; "Work Center")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Subcontractor No.";
            dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting(Type, "No.") where(Status = const(Released), Type = const("Work Center"), "Routing Status" = filter(< Finished));
                RequestFilterFields = "Prod. Order No.", "Starting Date";

                trigger OnAfterGetRecord()
                begin
                    TempProdOrderRoutingLine.Init();
                    TempProdOrderRoutingLine := "Prod. Order Routing Line";
                    TempProdOrderRoutingLine.Insert();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Subcontractor No." = '' then
                    CurrReport.Skip();

                Window.Update(1, "No.");
            end;

            trigger OnPreDataItem()
            begin
                TempProdOrderRoutingLine.DeleteAll();
                ReqLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
                ReqLine.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
                ReqLine.DeleteAll();
            end;

            trigger OnPostDataItem()
            begin
                CalculateSubContractRequirements();
            end;
        }
    }

    requestpage
    {

        layout
        {
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
        MfgSetup.Get();
    end;

    trigger OnPreReport()
    begin
        ReqWkshTmpl.Get(ReqLine."Worksheet Template Name");
        ReqWkShName.Get(ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name");
        ReqLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        ReqLine.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
        ReqLine.LockTable();

        if ReqLine.FindLast() then
            ReqLine.Init();

        Window.Open(Text000 + Text001);
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        ReqWkshTmpl: Record "Req. Wksh. Template";
        ReqWkShName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        ProdOrderLine: Record "Prod. Order Line";
        GLSetup: Record "General Ledger Setup";
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        BaseQtyToPurch: Decimal;
        QtyToPurch: Decimal;
        GLSetupRead: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Processing Work Centers   #1##########\';
        Text001: Label 'Processing Orders         #2########## ';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ProductionBlockedOutputItemQst: Label 'Item %1 is blocked for production output and cannot be calculated. Do you want to continue?', Comment = '%1 Item No.';
        ProductionBlockedOutputItemVariantQst: Label 'Variant %1 for item %2 is blocked for production output and cannot be calculated. Do you want to continue?', Comment = '%1 - Item Variant Code, %2 - Item No.';

    procedure SetWkShLine(NewReqLine: Record "Requisition Line")
    begin
        ReqLine := NewReqLine;
    end;

    local procedure InsertReqWkshLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        WorkCenter: Record "Work Center";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        if ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center" then
            WorkCenter.Get(ProdOrderRoutingLine."No.");
        OnBeforeInsertReqWkshLine(ProdOrderRoutingLine, WorkCenter, ReqLine, IsHandled, ProdOrderLine);
        if IsHandled then
            exit;

        ProdOrderLine.CalcFields("Total Exp. Oper. Output (Qty.)");

        ReqLine.SetSubcontracting(true);
        ReqLine.BlockDynamicTracking(true);

        if not CanCreateRequisitionLineFromProdOrderLine(ProdOrderLine."Item No.", ProdOrderLine."Variant Code") then
            exit;

        ReqLine.Init();
        ReqLine."Line No." := ReqLine."Line No." + 10000;
        ReqLine.Validate(Type, ReqLine.Type::Item);
        ReqLine.Validate("No.", ProdOrderLine."Item No.");
        ReqLine.Validate("Variant Code", ProdOrderLine."Variant Code");
        ReqLine.Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        ReqLine.Validate(Quantity, QtyToPurch);
        GetGLSetup();
        IsHandled := false;
        OnBeforeValidateUnitCost(ReqLine, WorkCenter, IsHandled, ProdOrderLine, ProdOrderRoutingLine);
        if not IsHandled then
            if ReqLine.Quantity <> 0 then begin
                if WorkCenter."Unit Cost Calculation" = WorkCenter."Unit Cost Calculation"::Units then
                    ReqLine.Validate(
                        ReqLine."Direct Unit Cost",
                        Round(
                            ProdOrderRoutingLine."Direct Unit Cost" * ProdOrderLine."Qty. per Unit of Measure",
                            GLSetup."Unit-Amount Rounding Precision"))
                else
                    ReqLine.Validate(
                        ReqLine."Direct Unit Cost",
                        Round(
                            (ProdOrderRoutingLine."Expected Operation Cost Amt." - ProdOrderRoutingLine."Expected Capacity Ovhd. Cost") /
                            ProdOrderLine."Total Exp. Oper. Output (Qty.)",
                            GLSetup."Unit-Amount Rounding Precision"));
            end else
                ReqLine.Validate(ReqLine."Direct Unit Cost", 0);
        ReqLine."Qty. per Unit of Measure" := 0;
        ReqLine."Quantity (Base)" := 0;
        ReqLine."Qty. Rounding Precision" := ProdOrderLine."Qty. Rounding Precision";
        ReqLine."Qty. Rounding Precision (Base)" := ProdOrderLine."Qty. Rounding Precision (Base)";
        ReqLine."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        ReqLine."Prod. Order Line No." := ProdOrderLine."Line No.";
        ReqLine."Due Date" := ProdOrderRoutingLine."Ending Date";
        ReqLine."Requester ID" := CopyStr(UserId(), 1, 50);
        ReqLine."Location Code" := ProdOrderLine."Location Code";
        ReqLine."Bin Code" := ProdOrderLine."Bin Code";
        ReqLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        ReqLine."Routing No." := ProdOrderRoutingLine."Routing No.";
        ReqLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        ReqLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        ReqLine.Validate(ReqLine."Vendor No.", WorkCenter."Subcontractor No.");
        ReqLine.Description := ProdOrderRoutingLine.Description;
        SetVendorItemNo();
        OnAfterTransferProdOrderRoutingLine(ReqLine, ProdOrderRoutingLine);
        // If purchase order already exist we will change this if possible
        PurchLine.Reset();
        PurchLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        PurchLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        PurchLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchLine.SetRange("Planning Flexibility", PurchLine."Planning Flexibility"::Unlimited);
        PurchLine.SetRange("Quantity Received", 0);
        if PurchLine.FindFirst() then begin
            ReqLine.Validate(ReqLine.Quantity, ReqLine.Quantity + PurchLine."Outstanding Quantity");
            ReqLine."Quantity (Base)" := 0;
            ReqLine."Replenishment System" := ReqLine."Replenishment System"::Purchase;
            ReqLine."Ref. Order No." := PurchLine."Document No.";
            ReqLine."Ref. Order Type" := ReqLine."Ref. Order Type"::Purchase;
            ReqLine."Ref. Line No." := PurchLine."Line No.";
            if PurchLine."Expected Receipt Date" = ReqLine."Due Date" then
                ReqLine."Action Message" := ReqLine."Action Message"::"Change Qty."
            else
                ReqLine."Action Message" := ReqLine."Action Message"::"Resched. & Chg. Qty.";
            ReqLine."Accept Action Message" := true;
        end else begin
            ReqLine."Replenishment System" := ReqLine."Replenishment System"::"Prod. Order";
            ReqLine."Ref. Order No." := ProdOrderLine."Prod. Order No.";
            ReqLine."Ref. Order Type" := ReqLine."Ref. Order Type"::"Prod. Order";
            ReqLine."Ref. Order Status" := ProdOrderLine.Status;
            ReqLine."Ref. Line No." := ProdOrderLine."Line No.";
            ReqLine."Action Message" := ReqLine."Action Message"::New;
            ReqLine."Accept Action Message" := true;
        end;

        if ReqLine."Ref. Order No." <> '' then
            ReqLine.GetDimFromRefOrderLine(true);

        OnBeforeReqWkshLineInsert(ReqLine, ProdOrderLine);
        ReqLine.Insert();
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure DeleteRepeatedReqLines(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ProdOrderLine."Item No.");
        RequisitionLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        RequisitionLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        RequisitionLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        OnDeleteRepeatedReqLinesOnAfterRequisitionLineSetFilters(RequisitionLine, ProdOrderLine, ProdOrderRoutingLine);
        RequisitionLine.DeleteAll(true);
    end;

    local procedure SetVendorItemNo()
    var
        ItemVendor: Record "Item Vendor";
    begin
        if ReqLine."No." = '' then
            exit;

        if Item."No." <> ReqLine."No." then begin
            Item.SetLoadFields("No.");
            Item.Get(ReqLine."No.");
        end;

        ItemVendor.Init();
        ItemVendor."Vendor No." := ReqLine."Vendor No.";
        ItemVendor."Variant Code" := ReqLine."Variant Code";
        Item.FindItemVend(ItemVendor, ReqLine."Location Code");
        ReqLine.Validate("Vendor Item No.", ItemVendor."Vendor Item No.");
        OnAfterSetVendorItemNo(ReqLine, ItemVendor, Item);
    end;

    local procedure CanCreateRequisitionLineFromProdOrderLine(ItemNo: Code[20]; VariantCode: Code[20]): Boolean
    begin
        if not GuiAllowed() then
            exit;

        if ItemNo <> '' then begin
            if Item."No." <> ItemNo then begin
                Item.SetLoadFields("Production Blocked");
                Item.Get(ItemNo);
            end;
            case Item."Production Blocked" of
                Item."Production Blocked"::Output:
                    begin
                        ShowProdBlockedForItemConfirmation(ItemNo);
                        exit(false);
                    end;
            end;
        end;

        if (ItemNo <> '') and (VariantCode <> '') then begin
            if (ItemVariant."Item No." <> ItemNo) or (ItemVariant.Code <> VariantCode) then begin
                ItemVariant.SetLoadFields("Production Blocked");
                ItemVariant.Get(ItemNo, VariantCode);
            end;
            case ItemVariant."Production Blocked" of
                ItemVariant."Production Blocked"::Output:
                    begin
                        ShowProdBlockedForItemVariantConfirmation(ItemNo, VariantCode);
                        exit(false);
                    end;
            end;
        end;

        exit(true);
    end;

    local procedure CalculateSubContractRequirements()
    begin
        OnProdOrderRoutingLineOnBeforeCalculateSubContractRequirements(TempProdOrderRoutingLine);

        if TempProdOrderRoutingLine.IsEmpty() then
            exit;

        TempProdOrderRoutingLine.SetCurrentKey("Prod. Order No.", "Routing Reference No.", Status, "Routing No.", "Operation No.");
        if TempProdOrderRoutingLine.FindSet() then
            repeat
                Window.Update(2, TempProdOrderRoutingLine."Prod. Order No.");
                ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Routing No.", "Routing Reference No.");
                ProdOrderLine.SetRange(Status, TempProdOrderRoutingLine.Status);
                ProdOrderLine.SetRange("Prod. Order No.", TempProdOrderRoutingLine."Prod. Order No.");
                ProdOrderLine.SetRange("Routing No.", TempProdOrderRoutingLine."Routing No.");
                ProdOrderLine.SetRange("Routing Reference No.", TempProdOrderRoutingLine."Routing Reference No.");
                OnProdOrderRoutingLineOnAfterGetRecordOnAfterProdOrderLineSetFilters(ProdOrderLine, TempProdOrderRoutingLine);
                if ProdOrderLine.FindSet() then begin
                    DeleteRepeatedReqLines(TempProdOrderRoutingLine);
                    repeat
                        BaseQtyToPurch :=
                            MfgCostCalcMgt.CalcQtyAdjdForRoutingScrap(
                                MfgCostCalcMgt.CalcQtyAdjdForBOMScrap(
                                    ProdOrderLine."Quantity (Base)", ProdOrderLine."Scrap %"),
                                    TempProdOrderRoutingLine."Scrap Factor % (Accumulated)", TempProdOrderRoutingLine."Fixed Scrap Qty. (Accum.)") -
                            (MfgCostCalcMgt.CalcOutputQtyBaseOnPurchOrder(ProdOrderLine, TempProdOrderRoutingLine) +
                             MfgCostCalcMgt.CalcActOutputQtyBase(ProdOrderLine, TempProdOrderRoutingLine));
                        QtyToPurch := Round(BaseQtyToPurch / ProdOrderLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                        OnAfterCalcQtyToPurch(ProdOrderLine, QtyToPurch);
                        if QtyToPurch > 0 then
                            InsertReqWkshLine(TempProdOrderRoutingLine);
                    until ProdOrderLine.Next() = 0;
                end;
            until TempProdOrderRoutingLine.Next() = 0;
    end;

    local procedure ShowProdBlockedForItemConfirmation(ItemNo: Code[20])
    begin
        if not Confirm(StrSubstNo(ProductionBlockedOutputItemQst, ItemNo)) then
            Error('');
    end;

    local procedure ShowProdBlockedForItemVariantConfirmation(ItemNo: Code[20]; VariantCode: Code[20])
    begin
        if not Confirm(StrSubstNo(ProductionBlockedOutputItemVariantQst, VariantCode, ItemNo)) then
            Error('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyToPurch(ProdOrderLine: Record "Prod. Order Line"; var QtyToPurch: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferProdOrderRoutingLine(var RequisitionLine: Record "Requisition Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReqWkshLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var WorkCenter: Record "Work Center"; var ReqLine: Record "Requisition Line"; var IsHandled: Boolean; ProdOrderLine: Record "Prod. Order Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitCost(var RequisitionLine: Record "Requisition Line"; var WorkCenter: Record "Work Center"; var IsHandled: Boolean; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReqWkshLineInsert(var RequisitionLine: Record "Requisition Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRepeatedReqLinesOnAfterRequisitionLineSetFilters(var RequisitionLine: Record "Requisition Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderRoutingLineOnAfterGetRecordOnAfterProdOrderLineSetFilters(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetVendorItemNo(var RequisitionLine: Record "Requisition Line"; ItemVendor: Record "Item Vendor"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderRoutingLineOnBeforeCalculateSubContractRequirements(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary)
    begin
    end;
}

