// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;

codeunit 99001505 "Subcontracting Management"
{
    var
        SubManagementSetup: Record "Subc. Management Setup";
        TempGlobalReservEntry: Record "Reservation Entry" temporary;
        PageManagement: Codeunit "Page Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        HasSubManagementSetup: Boolean;
        OperationNo: Code[10];

    procedure CalcReceiptDateFromProdCompDueDateWithInbWhseHandlingTime(ProdOrderComponent: Record "Prod. Order Component") ReceiptDate: Date
    begin
        GetSubmanagementSetup();
        if not HasSubManagementSetup or (Format(SubManagementSetup."Subc. Inb. Whse. Handling Time") = '') then
            exit(ProdOrderComponent."Due Date");

        ReceiptDate := CalcDate('-' + Format(SubManagementSetup."Subc. Inb. Whse. Handling Time"), ProdOrderComponent."Due Date");

        exit(ReceiptDate);
    end;

    procedure ChangeLocation_OnProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; VendorSubcontrLocation: Code[10]; OriginalLocationCode: Code[10]; OriginalBinCode: Code[20])
    begin
        case ProdOrderComponent."Subcontracting Type" of
            "Subcontracting Type"::InventoryByVendor,
            "Subcontracting Type"::Purchase:
                if (VendorSubcontrLocation <> '') and (ProdOrderComponent."Location Code" <> VendorSubcontrLocation) then
                    ProdOrderComponent.Validate("Location Code", VendorSubcontrLocation);

            "Subcontracting Type"::Transfer,
            "Subcontracting Type"::Empty:
                begin
                    if (ProdOrderComponent."Location Code" <> OriginalLocationCode) and (OriginalLocationCode <> '') then begin
                        ProdOrderComponent.Validate("Location Code", OriginalLocationCode);
                        ProdOrderComponent."Orig. Location Code" := '';
                    end;
                    if (ProdOrderComponent."Bin Code" <> OriginalBinCode) and (OriginalBinCode <> '') then begin
                        ProdOrderComponent.Validate("Bin Code", OriginalBinCode);
                        ProdOrderComponent."Orig. Bin Code" := '';
                    end;
                end;
        end;
    end;

    procedure ChangeLocation_OnPlanningComponent(var PlanningComponent: Record "Planning Component"; VendorSubcontrLocation: Code[10]; OriginalLocationCode: Code[10]; OriginalBinCode: Code[20])
    begin
        case PlanningComponent."Subcontracting Type" of
            "Subcontracting Type"::InventoryByVendor,
            "Subcontracting Type"::Purchase:
                if (VendorSubcontrLocation <> '') and (PlanningComponent."Location Code" <> VendorSubcontrLocation) then
                    PlanningComponent.Validate("Location Code", VendorSubcontrLocation);

            "Subcontracting Type"::Transfer,
            "Subcontracting Type"::Empty:
                begin
                    if (PlanningComponent."Location Code" <> OriginalLocationCode) and (OriginalLocationCode <> '') then begin
                        PlanningComponent.Validate("Location Code", OriginalLocationCode);
                        PlanningComponent."Orig. Location Code" := '';
                    end;
                    if (PlanningComponent."Bin Code" <> OriginalBinCode) and (OriginalBinCode <> '') then begin
                        PlanningComponent.Validate("Bin Code", OriginalBinCode);
                        PlanningComponent."Orig. Bin Code" := '';
                    end;
                end;
        end;
    end;

    procedure CheckDirectTransferIsAllowedForTransferHeader(TransferHeader: Record "Transfer Header")
    begin
        TransferHeader.CheckDirectTransferPosting();
    end;

    procedure CreatePurchProvisionRoutingLine(RoutingHeader: Record "Routing Header")
    var
        RtngLine: Record "Routing Line";
        Vend: Record Vendor;
        CSubingleInstanceDict: Codeunit "Single Instance Dictionary";
        SubcontractingMgmt: Codeunit "Subcontracting Management";
        RoutingLinkCode: Code[10];
        WorkCenterNo: Code[20];
    begin
        GetSubmanagementSetup();
        if HasSubManagementSetup then
            RoutingLinkCode := SubManagementSetup."Rtng. Link Code Purch. Prov.";

        Vend.SetLoadFields("Work Center No.");
        if Vend.Get(CSubingleInstanceDict.GetCode(SubcontractingMgmt.GetDictionaryKey_Sub_CreateProdOrderProcess())) then
            WorkCenterNo := Vend."Work Center No.";

        if WorkCenterNo = '' then
            WorkCenterNo := SubManagementSetup."Common Work Center No.";

        if WorkCenterNo = '' then
            exit;

        RtngLine.Init();
        RtngLine."Routing No." := RoutingHeader."No.";
        RtngLine."Operation No." := '01';
        RtngLine.Type := "Capacity Type Routing"::"Work Center";
        RtngLine.Validate("No.", WorkCenterNo);
        if RoutingLinkCode <> '' then
            RtngLine."Routing Link Code" := RoutingLinkCode;

        RtngLine.Insert();
    end;

    procedure CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRtngLine: Record "Prod. Order Routing Line") NoOfCreatedPurchOrder: Integer
    var
        ProdOrderLine: Record "Prod. Order Line";
        BaseQtyToPurch: Decimal;
        QtyToPurch: Decimal;
    begin
        GetSubmanagementSetup();
        SubManagementSetup.TestField("Subcontracting Template Name");
        SubManagementSetup.TestField("Subcontracting Batch Name");

        CheckProdOrderRtngLine(ProdOrderRtngLine, ProdOrderLine);

        ProdOrderLine.SetLoadFields("Quantity (Base)", "Scrap %", "Qty. per Unit of Measure", "Item No.", "Variant Code", "Unit of Measure Code", "Total Exp. Oper. Output (Qty.)", "Location Code", "Bin Code");
        ProdOrderLine.FindSet();
        repeat
            BaseQtyToPurch := GetBaseQtyToPurchase(ProdOrderRtngLine, ProdOrderLine);
            QtyToPurch := Round(BaseQtyToPurch / ProdOrderLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
            if QtyToPurch > 0 then
                CreateSubcontractingPurchase(ProdOrderRtngLine,
                  ProdOrderLine,
                  QtyToPurch,
                  NoOfCreatedPurchOrder);
        until ProdOrderLine.Next() = 0;

        exit(NoOfCreatedPurchOrder);
    end;

    procedure DelLocationLinkedComponents(ProdOrdRoutingLine: Record "Prod. Order Routing Line"; ShowMsg: Boolean)
    var
        ProdOrdComponent: Record "Prod. Order Component";
        ProdOrdLine: Record "Prod. Order Line";
        SKU: Record "Stockkeeping Unit";
        ConfirmMgmt: Codeunit "Confirm Management";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        RoutingLinkUpdConfQst: Label 'If you change the Work Center, you will also change the default location for components with Routing Link Code=%1.\\Do you want to continue anyway?', Comment = '%1=Routing Link Code';
        SuccessfullyUpdatedMsg: Label 'Successfully updated.';
        UpdateIsCancelledErr: Label 'Update cancelled.';
    begin

        ProdOrdComponent.SetRange(Status, ProdOrdRoutingLine.Status);
        ProdOrdComponent.SetRange("Prod. Order No.", ProdOrdRoutingLine."Prod. Order No.");
        ProdOrdComponent.SetRange("Prod. Order Line No.", ProdOrdRoutingLine."Routing Reference No.");
        ProdOrdComponent.SetRange("Routing Link Code", ProdOrdRoutingLine."Routing Link Code");
        if not ProdOrdComponent.IsEmpty() then begin
            ProdOrdComponent.FindSet();
            if ShowMsg then
                if not ConfirmMgmt.GetResponseOrDefault(StrSubstNo(RoutingLinkUpdConfQst, ProdOrdRoutingLine."Routing Link Code"), true) then
                    Error(UpdateIsCancelledErr);

            ProdOrdLine.SetLoadFields("Item No.", "Variant Code", "Location Code");
            ProdOrdLine.Get(ProdOrdRoutingLine.Status, ProdOrdComponent."Prod. Order No.", ProdOrdComponent."Prod. Order Line No.");
            GetPlanningParameters.AtSKU(
              SKU,
              ProdOrdLine."Item No.",
              ProdOrdLine."Variant Code",
              ProdOrdLine."Location Code");
            repeat
                ProdOrdComponent.Validate("Location Code", SKU."Components at Location");
                ProdOrdComponent.Modify();
            until ProdOrdComponent.Next() = 0;

            if ShowMsg then
                Message(SuccessfullyUpdatedMsg);
        end;
    end;

    procedure GetDictionaryKey_Sub_CreateProdOrderProcess(): Text
    begin
        exit('Sub_CreateProdOrderProcess');
    end;

    procedure GetSubcontractor(WorkCenterNo: Code[20]; var Vendor: Record Vendor): Boolean
    var
        WorkCenter: Record "Work Center";
        HasSubcontractor, IsHandled : Boolean;
        WorkCenterVendorDoesntExistErr: Label 'Vendor %1 on Work Center %2 does not exist.',
            Comment = 'Parameter %1 - subcontractor number, %2 - vendor number.';
    begin
        OnBeforeGetSubcontractor(WorkCenterNo, Vendor, HasSubcontractor, IsHandled);//DO NOT DELETE
        if IsHandled then
            exit(HasSubcontractor);

        WorkCenter.SetLoadFields("Subcontractor No.");
        WorkCenter.Get(WorkCenterNo);
        if WorkCenter."Subcontractor No." <> '' then begin
            Vendor.SetLoadFields("Subcontr. Location Code");
            if not Vendor.Get(WorkCenter."Subcontractor No.") then
                Error(WorkCenterVendorDoesntExistErr, WorkCenter."Subcontractor No.", WorkCenter."No.");
            Vendor.TestField("Subcontr. Location Code");
            exit(true);
        end;
        exit(false);
    end;

    procedure HandleCommonWorkCenter(ItemJnlLine: Record "Item Journal Line"): Boolean
    var
    begin
        if ItemJnlLine."Work Center No." = '' then
            exit(false);
        GetSubmanagementSetup();
        if SubManagementSetup."Common Work Center No." = ItemJnlLine."Work Center No." then
            exit(true);

        exit(false);
    end;

    procedure InsertProdDescriptionOnAfterInsertPurchOrderLine(PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
        InfoPurchOrderLine: Record "Purchase Line";
    begin
        GetSubmanagementSetup();

        if not HasSubManagementSetup then
            exit;

        if not SubManagementSetup."Create Prod. Order Info Line" then
            exit;

        if (RequisitionLine."Prod. Order No." <> '') and
           (RequisitionLine."Prod. Order Line No." <> 0) and
           (RequisitionLine."Operation No." <> '') and
           (RequisitionLine."Routing Reference No." <> 0)
        then begin
            ProdOrderLine.SetLoadFields(Description, "Description 2");
            ProdOrderLine.Get("Production Order Status"::Released, RequisitionLine."Prod. Order No.", RequisitionLine."Prod. Order Line No.");

            InfoPurchOrderLine.Init();
            InfoPurchOrderLine."Line No." := GetLineNoBeforeInsertedLineNo(PurchOrderLine);
            InfoPurchOrderLine."Document Type" := PurchOrderLine."Document Type";
            InfoPurchOrderLine."Document No." := PurchOrderLine."Document No.";
            InfoPurchOrderLine.Type := "Purchase Line Type"::" ";
            InfoPurchOrderLine.Description := ProdOrderLine.Description;
            InfoPurchOrderLine."Description 2" := ProdOrderLine."Description 2";

            InfoPurchOrderLine.Insert();
        end;
    end;

    procedure UpdateSubcontractorPriceForRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
        if IsSubcontracting(RequisitionLine."Work Center No.") then
            RequisitionLine.UpdateSubcontractorPrice();
    end;

    procedure UpdateLinkedComponentsAfterRoutingTransfer(var ProdOrderLine: Record "Prod. Order Line"; var RoutingLine: Record "Routing Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        WorkCenter: Record "Work Center";
    begin
        if ProdOrderRoutingLine.Type <> "Capacity Type"::"Work Center" then
            exit;

        if ProdOrderRoutingLine."Routing Link Code" = '' then
            exit;

        WorkCenter.SetLoadFields("Subcontractor No.");
        WorkCenter.Get(RoutingLine."Work Center No.");
        if WorkCenter."Subcontractor No." = '' then
            exit;

        UpdLinkedComponents(ProdOrderRoutingLine, false);
    end;

    procedure ShowCreatedPurchaseOrder(ProdOrderNo: Code[20]; NoOfCreatedPurchOrder: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InstructionMgt: Codeunit "Instruction Mgt.";
        NotifMgmt: Codeunit "Subc. Notification Mgmt.";
        IsHandled: Boolean;
        PurchOrderCreatedTxt: Label '%1 Purchase Order(s) created.\\Do you want to view them?', Comment = '%1 = No of Purchase Order(s) created.';
    begin
        OnBeforeShowCreatedPurchaseOrder(ProdOrderNo, NoOfCreatedPurchOrder, IsHandled);
        if IsHandled then
            exit;

        if NoOfCreatedPurchOrder = 0 then
            exit;
        if InstructionMgt.IsEnabled(NotifMgmt.GetShowCreatedSubContPurchOrderCode()) then
            if InstructionMgt.ShowConfirm(StrSubstNo(PurchOrderCreatedTxt, NoOfCreatedPurchOrder), NotifMgmt.GetShowCreatedSubContPurchOrderCode()) and
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

    procedure TransferReservationEntryFromProdOrderCompToTransferOrder(TransferLine: Record "Transfer Line"; ProdOrderComponent: Record "Prod. Order Component")
    var
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
    begin
        TempGlobalReservEntry.Reset();
        TempGlobalReservEntry.DeleteAll();

        if not ProdOrderCompReserve.FindReservEntry(ProdOrderComponent, ReservEntry) then
            exit;


        if ReservEntry.FindSet() then
            repeat
                TempGlobalReservEntry := ReservEntry;
                TempGlobalReservEntry.Insert();
            until ReservEntry.Next() = 0;

        TempReservEntry.Copy(TempGlobalReservEntry, true);

        ReservEntry.TransferReservations(
         ReservEntry,
         TransferLine."Item No.",
         TransferLine."Variant Code",
         TransferLine."Transfer-from Code",
         true,
         0,
         TransferLine."Qty. per Unit of Measure",
         Database::"Transfer Line",
         0,  // Direction::Outbound
         TransferLine."Document No.",
         '',
         0,
         TransferLine."Line No.");
    end;

    procedure CreateReservEntryForTransferReceiptToProdOrderComp(
     TransferLine: Record "Transfer Line";
     ProdOrderComponent: Record "Prod. Order Component")
    var
        Item: Record Item;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        TempGlobalReservEntry.SetRange("Reservation Status", TempGlobalReservEntry."Reservation Status"::Reservation);
        if not TempGlobalReservEntry.FindSet() then
            exit;

        repeat
            if TempGlobalReservEntry.GetItemTrackingEntryType() <> "Item Tracking Entry Type"::None then
                if Item.Get(TempGlobalReservEntry."Item No.") then begin
                    TempGlobalReservEntry."Location Code" := ProdOrderComponent."Location Code";
                    CreateReservEntry.CreateReservEntryFor(
                        Database::"Transfer Line",
                        1,  // Direction::Inbound
                        TransferLine."Document No.",
                        '',
                        TransferLine."Derived From Line No.",
                        TransferLine."Line No.",
                        TransferLine."Qty. per Unit of Measure",
                        Abs(TempGlobalReservEntry.Quantity),
                        Abs(TempGlobalReservEntry."Quantity (Base)"),
                        TempGlobalReservEntry);

                    TempTrackingSpecification.Init();
                    TempTrackingSpecification.SetSource(
                        Database::"Prod. Order Component",
                        ProdOrderComponent.Status.AsInteger(),
                        ProdOrderComponent."Prod. Order No.",
                        ProdOrderComponent."Line No.",
                        '',
                        ProdOrderComponent."Prod. Order Line No.");
                    TempTrackingSpecification."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
                    TempTrackingSpecification.CopyTrackingFromReservEntry(TempGlobalReservEntry);

                    CreateReservEntry.CreateReservEntryFrom(TempTrackingSpecification);

                    CreateReservEntry.CreateEntry(
                        TempGlobalReservEntry."Item No.",
                        TempGlobalReservEntry."Variant Code",
                        TransferLine."Transfer-to Code",
                        TempGlobalReservEntry.Description,
                        TransferLine."Receipt Date",
                        ProdOrderComponent."Due Date",
                        0,
                        TempGlobalReservEntry."Reservation Status");
                end;
        until TempGlobalReservEntry.Next() = 0;
    end;

    procedure TransferReservationEntryFromPstTransferLineToProdOrderComp(var TransferReceiptLine: Record "Transfer Receipt Line")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ProdOrderComp: Record "Prod. Order Component";
        TempForReservationEntry: Record "Reservation Entry" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ReserveProdOrderComp: Codeunit "Prod. Order Comp.-Reserve";
    begin
        if (TransferReceiptLine."Prod. Order No." = '') or (TransferReceiptLine."Operation No." = '') then
            exit;
        if not ProdOrderComp.Get("Production Order Status"::Released, TransferReceiptLine."Prod. Order No.", TransferReceiptLine."Prod. Order Line No.", TransferReceiptLine."Prod. Order Comp. Line No.") then
            exit;
        ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Expiration Date", "Lot No.", "Serial No.");
        ItemLedgEntry.SetRange("Item No.", TransferReceiptLine."Item No.");
        ItemLedgEntry.SetRange(Open, true);
        ItemLedgEntry.SetRange(Positive, true);
        ItemLedgEntry.SetRange("Document No.", TransferReceiptLine."Document No.");
        ItemLedgEntry.SetRange("Document Line No.", TransferReceiptLine."Line No.");
        ItemLedgEntry.SetRange("Location Code", TransferReceiptLine."Transfer-to Code");
        ItemLedgEntry.SetLoadFields("Serial No.", "Lot No.", "Package No.", "Variant Code", "Location Code", "Qty. per Unit of Measure", Quantity);
        if not ItemLedgEntry.IsEmpty() then begin
            ItemLedgEntry.FindSet();
            repeat
                if (ItemLedgEntry."Lot No." <> '') or (ItemLedgEntry."Serial No." <> '') or (ItemLedgEntry."Package No." <> '') then begin
                    if not TempTrackingSpecification.IsEmpty() then
                        TempTrackingSpecification.DeleteAll();
                    TempTrackingSpecification."Source Type" := Database::"Item Ledger Entry";
                    TempTrackingSpecification."Source Subtype" := 0;
                    TempTrackingSpecification."Source ID" := '';
                    TempTrackingSpecification."Source Batch Name" := '';
                    TempTrackingSpecification."Source Prod. Order Line" := 0;
                    TempTrackingSpecification."Source Ref. No." := ItemLedgEntry."Entry No.";
                    TempTrackingSpecification."Variant Code" := ItemLedgEntry."Variant Code";
                    TempTrackingSpecification."Location Code" := ItemLedgEntry."Location Code";
                    TempTrackingSpecification."Serial No." := ItemLedgEntry."Serial No.";
                    TempTrackingSpecification."Lot No." := ItemLedgEntry."Lot No.";
                    TempTrackingSpecification."Package No." := ItemLedgEntry."Package No.";
                    TempTrackingSpecification."Qty. per Unit of Measure" := ItemLedgEntry."Qty. per Unit of Measure";
                    TempTrackingSpecification.Insert();

                    ReserveProdOrderComp.CreateReservationSetFrom(TempTrackingSpecification);
                    TempForReservationEntry.CopyTrackingFromSpec(TempTrackingSpecification);
                    ReserveProdOrderComp.CreateReservation(
                      ProdOrderComp,
                      ProdOrderComp.Description,
                      ProdOrderComp."Due Date",
                      ItemLedgEntry.Quantity,
                      ItemLedgEntry.Quantity * ItemLedgEntry."Qty. per Unit of Measure",
                      TempForReservationEntry);
                end;
            until ItemLedgEntry.Next() = 0;
        end;
    end;

    procedure TransferSubcontractingProdOrderComp(var PurchOrderLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line"; var NextLineNo: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        PurchOrderHeader: Record "Purchase Header";
        PurchasingCode: Record Purchasing;
        WorkCenter: Record "Work Center";
        DimMgt: Codeunit DimensionManagement;
        SubContractorWorkCenterNo: Code[20];
        DimensionSetIDArr: array[10] of Integer;
    begin
        GetSubmanagementSetup();
        ProdOrderRtngLine.SetLoadFields("Work Center No.", Status, "Prod. Order No.", "Routing Link Code");
        if ProdOrderRtngLine.Get("Production Order Status"::Released, RequisitionLine."Prod. Order No.", RequisitionLine."Routing Reference No.", RequisitionLine."Routing No.", RequisitionLine."Operation No.") then begin
            WorkCenter.SetLoadFields("Subcontractor No.");
            if WorkCenter.Get(ProdOrderRtngLine."Work Center No.") then begin
                SubContractorWorkCenterNo := WorkCenter."No.";
                OnBeforeHandleProdOrderRtngWorkCenterWithSubcontractor(SubContractorWorkCenterNo);
                if SubContractorWorkCenterNo <> '' then begin
                    PurchOrderHeader.Get(PurchOrderLine."Document Type", PurchOrderLine."Document No.");
                    ProdOrderComp.SetRange(Status, ProdOrderRtngLine.Status);
                    ProdOrderComp.SetRange("Prod. Order No.", ProdOrderRtngLine."Prod. Order No.");
                    ProdOrderComp.SetRange("Prod. Order Line No.", RequisitionLine."Prod. Order Line No.");
                    ProdOrderComp.SetRange("Subcontracting Type", "Subcontracting Type"::Purchase);
                    ProdOrderComp.SetRange("Routing Link Code", ProdOrderRtngLine."Routing Link Code");
                    if ProdOrderComp.FindSet() then
                        repeat
                            InitPurchOrderLine(PurchOrderLine, PurchOrderHeader, RequisitionLine, ProdOrderComp, NextLineNo);

                            PurchOrderLine."Drop Shipment" := RequisitionLine."Sales Order Line No." <> 0;

                            if PurchasingCode.Get(RequisitionLine."Purchasing Code") then
                                if PurchOrderLine."Special Order" then begin
                                    PurchOrderLine."Special Order Sales No." := RequisitionLine."Sales Order No.";
                                    PurchOrderLine."Special Order Sales Line No." := RequisitionLine."Sales Order Line No.";
                                    PurchOrderLine."Special Order" := true;
                                    PurchOrderLine."Drop Shipment" := false;
                                    PurchOrderLine."Sales Order No." := '';
                                    PurchOrderLine."Sales Order Line No." := 0;
                                    PurchOrderLine.UpdateUnitCost();
                                end;

                            DimensionSetIDArr[1] := ProdOrderComp."Dimension Set ID";
                            DimensionSetIDArr[2] := PurchOrderLine."Dimension Set ID";
                            PurchOrderLine."Dimension Set ID" :=
                                DimMgt.GetCombinedDimensionSetID(
                                    DimensionSetIDArr, PurchOrderLine."Shortcut Dimension 1 Code", PurchOrderLine."Shortcut Dimension 2 Code");
                            PurchOrderLine."Order Date" := WorkDate();

                            PurchOrderLine."Subc. Prod. Order No." := ProdOrderRtngLine."Prod. Order No.";
                            PurchOrderLine."Subc. Prod. Order Line No." := ProdOrderRtngLine."Routing Reference No.";
                            PurchOrderLine."Subc. Routing No." := ProdOrderRtngLine."Routing No.";
                            PurchOrderLine."Subc. Rtng Reference No." := ProdOrderRtngLine."Routing Reference No.";
                            PurchOrderLine."Subc. Operation No." := ProdOrderRtngLine."Operation No.";
                            PurchOrderLine."Subc. Work Center No." := ProdOrderRtngLine."Work Center No.";

                            PurchOrderLine.Insert();
                        until ProdOrderComp.Next() = 0;
                end;
            end
        end;
    end;

    procedure UpdateLocationCodeInProdOrderCompAfterDeleteTransferLine(var TransferLine: Record "Transfer Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        SubcontractingMgmt: Codeunit "Subcontracting Management";
    begin
        if ProdOrderComponent.Get("Production Order Status"::Released, TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Prod. Order Comp. Line No.") then
            if ProdOrderComponent."Orig. Location Code" <> '' then begin
                SubcontractingMgmt.ChangeLocation_OnProdOrderComponent(ProdOrderComponent, '', ProdOrderComponent."Orig. Location Code", ProdOrderComponent."Orig. Bin Code");
                ProdOrderComponent."Orig. Location Code" := '';
                ProdOrderComponent."Orig. Bin Code" := '';


                ProdOrderComponent.Modify();
            end;
    end;

    procedure UpdateSubcontractingTypeForPlanningComponent(var PlanningComponent: Record "Planning Component")
    var
        PlanRtngLine: Record "Planning Routing Line";
        Vendor: Record Vendor;
        OrigLocationCode, VendorSubcontractingLocationCode : Code[10];
        OrigBinCode: Code[20];
    begin
        if PlanningComponent."Routing Link Code" = '' then
            exit;

        PlanRtngLine.SetRange("Worksheet Template Name", PlanningComponent."Worksheet Template Name");
        PlanRtngLine.SetRange("Worksheet Batch Name", PlanningComponent."Worksheet Batch Name");
        PlanRtngLine.SetRange("Worksheet Line No.", PlanningComponent."Worksheet Line No.");
        PlanRtngLine.SetRange("Routing Link Code", PlanningComponent."Routing Link Code");
        PlanRtngLine.SetRange(Type, "Capacity Type"::"Work Center");
        if not PlanRtngLine.IsEmpty() then begin
            PlanRtngLine.SetLoadFields("No.");
            PlanRtngLine.FindFirst();

            if not GetSubcontractor(PlanRtngLine."No.", Vendor) then
                Clear(Vendor);
            if PlanningComponent."Subcontracting Type" in ["Subcontracting Type"::InventoryByVendor, "Subcontracting Type"::Purchase] then
                VendorSubcontractingLocationCode := Vendor."Subcontr. Location Code";
            OrigLocationCode := PlanningComponent."Orig. Location Code";
            OrigBinCode := PlanningComponent."Orig. Bin Code";

            ChangeLocation_OnPlanningComponent(PlanningComponent, VendorSubcontractingLocationCode, OrigLocationCode, OrigBinCode);

            PlanningComponent.Modify();
        end;
    end;

    procedure UpdateSubcontractingTypeForProdOrderComponent(var ProdOrderComp: Record "Prod. Order Component")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Vendor: Record Vendor;
        ProdOrderCompFound: Boolean;
        OrigLocationCode, VendorSubcontractingLocationCode : Code[10];
        OrigBinCode: Code[20];
        PurchOrderNo: Code[20];
        PurchOrderExistErr: Label 'The currently selected component %1 is already used in Purchase Order %2. Therefore, it is not permitted to change the %3 field.', Comment = '%1=Item No, %2=Purchase Order No, %3=Field Caption';
    begin
        if ProdOrderComp."Routing Link Code" = '' then
            exit;

        ProdOrderLine.SetLoadFields("Routing Reference No.", "Routing No.");
        ProdOrderLine.Get(ProdOrderComp.Status, ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.");

        ProdOrderRtngLine.SetRange(Status, ProdOrderComp.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderComp."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRtngLine.SetRange("Routing Link Code", ProdOrderComp."Routing Link Code");
        ProdOrderRtngLine.SetLoadFields("Prod. Order No.", Type, "No.");
        if ProdOrderRtngLine.FindFirst() then begin
            PurchaseLine.SetRange("Document Type", "Purchase Document Type"::Order);
            PurchaseLine.SetRange("Prod. Order No.", ProdOrderRtngLine."Prod. Order No.");
            PurchaseLine.SetLoadFields(SystemId);
            if PurchaseLine.FindSet() then
                repeat
                    if PurchOrderNo <> PurchaseLine."Document No." then begin
                        PurchOrderNo := PurchaseLine."Document No.";
                        PurchaseLine2.SetRange("Document Type", PurchaseLine."Document Type");
                        PurchaseLine2.SetRange("Document No.", PurchaseLine."Document No.");
                        PurchaseLine2.SetRange(Type, "Purchase Line Type"::Item);
                        PurchaseLine2.SetRange("No.", ProdOrderComp."Item No.");
                        ProdOrderCompFound := not PurchaseLine2.IsEmpty();
                    end;
                until (PurchaseLine.Next() = 0) or ProdOrderCompFound;
            if ProdOrderCompFound then
                Error(PurchOrderExistErr, ProdOrderComp."Item No.", PurchOrderNo, ProdOrderComp.FieldCaption(ProdOrderComp."Subcontracting Type"));

            if ProdOrderRtngLine.Type = "Capacity Type"::"Work Center" then begin
                if not GetSubcontractor(ProdOrderRtngLine."No.", Vendor) then
                    Clear(Vendor);

                VendorSubcontractingLocationCode := Vendor."Subcontr. Location Code";
                if ProdOrderComp."Subcontracting Type" in ["Subcontracting Type"::InventoryByVendor, "Subcontracting Type"::Purchase] = false then
                    Clear(VendorSubcontractingLocationCode);
                OrigLocationCode := ProdOrderComp."Orig. Location Code";
                OrigBinCode := ProdOrderComp."Orig. Bin Code";

                ChangeLocation_OnProdOrderComponent(ProdOrderComp, VendorSubcontractingLocationCode, OrigLocationCode, OrigBinCode);

                ProdOrderComp.Modify();
            end;
        end;
    end;

    procedure UpdLinkedComponents(ProdOrdRoutingLine: Record "Prod. Order Routing Line"; ShowMsg: Boolean)
    var
        ProdOrdComponent: Record "Prod. Order Component";
        Vendor: Record Vendor;
        ConfirmMgt: Codeunit "Confirm Management";
        Subcontracting: Boolean;
        OrigLocationCode, VendorSubcontractingLocationCode : Code[10];
        OrigBinCode: Code[20];
        RoutingLinkUpdConfQst: Label 'If you change the Work Center, you will also change the default location for components with Routing Link Code=%1.\Do you want to continue anyway?', Comment = '%1=Routing Link Code';
        SuccessfullyUpdatedMsg: Label 'Successfully updated.';
        UpdateIsCancelledErr: Label 'The update is canceled.';
    begin
        ProdOrdComponent.SetRange(Status, ProdOrdRoutingLine.Status);
        ProdOrdComponent.SetRange("Prod. Order No.", ProdOrdRoutingLine."Prod. Order No.");
        ProdOrdComponent.SetRange("Prod. Order Line No.", ProdOrdRoutingLine."Routing Reference No.");
        ProdOrdComponent.SetRange("Routing Link Code", ProdOrdRoutingLine."Routing Link Code");
        if ProdOrdComponent.FindSet() then begin
            if ProdOrdRoutingLine.Type = "Capacity Type"::"Work Center" then
                Subcontracting := GetSubcontractor(ProdOrdRoutingLine."No.", Vendor);

            if Subcontracting then begin
                VendorSubcontractingLocationCode := Vendor."Subcontr. Location Code";
                if ShowMsg then
                    if not ConfirmMgt.GetResponseOrDefault(StrSubstNo(RoutingLinkUpdConfQst, ProdOrdRoutingLine."Routing Link Code"), true) then
                        Error(UpdateIsCancelledErr);
                repeat
                    if ProdOrdComponent."Subcontracting Type" in ["Subcontracting Type"::InventoryByVendor, "Subcontracting Type"::Purchase] = false then
                        Clear(VendorSubcontractingLocationCode);
                    OrigLocationCode := ProdOrdComponent."Orig. Location Code";
                    OrigBinCode := ProdOrdComponent."Orig. Bin Code";

                    ChangeLocation_OnProdOrderComponent(ProdOrdComponent, VendorSubcontractingLocationCode, OrigLocationCode, OrigBinCode);

                    ProdOrdComponent.Modify();
                until ProdOrdComponent.Next() = 0;

                if ShowMsg then
                    Message(SuccessfullyUpdatedMsg);
            end;
        end;
    end;

    /// <summary>
    /// Gets the transfer-from location code based on the setup field "Component at Location".
    /// The location code is retrieved from the purchase line, company information, or manufacturing setup.
    /// </summary>
    /// <returns>The transfer-from location code.</returns>
    procedure GetComponentsLocationCode(PurchaseLine: Record "Purchase Line"): Code[10]
    var
        CompanyInfo: Record "Company Information";
        ManufacturingSetup: Record "Manufacturing Setup";
        ComponentsLocationCode: Code[10];
    begin
        GetSubmanagementSetup();
        SubManagementSetup.TestField("Component at Location");

        case SubManagementSetup."Component at Location" of
            "Components at Location"::Purchase:
                begin
                    PurchaseLine.TestField("Location Code");
                    ComponentsLocationCode := PurchaseLine."Location Code";
                end;
            "Components at Location"::Company:
                begin
                    CompanyInfo.SetLoadFields("Location Code");
                    CompanyInfo.Get();
                    CompanyInfo.TestField("Location Code");
                    ComponentsLocationCode := CompanyInfo."Location Code";
                end;
            "Components at Location"::Manufacturing:
                begin
                    ManufacturingSetup.SetLoadFields("Components at Location");
                    ManufacturingSetup.Get();
                    ManufacturingSetup.TestField("Components at Location");
                    ComponentsLocationCode := ManufacturingSetup."Components at Location";
                end;
        end;

        exit(ComponentsLocationCode);
    end;

    internal procedure SetOperationNoForCreatedPurchaseOrder(OperationNoToSet: Code[10])
    begin
        OperationNo := OperationNoToSet;
    end;

    internal procedure ClearOperationNoForCreatedPurchaseOrder()
    begin
        Clear(OperationNo);
    end;

    local procedure CheckProdOrderRtngLine(ProdOrderRtngLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line")
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WorkCenter: Record "Work Center";
        ConfirmMgmt: Codeunit "Confirm Management";
        CreationOfSubcontractingOrderIsNotAllowedErr: Label 'You cannot create Subcontracting Order, because the Production Order %1 is not released.', Comment = '%1=Production Order No.';
        NoProdOrderLineWithRemQtyErr: Label 'No Prod. Order Line with Remaining Quantity.';
        PurchOrderCreatedTxt: Label 'Already Purchase Order(s) created.\\Do you want to view them?';
    begin
        if ProdOrderRtngLine.Status <> "Production Order Status"::Released then
            Error(CreationOfSubcontractingOrderIsNotAllowedErr, ProdOrderRtngLine."Prod. Order No.");

        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Routing No.", "Routing Reference No.");
        ProdOrderLine.SetRange(Status, ProdOrderRtngLine.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderRtngLine."Prod. Order No.");
        ProdOrderLine.SetRange("Routing No.", ProdOrderRtngLine."Routing No.");
        ProdOrderLine.SetRange("Routing Reference No.", ProdOrderRtngLine."Routing Reference No.");
        ProdOrderLine.SetFilter("Remaining Quantity", '<>%1', 0);
        if ProdOrderLine.IsEmpty() then
            Error(NoProdOrderLineWithRemQtyErr);

        WorkCenter.SetLoadFields("Gen. Prod. Posting Group", "Subcontractor No.");
        WorkCenter.Get(ProdOrderRtngLine."Work Center No.");
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
        PurchaseLine.SetRange("Routing No.", ProdOrderRtngLine."Routing No.");
        PurchaseLine.SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
        if not PurchaseLine.IsEmpty() then
            if ConfirmMgmt.GetResponseOrDefault(PurchOrderCreatedTxt, false) then
                if PurchaseLine.Count() > 1 then
                    Page.Run(Page::"Purchase Lines", PurchaseLine)
                else begin
                    PurchaseLine.FindFirst();
                    PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
                    PageManagement.PageRun(PurchaseHeader);
                end;
    end;

    local procedure CreateSubcontractingPurchase(ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"; QtyToPurch: Decimal; var NoOfCreatedPurchOrder: Integer)
    var
        ReqLine: Record "Requisition Line";
        CarryOutAction: Report "Carry Out Action Msg. - Req.";
    begin
        ProdOrderLine.CalcFields("Total Exp. Oper. Output (Qty.)");

        ReqLine.SetRange("Worksheet Template Name", SubManagementSetup."Subcontracting Template Name");
        ReqLine.SetRange("Journal Batch Name", SubManagementSetup."Subcontracting Batch Name");
        FilterReqLineWithProdOrderAndRtngLine(ReqLine, ProdOrderLine, ProdOrderRtngLine);
        if ReqLine.FindFirst() then
            ReqLine.Delete();

        InsertReqWkshLine(ProdOrderRtngLine, ProdOrderLine, SubManagementSetup."Subcontracting Template Name", SubManagementSetup."Subcontracting Batch Name", QtyToPurch);

        if ReqLine.FindFirst() then begin
            CarryOutAction.UseRequestPage(false);
            CarryOutAction.SetReqWkshLine(ReqLine);
            CarryOutAction.SetHideDialog(true);
            CarryOutAction.RunModal();
            Clear(CarryOutAction);
            NoOfCreatedPurchOrder += 1;
        end;
    end;

    local procedure FilterReqLineWithProdOrderAndRtngLine(var ReqLine: Record "Requisition Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line")
    begin
        ReqLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ReqLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");

        ReqLine.SetRange("Routing No.", ProdOrderRtngLine."Routing No.");
        ReqLine.SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
        ReqLine.SetRange("Work Center No.", ProdOrderRtngLine."Work Center No.");
        ReqLine.SetRange("Routing Reference No.", ProdOrderRtngLine."Routing Reference No.");
    end;

    local procedure GetBaseQtyToPurchase(ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line") BaseQuantityToPurch: Decimal
    var
        CostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        ActOutputQtyBase: Decimal;
        OutputQtyBaseOnPurchOrder: Decimal;
        QtyAdjdForRoutingScrap: Decimal;
        QtyAdjForBomScrap: Decimal;
    begin
        QtyAdjForBomScrap := CostCalcMgt.CalcQtyAdjdForBOMScrap(ProdOrderLine."Quantity (Base)", ProdOrderLine."Scrap %");

        QtyAdjdForRoutingScrap := CostCalcMgt.CalcQtyAdjdForRoutingScrap(QtyAdjForBomScrap, ProdOrderRtngLine."Scrap Factor % (Accumulated)", ProdOrderRtngLine."Fixed Scrap Qty. (Accum.)");

        OutputQtyBaseOnPurchOrder := CostCalcMgt.CalcOutputQtyBaseOnPurchOrder(ProdOrderLine, ProdOrderRtngLine);

        ActOutputQtyBase := CostCalcMgt.CalcActOutputQtyBase(ProdOrderLine, ProdOrderRtngLine);

        BaseQuantityToPurch := QtyAdjdForRoutingScrap - (OutputQtyBaseOnPurchOrder + ActOutputQtyBase);

        exit(BaseQuantityToPurch);
    end;

    local procedure GetSubmanagementSetup()
    begin
        if HasSubManagementSetup then
            exit;
        if SubManagementSetup.Get() then
            HasSubManagementSetup := true;
    end;

    local procedure GetLineNoBeforeInsertedLineNo(PurchLine: Record "Purchase Line") BeforeLineNo: Integer
    var
        ToPurchLine: Record "Purchase Line";
        LineSpacing: Integer;
        NotEnoughSpaceErr: Label 'There is not enough space to insert the subcontracting info line.';
    begin
        ToPurchLine.Reset();
        ToPurchLine.SetRange("Document Type", PurchLine."Document Type");
        ToPurchLine.SetRange("Document No.", PurchLine."Document No.");
        ToPurchLine := PurchLine;
#pragma warning disable AA0181
        if ToPurchLine.Find('<') then begin
#pragma warning restore AA0181
            LineSpacing :=
              (PurchLine."Line No." - ToPurchLine."Line No.") div 2;
            if LineSpacing = 0 then
                Error(NotEnoughSpaceErr);
        end else
            LineSpacing := 5000;

        BeforeLineNo := PurchLine."Line No." - LineSpacing;
    end;

    local procedure GetNextReqLineNo(ReqLine: Record "Requisition Line"): Integer
    var
        RequisitionLine: Record "Requisition Line";
        NextLineNo: Integer;
    begin
        RequisitionLine.SetRange(RequisitionLine."Worksheet Template Name", ReqLine."Worksheet Template Name");
        RequisitionLine.SetRange(RequisitionLine."Journal Batch Name", ReqLine."Journal Batch Name");
        RequisitionLine.SetLoadFields("Line No.");
        if RequisitionLine.FindLast() then
            NextLineNo := RequisitionLine."Line No." + 10000
        else
            NextLineNo += 10000;
        exit(NextLineNo);
    end;

    local procedure InitPurchOrderLine(var PurchOrderLine: Record "Purchase Line"; PurchOrderHeader: Record "Purchase Header"; RequisitionLine: Record "Requisition Line"; ProdOrderComp: Record "Prod. Order Component"; var NextLineNo: Integer)
    var
        Item: Record Item;
    begin
        GetSubmanagementSetup();

        Item.SetLoadFields("Item Category Code", "Description 2");
        Item.Get(ProdOrderComp."Item No.");

        PurchOrderLine.Init();
        PurchOrderLine.BlockDynamicTracking(true);
        PurchOrderLine."Document Type" := "Purchase Document Type"::Order;
        PurchOrderLine."Buy-from Vendor No." := RequisitionLine."Vendor No.";
        PurchOrderLine."Document No." := PurchOrderHeader."No.";
        NextLineNo := NextLineNo + 10000;
        PurchOrderLine."Line No." := NextLineNo;

        PurchOrderLine.Validate(Type, "Purchase Line Type"::Item);

        PurchOrderLine.Validate("No.", ProdOrderComp."Item No.");

        PurchOrderLine.Validate("Variant Code", ProdOrderComp."Variant Code");

        PurchOrderLine.Validate("Location Code", ProdOrderComp."Location Code");
        if ProdOrderComp."Bin Code" <> '' then
            PurchOrderLine.Validate("Bin Code", ProdOrderComp."Bin Code");
        PurchOrderLine.Validate("Unit of Measure Code", ProdOrderComp."Unit of Measure Code");
        PurchOrderLine."Qty. per Unit of Measure" := ProdOrderComp."Qty. per Unit of Measure";

        PurchOrderLine.Validate(Quantity, ProdOrderComp."Remaining Quantity");

        if SubManagementSetup."Component Direct Unit Cost" <> SubManagementSetup."Component Direct Unit Cost"::Standard then begin
            if PurchOrderHeader."Prices Including VAT" then
                PurchOrderLine.Validate("Direct Unit Cost", ProdOrderComp."Direct Unit Cost" * (1 + PurchOrderLine."VAT %" / 100))
            else
                PurchOrderLine.Validate("Direct Unit Cost", ProdOrderComp."Direct Unit Cost");
            PurchOrderLine.Validate("Line Discount %", RequisitionLine."Line Discount %");
        end;

        PurchOrderLine.Description := ProdOrderComp.Description;
        PurchOrderLine."Description 2" := Item."Description 2";

        PurchOrderLine."Sales Order No." := RequisitionLine."Sales Order No.";
        PurchOrderLine."Sales Order Line No." := RequisitionLine."Sales Order Line No.";

        PurchOrderLine."Item Category Code" := Item."Item Category Code";
        PurchOrderLine.Validate("Purchasing Code", RequisitionLine."Purchasing Code");

        if RequisitionLine."Due Date" <> 0D then begin
            PurchOrderLine.Validate("Expected Receipt Date", RequisitionLine."Due Date");
            PurchOrderLine."Requested Receipt Date" := PurchOrderLine."Planned Receipt Date";
        end;
    end;

    local procedure InsertReqWkshLine(ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"; ReqWkshTemplateName: Code[10]; WkshName: Code[10]; QtyToPurch: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
        PurchLine: Record "Purchase Line";
        ReqLine: Record "Requisition Line";
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetLoadFields("Subcontractor No.", "Unit Cost Calculation", "Location Code", "Open Shop Floor Bin Code");
        WorkCenter.Get(ProdOrderRtngLine."Work Center No.");
        ReqLine.GetProdOrderLine(ProdOrderLine);

        ProdOrderLine.CalcFields("Total Exp. Oper. Output (Qty.)");

        ReqLine.SetSubcontracting(true);
        ReqLine.BlockDynamicTracking(true);

        ReqLine.Init();
        ReqLine."Worksheet Template Name" := ReqWkshTemplateName;
        ReqLine."Journal Batch Name" := WkshName;

        ReqLine."Line No." := GetNextReqLineNo(ReqLine);

        ReqLine.Validate(Type, "Requisition Line Type"::Item);
        ReqLine.Validate("No.", ProdOrderLine."Item No.");
        ReqLine.Validate("Variant Code", ProdOrderLine."Variant Code");
        ReqLine.Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        ReqLine.Validate(Quantity, QtyToPurch);

        GLSetup.Get();
        if ReqLine.Quantity <> 0 then begin
            if WorkCenter."Unit Cost Calculation" = "Unit Cost Calculation Type"::Units then
                ReqLine.Validate(
                    ReqLine."Direct Unit Cost",
                    Round(
                        ProdOrderRtngLine."Direct Unit Cost" * ProdOrderLine."Qty. per Unit of Measure",
                        GLSetup."Unit-Amount Rounding Precision"))
            else
                ReqLine.Validate(
                    ReqLine."Direct Unit Cost",
                    Round(
                        (ProdOrderRtngLine."Expected Operation Cost Amt." - ProdOrderRtngLine."Expected Capacity Ovhd. Cost") /
                        ProdOrderLine."Total Exp. Oper. Output (Qty.)",
                        GLSetup."Unit-Amount Rounding Precision"))
        end else
            ReqLine.Validate("Direct Unit Cost", 0);

        ReqLine."Qty. per Unit of Measure" := 0;
        ReqLine."Quantity (Base)" := 0;
        ReqLine."Qty. Rounding Precision" := ProdOrderLine."Qty. Rounding Precision";
        ReqLine."Qty. Rounding Precision (Base)" := ProdOrderLine."Qty. Rounding Precision (Base)";
        ReqLine."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        ReqLine."Prod. Order Line No." := ProdOrderLine."Line No.";
        ReqLine."Due Date" := ProdOrderRtngLine."Ending Date";
        ReqLine."Requester ID" := CopyStr(UserId(), 1, MaxStrLen(ReqLine."Requester ID"));

        if WorkCenter."Location Code" <> '' then begin
            ReqLine."Location Code" := WorkCenter."Location Code";
            ReqLine."Bin Code" := WorkCenter."Open Shop Floor Bin Code";
        end else begin
            ReqLine."Location Code" := ProdOrderLine."Location Code";
            ReqLine."Bin Code" := ProdOrderLine."Bin Code";
        end;

        ReqLine."Routing Reference No." := ProdOrderRtngLine."Routing Reference No.";
        ReqLine."Routing No." := ProdOrderRtngLine."Routing No.";
        ReqLine."Operation No." := ProdOrderRtngLine."Operation No.";
        ReqLine."Work Center No." := ProdOrderRtngLine."Work Center No.";
        ReqLine."Variant Code" := ProdOrderLine."Variant Code";

        ReqLine.Validate("Vendor No.", WorkCenter."Subcontractor No.");

        ReqLine.Description := ProdOrderRtngLine.Description;
        ReqLine."Description 2" := '';
        SetVendorItemNo(ReqLine);

        if PurchLineExists(PurchLine, ProdOrderLine, ProdOrderRtngLine) then begin
            ReqLine.Validate(Quantity, ReqLine.Quantity + PurchLine."Outstanding Quantity");
            ReqLine."Quantity (Base)" := 0;
            ReqLine."Replenishment System" := "Replenishment System"::Purchase;

            ReqLine."Ref. Order No." := PurchLine."Document No.";
            ReqLine."Ref. Order Type" := ReqLine."Ref. Order Type"::Purchase;
            ReqLine."Ref. Line No." := PurchLine."Line No.";

            if PurchLine."Expected Receipt Date" = ReqLine."Due Date" then
                ReqLine."Action Message" := "Action Message Type"::"Change Qty."
            else
                ReqLine."Action Message" := "Action Message Type"::"Resched. & Chg. Qty.";
            ReqLine."Accept Action Message" := true;
        end else begin
            ReqLine."Replenishment System" := "Replenishment System"::"Prod. Order";
            ReqLine."Ref. Order No." := ProdOrderLine."Prod. Order No.";
            ReqLine."Ref. Order Type" := ReqLine."Ref. Order Type"::"Prod. Order";
            ReqLine."Ref. Order Status" := ProdOrderLine.Status;
            ReqLine."Ref. Line No." := ProdOrderLine."Line No.";
            ReqLine."Action Message" := "Action Message Type"::New;
            ReqLine."Accept Action Message" := true;
        end;

        if ReqLine."Ref. Order No." <> '' then
            ReqLine.GetDimFromRefOrderLine(true);

        ReqLine.Insert();
    end;

    local procedure SetVendorItemNo(var ReqLine: Record "Requisition Line")
    var
        Item: Record Item;
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
    end;

    local procedure IsSubcontracting(WorkCenterNo: Code[20]): Boolean
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetLoadFields("Subcontractor No.");
        if WorkCenter.Get(WorkCenterNo) then
            exit(WorkCenter."Subcontractor No." <> '')
    end;

    local procedure PurchLineExists(var PurchLine: Record "Purchase Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"): Boolean
    begin
        PurchLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchLine.SetRange("Document Type", "Purchase Document Type"::Order);
        PurchLine.SetRange(Type, "Purchase Line Type"::Item);
        PurchLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        PurchLine.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        PurchLine.SetRange("Routing No.", ProdOrderRtngLine."Routing No.");
        PurchLine.SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
        PurchLine.SetRange("Planning Flexibility", "Reservation Planning Flexibility"::Unlimited);
        PurchLine.SetRange("Quantity Received", 0);
        exit(PurchLine.FindFirst());
    end;

    [InternalEvent(false, false)]
    local procedure OnBeforeHandleProdOrderRtngWorkCenterWithSubcontractor(var SubContractorWorkCenterNo: Code[20])
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnBeforeGetSubcontractor(WorkCenterNo: Code[20]; var Vendor: Record Vendor; var HasSubcontractor: Boolean; var IsHandled: Boolean)
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnBeforeShowCreatedPurchaseOrder(ProdOrderNo: Code[20]; NoOfCreatedPurchOrder: Integer; var IsHandled: Boolean)
    begin
    end;
}
