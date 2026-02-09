// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Utilities;
using System.Utilities;

codeunit 99001557 "Subc. Purchase Order Creator"
{
    var
        SubcManagementSetup: Record "Subc. Management Setup";
        PageManagement: Codeunit "Page Management";
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
        HasSubManagementSetup: Boolean;
        OperationNo: Code[10];

    procedure CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line") NoOfCreatedPurchOrder: Integer
    var
        ProdOrderLine: Record "Prod. Order Line";
        BaseQtyToPurch: Decimal;
        QtyToPurch: Decimal;
    begin
        GetSubmanagementSetup();
        SubcManagementSetup.TestField("Subcontracting Template Name");
        SubcManagementSetup.TestField("Subcontracting Batch Name");

        CheckProdOrderRtngLine(ProdOrderRoutingLine, ProdOrderLine);

        ProdOrderLine.SetLoadFields("Quantity (Base)", "Scrap %", "Qty. per Unit of Measure", "Item No.", "Variant Code", "Unit of Measure Code", "Total Exp. Oper. Output (Qty.)", "Location Code", "Bin Code");
        ProdOrderLine.FindSet();
        repeat
            BaseQtyToPurch := GetBaseQtyToPurchase(ProdOrderRoutingLine, ProdOrderLine);
            QtyToPurch := Round(BaseQtyToPurch / ProdOrderLine."Qty. per Unit of Measure", UnitofMeasureManagement.QtyRndPrecision());
            if QtyToPurch > 0 then
                CreateSubcontractingPurchase(ProdOrderRoutingLine,
                  ProdOrderLine,
                  QtyToPurch,
                  NoOfCreatedPurchOrder);
        until ProdOrderLine.Next() = 0;

        exit(NoOfCreatedPurchOrder);
    end;

    procedure InsertProdDescriptionOnAfterInsertPurchOrderLine(PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
    begin
        GetSubmanagementSetup();

        if not HasSubManagementSetup then
            exit;

        if not SubcManagementSetup."Create Prod. Order Info Line" then
            exit;

        if (RequisitionLine."Prod. Order No." <> '') and
           (RequisitionLine."Prod. Order Line No." <> 0) and
           (RequisitionLine."Operation No." <> '') and
           (RequisitionLine."Routing Reference No." <> 0)
        then begin
            ProdOrderLine.SetLoadFields(Description, "Description 2");
            ProdOrderLine.Get("Production Order Status"::Released, RequisitionLine."Prod. Order No.", RequisitionLine."Prod. Order Line No.");

            PurchaseLine.Init();
            PurchaseLine."Line No." := GetLineNoBeforeInsertedLineNo(PurchOrderLine);
            PurchaseLine."Document Type" := PurchOrderLine."Document Type";
            PurchaseLine."Document No." := PurchOrderLine."Document No.";
            PurchaseLine.Type := "Purchase Line Type"::" ";
            PurchaseLine.Description := ProdOrderLine.Description;
            PurchaseLine."Description 2" := ProdOrderLine."Description 2";

            PurchaseLine.Insert();
        end;
    end;

    procedure TransferSubcontractingProdOrderComp(var PurchaseLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line"; var NextLineNo: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseHeader: Record "Purchase Header";
        Purchasing: Record Purchasing;
        WorkCenter: Record "Work Center";
        DimensionManagement: Codeunit DimensionManagement;
        SubContractorWorkCenterNo: Code[20];
        DimensionSetIDArr: array[10] of Integer;
    begin
        GetSubmanagementSetup();
        ProdOrderRoutingLine.SetLoadFields("Work Center No.", Status, "Prod. Order No.", "Routing Link Code");
        if ProdOrderRoutingLine.Get("Production Order Status"::Released, RequisitionLine."Prod. Order No.", RequisitionLine."Routing Reference No.", RequisitionLine."Routing No.", RequisitionLine."Operation No.") then begin
            WorkCenter.SetLoadFields("Subcontractor No.");
            if WorkCenter.Get(ProdOrderRoutingLine."Work Center No.") then begin
                SubContractorWorkCenterNo := WorkCenter."No.";
                OnBeforeHandleProdOrderRtngWorkCenterWithSubcontractor(SubContractorWorkCenterNo);
                if SubContractorWorkCenterNo <> '' then begin
                    PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
                    ProdOrderComponent.SetRange(Status, ProdOrderRoutingLine.Status);
                    ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
                    ProdOrderComponent.SetRange("Prod. Order Line No.", RequisitionLine."Prod. Order Line No.");
                    ProdOrderComponent.SetRange("Subcontracting Type", "Subcontracting Type"::Purchase);
                    ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
                    if ProdOrderComponent.FindSet() then
                        repeat
                            InitPurchOrderLine(PurchaseLine, PurchaseHeader, RequisitionLine, ProdOrderComponent, NextLineNo);

                            PurchaseLine."Drop Shipment" := RequisitionLine."Sales Order Line No." <> 0;

                            if Purchasing.Get(RequisitionLine."Purchasing Code") then
                                if PurchaseLine."Special Order" then begin
                                    PurchaseLine."Special Order Sales No." := RequisitionLine."Sales Order No.";
                                    PurchaseLine."Special Order Sales Line No." := RequisitionLine."Sales Order Line No.";
                                    PurchaseLine."Special Order" := true;
                                    PurchaseLine."Drop Shipment" := false;
                                    PurchaseLine."Sales Order No." := '';
                                    PurchaseLine."Sales Order Line No." := 0;
                                    PurchaseLine.UpdateUnitCost();
                                end;

                            DimensionSetIDArr[1] := ProdOrderComponent."Dimension Set ID";
                            DimensionSetIDArr[2] := PurchaseLine."Dimension Set ID";
                            PurchaseLine."Dimension Set ID" :=
                                DimensionManagement.GetCombinedDimensionSetID(
                                    DimensionSetIDArr, PurchaseLine."Shortcut Dimension 1 Code", PurchaseLine."Shortcut Dimension 2 Code");
                            PurchaseLine."Order Date" := WorkDate();

                            PurchaseLine."Subc. Prod. Order No." := ProdOrderRoutingLine."Prod. Order No.";
                            PurchaseLine."Subc. Prod. Order Line No." := ProdOrderRoutingLine."Routing Reference No.";
                            PurchaseLine."Subc. Routing No." := ProdOrderRoutingLine."Routing No.";
                            PurchaseLine."Subc. Rtng Reference No." := ProdOrderRoutingLine."Routing Reference No.";
                            PurchaseLine."Subc. Operation No." := ProdOrderRoutingLine."Operation No.";
                            PurchaseLine."Subc. Work Center No." := ProdOrderRoutingLine."Work Center No.";

                            PurchaseLine.Insert();
                        until ProdOrderComponent.Next() = 0;
                end;
            end
        end;
    end;

    procedure ShowCreatedPurchaseOrder(ProdOrderNo: Code[20]; NoOfCreatedPurchOrder: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InstructionMgt: Codeunit "Instruction Mgt.";
        SubcNotificationMgmt: Codeunit "Subc. Notification Mgmt.";
        IsHandled: Boolean;
        PurchOrderCreatedTxt: Label '%1 Purchase Order(s) created.\\Do you want to view them?', Comment = '%1 = No of Purchase Order(s) created.';
    begin
        OnBeforeShowCreatedPurchaseOrder(ProdOrderNo, NoOfCreatedPurchOrder, IsHandled);
        if IsHandled then
            exit;

        if NoOfCreatedPurchOrder = 0 then
            exit;
        if InstructionMgt.IsEnabled(SubcNotificationMgmt.GetShowCreatedSubContPurchOrderCode()) then
            if InstructionMgt.ShowConfirm(StrSubstNo(PurchOrderCreatedTxt, NoOfCreatedPurchOrder), SubcNotificationMgmt.GetShowCreatedSubContPurchOrderCode()) and
                GuiAllowed()
            then begin
                PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.");
                PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
                PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
                PurchaseLine.SetRange("Prod. Order No.", ProdOrderNo);
                if NoOfCreatedPurchOrder > 1 then
                    PageManagement.PageRun(PurchaseLine)
                else begin
                    PurchaseLine.SetLoadFields(SystemId);
                    if (NoOfCreatedPurchOrder = 1) and (OperationNo <> '') then
                        PurchaseLine.SetRange("Operation No.", OperationNo);
                    PurchaseLine.FindFirst();
                    PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
                    PageManagement.PageRun(PurchaseHeader);
                end;
            end;
    end;

    internal procedure SetOperationNoForCreatedPurchaseOrder(OperationNoToSet: Code[10])
    begin
        OperationNo := OperationNoToSet;
    end;

    internal procedure ClearOperationNoForCreatedPurchaseOrder()
    begin
        Clear(OperationNo);
    end;

    local procedure CheckProdOrderRtngLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line")
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: Record "Work Center";
        ConfirmManagement: Codeunit "Confirm Management";
        CreationOfSubcontractingOrderIsNotAllowedErr: Label 'You cannot create Subcontracting Order, because the Production Order %1 is not released.', Comment = '%1=Production Order No.';
        NoProdOrderLineWithRemQtyErr: Label 'No Prod. Order Line with Remaining Quantity.';
        PurchOrderCreatedTxt: Label 'Already Purchase Order(s) created.\\Do you want to view them?';
    begin
        if ProdOrderRoutingLine.Status <> "Production Order Status"::Released then
            Error(CreationOfSubcontractingOrderIsNotAllowedErr, ProdOrderRoutingLine."Prod. Order No.");

        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Routing No.", "Routing Reference No.");
        ProdOrderLine.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderLine.SetFilter("Remaining Quantity", '<>%1', 0);
        if ProdOrderLine.IsEmpty() then
            Error(NoProdOrderLineWithRemQtyErr);

        WorkCenter.SetLoadFields("Gen. Prod. Posting Group", "Subcontractor No.");
        WorkCenter.Get(ProdOrderRoutingLine."Work Center No.");
        WorkCenter.TestField("Subcontractor No.");
        WorkCenter.TestField("Gen. Prod. Posting Group");

        GenProductPostingGroup.SetLoadFields("Def. VAT Prod. Posting Group");
        GenProductPostingGroup.Get(WorkCenter."Gen. Prod. Posting Group");
        GenProductPostingGroup.TestField("Def. VAT Prod. Posting Group");

        ProdOrderLine.FindFirst();
        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.");
        PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        PurchaseLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        if not PurchaseLine.IsEmpty() then
            if ConfirmManagement.GetResponseOrDefault(PurchOrderCreatedTxt, false) then
                if PurchaseLine.Count() > 1 then
                    Page.Run(Page::"Purchase Lines", PurchaseLine)
                else begin
                    PurchaseLine.FindFirst();
                    PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
                    PageManagement.PageRun(PurchaseHeader);
                end;
    end;

    local procedure CreateSubcontractingPurchase(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"; QtyToPurch: Decimal; var NoOfCreatedPurchOrder: Integer)
    var
        RequisitionLine: Record "Requisition Line";
        CarryOutActionMsgReq: Report "Carry Out Action Msg. - Req.";
    begin
        ProdOrderLine.CalcFields("Total Exp. Oper. Output (Qty.)");

        RequisitionLine.SetRange("Worksheet Template Name", SubcManagementSetup."Subcontracting Template Name");
        RequisitionLine.SetRange("Journal Batch Name", SubcManagementSetup."Subcontracting Batch Name");
        FilterReqLineWithProdOrderAndRtngLine(RequisitionLine, ProdOrderLine, ProdOrderRoutingLine);
        if RequisitionLine.FindFirst() then
            RequisitionLine.Delete();

        InsertReqWkshLine(ProdOrderRoutingLine, ProdOrderLine, SubcManagementSetup."Subcontracting Template Name", SubcManagementSetup."Subcontracting Batch Name", QtyToPurch);

        if RequisitionLine.FindFirst() then begin
            CarryOutActionMsgReq.UseRequestPage(false);
            CarryOutActionMsgReq.SetReqWkshLine(RequisitionLine);
            CarryOutActionMsgReq.SetHideDialog(true);
            CarryOutActionMsgReq.RunModal();
            Clear(CarryOutActionMsgReq);
            NoOfCreatedPurchOrder += 1;
        end;
    end;

    local procedure FilterReqLineWithProdOrderAndRtngLine(var RequisitionLine: Record "Requisition Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        RequisitionLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        RequisitionLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");

        RequisitionLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        RequisitionLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        RequisitionLine.SetRange("Work Center No.", ProdOrderRoutingLine."Work Center No.");
        RequisitionLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
    end;

    local procedure GetBaseQtyToPurchase(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line") BaseQuantityToPurch: Decimal
    var
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        ActOutputQtyBase: Decimal;
        OutputQtyBaseOnPurchOrder: Decimal;
        QtyAdjdForRoutingScrap: Decimal;
        QtyAdjForBomScrap: Decimal;
    begin
        QtyAdjForBomScrap := MfgCostCalculationMgt.CalcQtyAdjdForBOMScrap(ProdOrderLine."Quantity (Base)", ProdOrderLine."Scrap %");

        QtyAdjdForRoutingScrap := MfgCostCalculationMgt.CalcQtyAdjdForRoutingScrap(QtyAdjForBomScrap, ProdOrderRoutingLine."Scrap Factor % (Accumulated)", ProdOrderRoutingLine."Fixed Scrap Qty. (Accum.)");

        OutputQtyBaseOnPurchOrder := MfgCostCalculationMgt.CalcOutputQtyBaseOnPurchOrder(ProdOrderLine, ProdOrderRoutingLine);

        ActOutputQtyBase := MfgCostCalculationMgt.CalcActOutputQtyBase(ProdOrderLine, ProdOrderRoutingLine);

        BaseQuantityToPurch := QtyAdjdForRoutingScrap - (OutputQtyBaseOnPurchOrder + ActOutputQtyBase);

        exit(BaseQuantityToPurch);
    end;

    local procedure GetSubmanagementSetup()
    begin
        if HasSubManagementSetup then
            exit;
        if SubcManagementSetup.Get() then
            HasSubManagementSetup := true;
    end;

    local procedure GetLineNoBeforeInsertedLineNo(PurchaseLine: Record "Purchase Line") BeforeLineNo: Integer
    var
        ToPurchaseLine: Record "Purchase Line";
        LineSpacing: Integer;
        NotEnoughSpaceErr: Label 'There is not enough space to insert the subcontracting info line.';
    begin
        ToPurchaseLine.Reset();
        ToPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        ToPurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        ToPurchaseLine := PurchaseLine;
#pragma warning disable AA0181
        if ToPurchaseLine.Find('<') then begin
#pragma warning restore AA0181
            LineSpacing :=
              (PurchaseLine."Line No." - ToPurchaseLine."Line No.") div 2;
            if LineSpacing = 0 then
                Error(NotEnoughSpaceErr);
        end else
            LineSpacing := 5000;

        BeforeLineNo := PurchaseLine."Line No." - LineSpacing;
    end;

    local procedure GetNextReqLineNo(RequisitionLine: Record "Requisition Line"): Integer
    var
        RequisitionLine2: Record "Requisition Line";
        NextLineNo: Integer;
    begin
        RequisitionLine2.SetRange(RequisitionLine2."Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        RequisitionLine2.SetRange(RequisitionLine2."Journal Batch Name", RequisitionLine."Journal Batch Name");
        RequisitionLine2.SetLoadFields("Line No.");
        if RequisitionLine2.FindLast() then
            NextLineNo := RequisitionLine2."Line No." + 10000
        else
            NextLineNo += 10000;
        exit(NextLineNo);
    end;

    local procedure InitPurchOrderLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; RequisitionLine: Record "Requisition Line"; ProdOrderComponent: Record "Prod. Order Component"; var NextLineNo: Integer)
    var
        Item: Record Item;
    begin
        GetSubmanagementSetup();

        Item.SetLoadFields("Item Category Code", "Description 2");
        Item.Get(ProdOrderComponent."Item No.");

        PurchaseLine.Init();
        PurchaseLine.BlockDynamicTracking(true);
        PurchaseLine."Document Type" := "Purchase Document Type"::Order;
        PurchaseLine."Buy-from Vendor No." := RequisitionLine."Vendor No.";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        NextLineNo := NextLineNo + 10000;
        PurchaseLine."Line No." := NextLineNo;

        PurchaseLine.Validate(Type, "Purchase Line Type"::Item);

        PurchaseLine.Validate("No.", ProdOrderComponent."Item No.");

        PurchaseLine.Validate("Variant Code", ProdOrderComponent."Variant Code");

        PurchaseLine.Validate("Location Code", ProdOrderComponent."Location Code");
        if ProdOrderComponent."Bin Code" <> '' then
            PurchaseLine.Validate("Bin Code", ProdOrderComponent."Bin Code");
        PurchaseLine.Validate("Unit of Measure Code", ProdOrderComponent."Unit of Measure Code");
        PurchaseLine."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";

        PurchaseLine.Validate(Quantity, ProdOrderComponent."Remaining Quantity");

        if SubcManagementSetup."Component Direct Unit Cost" <> SubcManagementSetup."Component Direct Unit Cost"::Standard then begin
            if PurchaseHeader."Prices Including VAT" then
                PurchaseLine.Validate("Direct Unit Cost", ProdOrderComponent."Direct Unit Cost" * (1 + PurchaseLine."VAT %" / 100))
            else
                PurchaseLine.Validate("Direct Unit Cost", ProdOrderComponent."Direct Unit Cost");
            PurchaseLine.Validate("Line Discount %", RequisitionLine."Line Discount %");
        end;

        PurchaseLine.Description := ProdOrderComponent.Description;
        PurchaseLine."Description 2" := Item."Description 2";

        PurchaseLine."Sales Order No." := RequisitionLine."Sales Order No.";
        PurchaseLine."Sales Order Line No." := RequisitionLine."Sales Order Line No.";

        PurchaseLine."Item Category Code" := Item."Item Category Code";
        PurchaseLine.Validate("Purchasing Code", RequisitionLine."Purchasing Code");

        if RequisitionLine."Due Date" <> 0D then begin
            PurchaseLine.Validate("Expected Receipt Date", RequisitionLine."Due Date");
            PurchaseLine."Requested Receipt Date" := PurchaseLine."Planned Receipt Date";
        end;
    end;

    local procedure InsertReqWkshLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"; ReqWkshTemplateName: Code[10]; WkshName: Code[10]; QtyToPurch: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetLoadFields("Subcontractor No.", "Unit Cost Calculation", "Location Code", "Open Shop Floor Bin Code");
        WorkCenter.Get(ProdOrderRoutingLine."Work Center No.");
        RequisitionLine.GetProdOrderLine(ProdOrderLine);

        ProdOrderLine.CalcFields("Total Exp. Oper. Output (Qty.)");

        RequisitionLine.SetSubcontracting(true);
        RequisitionLine.BlockDynamicTracking(true);

        RequisitionLine.Init();
        RequisitionLine."Worksheet Template Name" := ReqWkshTemplateName;
        RequisitionLine."Journal Batch Name" := WkshName;

        RequisitionLine."Line No." := GetNextReqLineNo(RequisitionLine);

        RequisitionLine.Validate(Type, "Requisition Line Type"::Item);
        RequisitionLine.Validate("No.", ProdOrderLine."Item No.");
        RequisitionLine.Validate("Variant Code", ProdOrderLine."Variant Code");
        RequisitionLine.Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        RequisitionLine.Validate(Quantity, QtyToPurch);

        GeneralLedgerSetup.Get();
        if RequisitionLine.Quantity <> 0 then begin
            if WorkCenter."Unit Cost Calculation" = "Unit Cost Calculation Type"::Units then
                RequisitionLine.Validate(
                    RequisitionLine."Direct Unit Cost",
                    Round(
                        ProdOrderRoutingLine."Direct Unit Cost" * ProdOrderLine."Qty. per Unit of Measure",
                        GeneralLedgerSetup."Unit-Amount Rounding Precision"))
            else
                RequisitionLine.Validate(
                    RequisitionLine."Direct Unit Cost",
                    Round(
                        (ProdOrderRoutingLine."Expected Operation Cost Amt." - ProdOrderRoutingLine."Expected Capacity Ovhd. Cost") /
                        ProdOrderLine."Total Exp. Oper. Output (Qty.)",
                        GeneralLedgerSetup."Unit-Amount Rounding Precision"))
        end else
            RequisitionLine.Validate("Direct Unit Cost", 0);

        RequisitionLine."Qty. per Unit of Measure" := 0;
        RequisitionLine."Quantity (Base)" := 0;
        RequisitionLine."Qty. Rounding Precision" := ProdOrderLine."Qty. Rounding Precision";
        RequisitionLine."Qty. Rounding Precision (Base)" := ProdOrderLine."Qty. Rounding Precision (Base)";
        RequisitionLine."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        RequisitionLine."Prod. Order Line No." := ProdOrderLine."Line No.";
        RequisitionLine."Due Date" := ProdOrderRoutingLine."Ending Date";
        RequisitionLine."Requester ID" := CopyStr(UserId(), 1, MaxStrLen(RequisitionLine."Requester ID"));

        if WorkCenter."Location Code" <> '' then begin
            RequisitionLine."Location Code" := WorkCenter."Location Code";
            RequisitionLine."Bin Code" := WorkCenter."Open Shop Floor Bin Code";
        end else begin
            RequisitionLine."Location Code" := ProdOrderLine."Location Code";
            RequisitionLine."Bin Code" := ProdOrderLine."Bin Code";
        end;

        RequisitionLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        RequisitionLine."Routing No." := ProdOrderRoutingLine."Routing No.";
        RequisitionLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        RequisitionLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        RequisitionLine."Variant Code" := ProdOrderLine."Variant Code";

        RequisitionLine.Validate("Vendor No.", WorkCenter."Subcontractor No.");

        RequisitionLine.Description := ProdOrderRoutingLine.Description;
        RequisitionLine."Description 2" := '';
        SetVendorItemNo(RequisitionLine);

        if PurchLineExists(PurchaseLine, ProdOrderLine, ProdOrderRoutingLine) then begin
            RequisitionLine.Validate(Quantity, RequisitionLine.Quantity + PurchaseLine."Outstanding Quantity");
            RequisitionLine."Quantity (Base)" := 0;
            RequisitionLine."Replenishment System" := "Replenishment System"::Purchase;

            RequisitionLine."Ref. Order No." := PurchaseLine."Document No.";
            RequisitionLine."Ref. Order Type" := RequisitionLine."Ref. Order Type"::Purchase;
            RequisitionLine."Ref. Line No." := PurchaseLine."Line No.";

            if PurchaseLine."Expected Receipt Date" = RequisitionLine."Due Date" then
                RequisitionLine."Action Message" := "Action Message Type"::"Change Qty."
            else
                RequisitionLine."Action Message" := "Action Message Type"::"Resched. & Chg. Qty.";
            RequisitionLine."Accept Action Message" := true;
        end else begin
            RequisitionLine."Replenishment System" := "Replenishment System"::"Prod. Order";
            RequisitionLine."Ref. Order No." := ProdOrderLine."Prod. Order No.";
            RequisitionLine."Ref. Order Type" := RequisitionLine."Ref. Order Type"::"Prod. Order";
            RequisitionLine."Ref. Order Status" := ProdOrderLine.Status;
            RequisitionLine."Ref. Line No." := ProdOrderLine."Line No.";
            RequisitionLine."Action Message" := "Action Message Type"::New;
            RequisitionLine."Accept Action Message" := true;
        end;

        if RequisitionLine."Ref. Order No." <> '' then
            RequisitionLine.GetDimFromRefOrderLine(true);

        RequisitionLine.Insert();
    end;

    local procedure SetVendorItemNo(var RequisitionLine: Record "Requisition Line")
    var
        Item: Record Item;
        ItemVendor: Record "Item Vendor";
    begin
        if RequisitionLine."No." = '' then
            exit;

        if Item."No." <> RequisitionLine."No." then begin
            Item.SetLoadFields("No.");
            Item.Get(RequisitionLine."No.");
        end;

        ItemVendor.Init();
        ItemVendor."Vendor No." := RequisitionLine."Vendor No.";
        ItemVendor."Variant Code" := RequisitionLine."Variant Code";
        Item.FindItemVend(ItemVendor, RequisitionLine."Location Code");
        RequisitionLine.Validate("Vendor Item No.", ItemVendor."Vendor Item No.");
    end;

    local procedure PurchLineExists(var PurchaseLine: Record "Purchase Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Boolean
    begin
        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
        PurchaseLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        PurchaseLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        PurchaseLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        PurchaseLine.SetRange("Planning Flexibility", "Reservation Planning Flexibility"::Unlimited);
        PurchaseLine.SetRange("Quantity Received", 0);
        exit(PurchaseLine.FindFirst());
    end;

    [InternalEvent(false, false)]
    local procedure OnBeforeHandleProdOrderRtngWorkCenterWithSubcontractor(var SubContractorWorkCenterNo: Code[20])
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnBeforeShowCreatedPurchaseOrder(ProdOrderNo: Code[20]; NoOfCreatedPurchOrder: Integer; var IsHandled: Boolean)
    begin
    end;
}
