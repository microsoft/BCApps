// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

report 99001501 "Subc. Create Transf. Order"
{
    ApplicationArea = Manufacturing;
    Caption = 'Create Subcontracting Transfer Order';
    ProcessingOnly = true;
    UsageCategory = Tasks;
    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") order(ascending);
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") order(ascending) where("Prod. Order No." = filter(<> ''), "Operation No." = filter(<> ''));
                trigger OnAfterGetRecord()
                begin
                    HandleComponentsForPurchLine("Purchase Line", true);
                    HandleWIPTransferForPurchLine("Purchase Line", true);
                end;
            }
            trigger OnAfterGetRecord()
            begin
                "Purchase Header".CalcFields("Subcontracting Order");
                if not "Subcontracting Order" then
                    Error(OrderNoIsNotSubcontractorErr, PurchOrderNo);

                if not CheckTransferCreated() then
                    Error(NothingToCreateErr);

                Vendor.Get("Purchase Header"."Buy-from Vendor No.");
            end;

            trigger OnPostDataItem()
            begin
                ShowDocument();
            end;

            trigger OnPreDataItem()
            begin
                PurchOrderNo := CopyStr("Purchase Header".GetFilter("No."), 1, MaxStrLen(PurchOrderNo));
                if PurchOrderNo = '' then
                    Error(WarningToSpecifyPurchOrderErr);
            end;
        }
    }

    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        PurchOrderNo: Code[20];
        LineNo: Integer;
        NothingToCreateErr: Label 'Nothing to create. No components or WIP to transfer for the specified subcontracting order.';
        OrderNoDoesNotExistInProdOrderErr: Label 'Operation %1 in the subcontracting order %2 does not exist in the routing %3 of the production order %4.', Comment = '%1=Operation No., %2=Purchase Order No., %3=Routing No., %4=Production Order No.';
        OrderNoIsNotSubcontractorErr: Label 'Order %1 is not a Subcontractor work.', Comment = '%1=Purchase Order No.';
        WarningToSpecifyPurchOrderErr: Label 'Warning. Specify a Purchase Order No. for the Subcontractor work.';

    local procedure InsertTransferHeader(TransferFromLocation: Code[10])
    var
        TransferRoute: Record "Transfer Route";
        TransferToLocationCode: Code[10];
    begin
        GetTransferToLocationCode(TransferToLocationCode);

        TransferHeader.Reset();
        TransferHeader.SetRange("Source Subtype", TransferHeader."Source Subtype"::"2");
        TransferHeader.SetRange("Source ID", "Purchase Header"."Buy-from Vendor No.");
        TransferHeader.SetRange(Status, TransferHeader.Status::Open);
        TransferHeader.SetRange("Completely Shipped", false);
        TransferHeader.SetRange("Transfer-from Code", TransferFromLocation);
        TransferHeader.SetRange("Transfer-to Code", TransferToLocationCode);
        TransferHeader.SetRange("Return Order", false);
        TransferHeader.SetRange("Subcontr. Purch. Order No.", "Purchase Header"."No.");
        if not TransferHeader.FindFirst() then begin
            TransferHeader.Init();
            TransferHeader."No." := '';
            TransferHeader.Insert(true);
            TransferHeader.Validate("Transfer-from Code", TransferFromLocation);
            TransferHeader.Validate("Transfer-to Code", TransferToLocationCode);
            if not TransferRoute.Get(TransferFromLocation, TransferToLocationCode) or (TransferRoute."In-Transit Code" = '') then
                TransferHeader.Validate("Direct Transfer", true);

            TransferHeader."Source Type" := TransferHeader."Source Type"::Subcontracting;
            TransferHeader."Source Subtype" := TransferHeader."Source Subtype"::"2";
            TransferHeader."Source ID" := "Purchase Header"."Buy-from Vendor No.";
            TransferHeader."Subcontr. Purch. Order No." := "Purchase Header"."No.";
            TransferHeader."Subcontr. PO Line No." := "Purchase Line"."Line No.";

            TransferHeader."Transfer-to Name" := Vendor.Name;
            TransferHeader."Transfer-to Name 2" := Vendor."Name 2";
            TransferHeader."Transfer-to Address" := Vendor.Address;
            TransferHeader."Transfer-to Address 2" := Vendor."Address 2";
            TransferHeader."Transfer-to Post Code" := Vendor."Post Code";
            TransferHeader."Transfer-to City" := Vendor.City;
            TransferHeader."Transfer-to County" := Vendor.County;
            TransferHeader."Trsf.-from Country/Region Code" := Vendor."Country/Region Code";

            TransferHeader.Modify();
            LineNo := 0;
        end else begin
            TransferLine.SetRange("Document No.", TransferHeader."No.");
            if TransferLine.FindLast() then
                LineNo := TransferLine."Line No."
            else
                LineNo := 0;
        end;
    end;

    local procedure CheckTransferCreated(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchaseLine.SetRange("Document No.", PurchOrderNo);
        PurchaseLine.SetFilter("Prod. Order No.", '<>''''');
        PurchaseLine.SetFilter("Prod. Order Line No.", '<>0');
        PurchaseLine.SetFilter("Operation No.", '<>0');
        if PurchaseLine.FindSet() then
            repeat
                if HandleComponentsForPurchLine(PurchaseLine, false) then
                    exit(true);
                if HandleWIPTransferForPurchLine(PurchaseLine, false) then
                    exit(true);
            until PurchaseLine.Next() = 0;

        exit(false);
    end;

    local procedure HandleComponentsForPurchLine(PurchaseLine: Record "Purchase Line"; InsertLine: Boolean): Boolean
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        SubcProdOrdCompRes: Codeunit "Subc. Prod. Ord. Comp. Res.";
        SubcontractingManagement: Codeunit "Subcontracting Management";
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
        TransferFromLocationCode: Code[10];
        QtyPerUom: Decimal;
        QtyToPost: Decimal;
    begin
        if not ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);

        if not ProdOrderRoutingLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.",
             PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.")
        then
            Error(OrderNoDoesNotExistInProdOrderErr, PurchaseLine."Operation No.", PurchOrderNo, PurchaseLine."Routing No.", PurchaseLine."Prod. Order No.");

        Item.SetLoadFields("Base Unit of Measure", "Rounding Precision");
        Item.Get(PurchaseLine."No.");
        QtyPerUom := UnitofMeasureManagement.GetQtyPerUnitOfMeasure(Item, PurchaseLine."Unit of Measure Code");

        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.SetRange("Purchase Order Filter", PurchaseLine."Document No.");
        ProdOrderComponent.SetRange("Component Supply Method", ProdOrderComponent."Component Supply Method"::"Transfer to Vendor");
        if ProdOrderComponent.FindSet() then
            repeat
                Item.SetLoadFields("Rounding Precision", "Order Tracking Policy");
                Item.Get(ProdOrderComponent."Item No.");
                QtyToPost := MfgCostCalculationMgt.CalcActNeededQtyBase(ProdOrderLine, ProdOrderComponent, Round(PurchaseLine.Quantity * QtyPerUom, UnitofMeasureManagement.QtyRndPrecision()));
                ProdOrderComponent.CalcFields("Qty. on Trans Order (Base)", "Qty. in Transit (Base)", "Qty. transf. to Subcontr");
                if QtyToPost > (ProdOrderComponent."Qty. on Trans Order (Base)" +
                                ProdOrderComponent."Qty. in Transit (Base)" +
                                Abs(ProdOrderComponent."Qty. transf. to Subcontr"))
                then
                    if InsertLine then begin
                        TransferFromLocationCode := GetTransferFromLocationForComponent(ProdOrderComponent);
                        InsertTransferHeader(TransferFromLocationCode);

                        LineNo := LineNo + 10000;

                        TransferLine.Init();
                        TransferLine."Document No." := TransferHeader."No.";
                        TransferLine."Line No." := LineNo;

                        TransferLine.Insert();

                        TransferLine.Validate("Item No.", ProdOrderComponent."Item No.");
                        TransferLine.Validate("Variant Code", ProdOrderComponent."Variant Code");

                        TransferLine."Unit of Measure Code" := ProdOrderComponent."Unit of Measure Code";
                        TransferLine."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";

                        QtyToPost := QtyToPost -
                            (ProdOrderComponent."Qty. on Trans Order (Base)" +
                             ProdOrderComponent."Qty. in Transit (Base)" +
                             Abs(ProdOrderComponent."Qty. transf. to Subcontr"));

                        TransferLine.Validate(Quantity, Round(QtyToPost / ProdOrderComponent."Qty. per Unit of Measure", Item."Rounding Precision", '>'));

                        if ProdOrderComponent."Due Date" <> 0D then
                            TransferLine.Validate("Receipt Date", SubcontractingManagement.CalcReceiptDateFromProdCompDueDateWithInbWhseHandlingTime(ProdOrderComponent));

                        TransferLine."Subcontr. Purch. Order No." := PurchaseLine."Document No.";
                        TransferLine."Subcontr. PO Line No." := PurchaseLine."Line No.";
                        TransferLine."Prod. Order No." := PurchaseLine."Prod. Order No.";
                        TransferLine."Prod. Order Line No." := PurchaseLine."Prod. Order Line No.";
                        TransferLine."Prod. Order Comp. Line No." := ProdOrderComponent."Line No.";
                        TransferLine."Routing No." := PurchaseLine."Routing No.";
                        TransferLine."Routing Reference No." := PurchaseLine."Routing Reference No.";
                        TransferLine."Work Center No." := PurchaseLine."Work Center No.";
                        TransferLine."Operation No." := PurchaseLine."Operation No.";
                        TransferLine.Modify();

                        if ProdOrderComponent."Orig. Location Code" = '' then
                            ProdOrderComponent."Orig. Location Code" := ProdOrderComponent."Location Code";
                        if ProdOrderComponent."Orig. Bin Code" = '' then
                            ProdOrderComponent."Orig. Bin Code" := ProdOrderComponent."Bin Code";

                        SubcontractingManagement.TransferReservationEntryFromProdOrderCompToTransferOrder(TransferLine, ProdOrderComponent);
                        if TransferHeader."Transfer-to Code" <> ProdOrderComponent."Location Code" then begin
                            if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
                                ProdOrderComponent.Validate("Location Code", TransferHeader."Transfer-to Code")
                            else begin
                                BindSubscription(SubcProdOrdCompRes);
                                ProdOrderComponent.Validate("Location Code", TransferHeader."Transfer-to Code");
                                UnbindSubscription(SubcProdOrdCompRes);
                            end;
                            ProdOrderComponent.GetDefaultBin();
                        end;
                        ProdOrderComponent.Modify();

                        SubcontractingManagement.CreateReservEntryForTransferReceiptToProdOrderComp(TransferLine, ProdOrderComponent);
                    end else
                        exit(true);
            until ProdOrderComponent.Next() = 0;

        exit(false);
    end;

    local procedure ShowDocument()
    var
        SubcPurchFactboxMgmt: Codeunit "Subc. Purch. Factbox Mgmt.";
    begin
        Commit(); // Used for following call of Transfer Pages
        SubcPurchFactboxMgmt.ShowTransferOrdersAndReturnOrder("Purchase Line", true, false);
    end;

    local procedure GetTransferFromLocationForComponent(ProdOrderComponent: Record "Prod. Order Component"): Code[10]
    var
        ResultLocationCode: Code[10];
        SubcontrLocationCode: Code[10];
    begin
        SubcontrLocationCode := "Purchase Header"."Subc. Location Code";
        if SubcontrLocationCode = '' then
            SubcontrLocationCode := Vendor."Subcontr. Location Code";

        if (ProdOrderComponent."Location Code" = SubcontrLocationCode) and
           (ProdOrderComponent."Orig. Location Code" <> '')
        then
            ResultLocationCode := ProdOrderComponent."Orig. Location Code"
        else
            ResultLocationCode := ProdOrderComponent."Location Code";
        exit(ResultLocationCode);
    end;

    local procedure GetTransferToLocationCode(var TransferToLocationCode: Code[10])
    begin
        GetTransferToLocationCodeForPurchaseHeader("Purchase Header", Vendor, TransferToLocationCode);
        if TransferToLocationCode = '' then
            Vendor.TestField("Subcontr. Location Code");
    end;

    local procedure GetTransferToLocationCodeForPurchaseHeader(PurchaseHeader: Record "Purchase Header"; VendorFromPurchaseHeader: Record Vendor; var TransferToLocationCode: Code[10])
    begin
        TransferToLocationCode := PurchaseHeader."Subc. Location Code";
        if TransferToLocationCode = '' then
            TransferToLocationCode := VendorFromPurchaseHeader."Subcontr. Location Code";
    end;

    local procedure HandleWIPTransferForPurchLine(PurchaseLine: Record "Purchase Line"; InsertLine: Boolean): Boolean
    var
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        UOMManagement: Codeunit "Unit of Measure Management";
        TransferFromLoc: Code[10];
        WIPPreviousOperationNo: Code[10];
        WIPQtyBase: Decimal;
        WIPQtyInUOM: Decimal;
        WIPPreviousOperationNoDict: Dictionary of [Code[10], Code[10]];
        WIPSourceQtyDict: Dictionary of [Code[10], Decimal];
        WIPSourceLocationList: List of [Code[10]];
    begin
        if not ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);

        if not ProdOrderRoutingLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.") then
            exit(false);

        if not ProdOrderRoutingLine."Transfer WIP Item" then
            exit(false);

        if not CheckCreateWIPTransfer(PurchaseLine) then
            exit(false);

        GetWIPTransferFromLocations(ProdOrderLine, ProdOrderRoutingLine, WIPSourceLocationList, WIPSourceQtyDict, WIPPreviousOperationNoDict);

        if WIPSourceLocationList.Count() = 0 then
            exit(false);

        if not InsertLine then
            exit(true);

        Item.SetLoadFields("Base Unit of Measure", "Rounding Precision", Description, "Description 2");
        Item.Get(ProdOrderLine."Item No.");

        foreach TransferFromLoc in WIPSourceLocationList do begin
            WIPQtyBase := WIPSourceQtyDict.Get(TransferFromLoc);
            WIPPreviousOperationNoDict.Get(TransferFromLoc, WIPPreviousOperationNo);
            if ProdOrderLine."Qty. per Unit of Measure" <> 0 then
                WIPQtyInUOM := Round(WIPQtyBase / ProdOrderLine."Qty. per Unit of Measure", UOMManagement.QtyRndPrecision())
            else
                WIPQtyInUOM := Round(WIPQtyBase, UOMManagement.QtyRndPrecision());
            if WIPQtyInUOM > 0 then begin
                InsertTransferHeader(TransferFromLoc);
                InsertWIPTransferLine(PurchaseLine, ProdOrderLine, ProdOrderRoutingLine, WIPQtyInUOM, WIPPreviousOperationNo);
            end;
        end;

        exit(false);
    end;

    local procedure InsertWIPTransferLine(PurchaseLine: Record "Purchase Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WIPQty: Decimal; WIPPreviousOperationNo: Code[10])
    begin
        LineNo := LineNo + 10000;

        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := LineNo;
        TransferLine.Insert();

        TransferLine.Validate("Item No.", ProdOrderLine."Item No.");
        if ProdOrderLine."Variant Code" <> '' then
            TransferLine.Validate("Variant Code", ProdOrderLine."Variant Code");
        TransferLine.Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        TransferLine.Validate("Transfer WIP Item", true);
        TransferLine.Validate(Quantity, WIPQty);

        if ProdOrderRoutingLine."Transfer Description" <> '' then
            TransferLine.Description := ProdOrderRoutingLine."Transfer Description";

        if ProdOrderRoutingLine."Transfer Description 2" <> '' then
            TransferLine."Description 2" := ProdOrderRoutingLine."Transfer Description 2";

        TransferLine."Subcontr. Purch. Order No." := PurchaseLine."Document No.";
        TransferLine."Subcontr. PO Line No." := PurchaseLine."Line No.";
        TransferLine."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        TransferLine."Prod. Order Line No." := ProdOrderLine."Line No.";
        TransferLine."Routing No." := ProdOrderRoutingLine."Routing No.";
        TransferLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        TransferLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
        TransferLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        TransferLine."Prev. Operation No." := WIPPreviousOperationNo;

        TransferLine.Modify();
    end;

    local procedure GetWIPTransferFromLocations(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var WIPSourceLocationList: List of [Code[10]]; var WIPSourceQtyDict: Dictionary of [Code[10], Decimal]; var WIPPreviousOperationNoDict: Dictionary of [Code[10], Code[10]])
    var
        PrevProdOrderRoutingLine: Record "Prod. Order Routing Line";
        LocCode: Code[10];
        WIPQtyBase: Decimal;
        IsSerial, TransferWIPItem, FoundSubcontractingPrevOp : Boolean;
        WIPItemTransferDifferentErr: Label 'Field ''''%1'''' must have the same value for all previous operations of the routing.', Comment = '%1=Transfer WIP Item';
    begin
        // No previous operation: initial transfer directly from Prod. Order Line location
        if ProdOrderRoutingLine."Previous Operation No." = '' then begin
            LocCode := ProdOrderLine."Location Code";
            if LocCode <> '' then begin
                WIPSourceLocationList.Add(LocCode);
                WIPSourceQtyDict.Add(LocCode, ProdOrderLine."Quantity (Base)");
                WIPPreviousOperationNoDict.Add(LocCode, '');
            end;
            exit;
        end;

        IsSerial := ProdOrderRoutingLine.IsSerial();

        PrevProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        PrevProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        PrevProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        PrevProdOrderRoutingLine.SetFilter("Operation No.", ProdOrderRoutingLine."Previous Operation No.");
        PrevProdOrderRoutingLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        PrevProdOrderRoutingLine.SetLoadFields("Operation No.", "Transfer WIP Item");
        PrevProdOrderRoutingLine.SetAutoCalcFields(Subcontracting);
        if PrevProdOrderRoutingLine.FindSet() then
            repeat
                if not FoundSubcontractingPrevOp then begin
                    TransferWIPItem := PrevProdOrderRoutingLine."Transfer WIP Item";
                    FoundSubcontractingPrevOp := true;
                end else
                    if TransferWIPItem <> PrevProdOrderRoutingLine."Transfer WIP Item" then
                        Error(WIPItemTransferDifferentErr, PrevProdOrderRoutingLine.FieldCaption("Transfer WIP Item"));

                GetWIPLocationAndQtyForPreviousOp(
                    ProdOrderLine, PrevProdOrderRoutingLine, IsSerial, LocCode, WIPQtyBase);

                if (LocCode <> '') and (WIPQtyBase > 0) and (not WIPSourceQtyDict.ContainsKey(LocCode)) then begin
                    WIPSourceLocationList.Add(LocCode);
                    WIPSourceQtyDict.Add(LocCode, WIPQtyBase);
                    WIPPreviousOperationNoDict.Add(LocCode, PrevProdOrderRoutingLine."Operation No.");
                end;
            until PrevProdOrderRoutingLine.Next() = 0;

        if WIPSourceLocationList.Count() = 0 then begin
            LocCode := ProdOrderLine."Location Code";
            if LocCode <> '' then begin
                WIPSourceLocationList.Add(LocCode);
                WIPSourceQtyDict.Add(LocCode, ProdOrderLine."Quantity (Base)");
                WIPPreviousOperationNoDict.Add(LocCode, '');
            end;
        end;
    end;

    local procedure GetWIPLocationAndQtyForPreviousOp(ProdOrderLine: Record "Prod. Order Line"; PrevProdOrderRoutingLine: Record "Prod. Order Routing Line"; IsSerial: Boolean; var LocationCode: Code[10]; var WIPQtyBase: Decimal)
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        PrevVendor: Record Vendor;
        PrevWorkCenter: Record "Work Center";
    begin
        LocationCode := ProdOrderLine."Location Code";
        WIPQtyBase := ProdOrderLine."Quantity (Base)";

        if PrevProdOrderRoutingLine."Transfer WIP Item" then begin
            // Previous op has a subcontracting WIP transfer
            PrevWorkCenter.SetLoadFields("Subcontractor No.");
            if PrevWorkCenter.Get(PrevProdOrderRoutingLine."Work Center No.") then
                if PrevWorkCenter."Subcontractor No." <> '' then begin
                    PrevVendor.SetLoadFields("Subcontr. Location Code");
                    if PrevVendor.Get(PrevWorkCenter."Subcontractor No.") then
                        if PrevVendor."Subcontr. Location Code" <> '' then
                            LocationCode := PrevVendor."Subcontr. Location Code";
                end;

            if LocationCode <> '' then begin
                WIPLedgerEntry.SetRange("Prod. Order Status", "Production Order Status"::Released);
                WIPLedgerEntry.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                WIPLedgerEntry.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                WIPLedgerEntry.SetRange("Routing No.", PrevProdOrderRoutingLine."Routing No.");
                WIPLedgerEntry.SetRange("Routing Reference No.", PrevProdOrderRoutingLine."Routing Reference No.");
                WIPLedgerEntry.SetRange("Operation No.", PrevProdOrderRoutingLine."Operation No.");
                WIPLedgerEntry.SetRange("Location Code", LocationCode);
                WIPLedgerEntry.SetRange("In Transit", false);
                WIPLedgerEntry.CalcSums("Quantity (Base)");
            end;
        end;

        // Parallel routings always use Prod. Order Line quantity as preset
        if IsSerial and (WIPLedgerEntry."Quantity (Base)" <> 0) then
            WIPQtyBase := WIPLedgerEntry."Quantity (Base)";
    end;

    local procedure CheckCreateWIPTransfer(PurchaseLine: Record "Purchase Line"): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseHeader: Record "Purchase Header";
        SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        TransferLineToCheck: Record "Transfer Line";
        VendorFromPurchOrder: Record Vendor;
        LocCode: Code[10];
        TransferToLocationCode: Code[10];
        ExpectedQtyBase: Decimal;
        PostedWIPQtyBase: Decimal;
        WIPPreviousOperationNoDict: Dictionary of [Code[10], Code[10]];
        WIPSourceQtyDict: Dictionary of [Code[10], Decimal];
        WIPSourceLocationList: List of [Code[10]];
    begin
        TransferLineToCheck.SetCurrentKey("Prod. Order No.", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.");
        TransferLineToCheck.SetRange("Subcontr. Purch. Order No.", PurchaseLine."Document No.");
        TransferLineToCheck.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        TransferLineToCheck.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        TransferLineToCheck.SetRange("Operation No.", PurchaseLine."Operation No.");
        TransferLineToCheck.SetRange("Derived From Line No.", 0);
        TransferLineToCheck.SetRange("Transfer WIP Item", true);
        if not TransferLineToCheck.IsEmpty() then
            exit(false);

        if not ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);

        if not ProdOrderRoutingLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.") then
            exit(false);

        if not ProdOrderRoutingLine."Transfer WIP Item" then
            exit(false);

        GetWIPTransferFromLocations(ProdOrderLine, ProdOrderRoutingLine, WIPSourceLocationList, WIPSourceQtyDict, WIPPreviousOperationNoDict);

        ExpectedQtyBase := 0;
        foreach LocCode in WIPSourceLocationList do
            ExpectedQtyBase += WIPSourceQtyDict.Get(LocCode);

        if ExpectedQtyBase = 0 then
            exit(false);

        if not PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
            exit(false);

        if not VendorFromPurchOrder.Get(PurchaseHeader."Buy-from Vendor No.") then
            exit(false);

        GetTransferToLocationCodeForPurchaseHeader(PurchaseHeader, VendorFromPurchOrder, TransferToLocationCode);

        if TransferToLocationCode = '' then
            exit(false);

        SubcontractorWIPLedgerEntry.SetRange("Prod. Order Status", "Production Order Status"::Released);
        SubcontractorWIPLedgerEntry.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        SubcontractorWIPLedgerEntry.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        SubcontractorWIPLedgerEntry.SetRange("Routing No.", PurchaseLine."Routing No.");
        SubcontractorWIPLedgerEntry.SetRange("Routing Reference No.", PurchaseLine."Routing Reference No.");
        SubcontractorWIPLedgerEntry.SetRange("Operation No.", PurchaseLine."Operation No.");
        SubcontractorWIPLedgerEntry.SetRange("Location Code", TransferToLocationCode);
        SubcontractorWIPLedgerEntry.SetRange("In Transit", false);
        SubcontractorWIPLedgerEntry.CalcSums("Quantity (Base)");
        PostedWIPQtyBase := SubcontractorWIPLedgerEntry."Quantity (Base)";

        if WIPPreviousOperationNoDict.Keys().Count() > 1 then
            foreach LocCode in WIPPreviousOperationNoDict.Keys() do
                if LocCode <> '' then
                    exit(ExpectedQtyBase > 0);

        exit(PostedWIPQtyBase < ExpectedQtyBase);
    end;
}