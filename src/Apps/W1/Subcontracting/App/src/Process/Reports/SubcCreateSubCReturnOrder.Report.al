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
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

report 99001502 "Subc. Create SubCReturnOrder"
{
    ApplicationArea = Manufacturing;
    Caption = 'Create Subcontracting Return Order';
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
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") order(ascending) where("Prod. Order No." = filter(<> ''));
                trigger OnAfterGetRecord()
                var
                    QtyToPost: Decimal;
                begin
                    HandleComponentReturnForPurchLine("Purchase Line", true, QtyToPost);
                    HandleWIPReturnForPurchLine("Purchase Line", true);
                end;
            }
            trigger OnAfterGetRecord()
            begin
                "Purchase Header".CalcFields("Subcontracting Order");
                if not "Subcontracting Order" then
                    Error(OrderNoIsNotSubcontractorErr, PurchOrderNo);

                if not CheckTransferToCreate() then
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
        SubcManagementSetup: Record "Subc. Management Setup";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        PurchOrderNo: Code[20];
        LineNo: Integer;
        NothingToCreateErr: Label 'Nothing to create. No components or WIP items to return for the specified subcontracting order.';
        OrderNoDoesNotExistInProdOrderErr: Label 'Operation %1 in the subcontracting order %2 does not exist in the routing %3 of the production order %4.', Comment = '%1=Operation No., %2=Purchase Order No., %3=Routing No., %4=Production Order No.';
        OrderNoIsNotSubcontractorErr: Label 'Order %1 is not a Subcontractor work.', Comment = '%1=Purchase Order No.';
        WarningToSpecifyPurchOrderErr: Label 'Warning. Specify a Purchase Order No. for the Subcontractor work.';

    local procedure InsertTransferHeader(TransferFromLocationCode: Code[10]; TransferToLocationCode: Code[10])
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
        TransferRoute: Record "Transfer Route";
    begin
        if not SubcManagementSetup.Get() then
            Clear(SubcManagementSetup);

        TransferHeader.Reset();
        TransferHeader.SetRange("Source Subtype", TransferHeader."Source Subtype"::"2");
        TransferHeader.SetRange("Source ID", "Purchase Header"."Buy-from Vendor No.");
        TransferHeader.SetRange(Status, TransferHeader.Status::Open);
        TransferHeader.SetRange("Completely Shipped", false);
        TransferHeader.SetRange("Transfer-from Code", TransferFromLocationCode);
        TransferHeader.SetRange("Transfer-to Code", TransferToLocationCode);
        TransferHeader.SetRange("Return Order", true);
        if not TransferHeader.FindFirst() then begin
            TransferHeader.Init();
            TransferHeader."No." := '';
            TransferHeader.Insert(true);

            TransferHeader.Validate("Transfer-from Code", TransferFromLocationCode);
            TransferHeader.Validate("Transfer-to Code", TransferToLocationCode);

            if SubcManagementSetup."Direct Transfer" or (not TransferRoute.Get(TransferFromLocationCode, TransferToLocationCode)) or (TransferRoute."In-Transit Code" = '') then begin
                SubcontractingManagement.CheckDirectTransferIsAllowedForTransferHeader(TransferHeader);
                TransferHeader.Validate("Direct Transfer", true);
            end;

            TransferHeader."Source Type" := TransferHeader."Source Type"::Subcontracting;
            TransferHeader."Source Subtype" := TransferHeader."Source Subtype"::"2";
            TransferHeader."Source ID" := "Purchase Header"."Buy-from Vendor No.";
            TransferHeader."Subcontr. Purch. Order No." := "Purchase Header"."No.";
            TransferHeader."Subcontr. PO Line No." := "Purchase Line"."Line No.";
            TransferHeader."Return Order" := true;
            TransferHeader."Transfer-from Name" := Vendor.Name;
            TransferHeader."Transfer-from Name 2" := Vendor."Name 2";
            TransferHeader."Transfer-from Address" := Vendor.Address;
            TransferHeader."Transfer-from Address 2" := Vendor."Address 2";
            TransferHeader."Transfer-from Post Code" := Vendor."Post Code";
            TransferHeader."Transfer-from City" := Vendor.City;
            TransferHeader."Transfer-from County" := Vendor.County;
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

    local procedure CheckTransferToCreate(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        QtyToPost: Decimal;
    begin
        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchaseLine.SetRange("Document No.", PurchOrderNo);
        PurchaseLine.SetFilter("Prod. Order No.", '<>''''');
        PurchaseLine.SetFilter("Prod. Order Line No.", '<>0');
        PurchaseLine.SetFilter("Operation No.", '<>0');
        if PurchaseLine.FindSet() then
            repeat
                if HandleComponentReturnForPurchLine(PurchaseLine, false, QtyToPost) then
                    exit(true);
                if HandleWIPReturnForPurchLine(PurchaseLine, false) then
                    exit(true);
            until PurchaseLine.Next() = 0;

        exit(false);
    end;

    local procedure HandleComponentReturnForPurchLine(PurchaseLine: Record "Purchase Line"; InsertLine: Boolean; var QtyToPost: Decimal): Boolean
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        SubcontractingManagement: Codeunit "Subcontracting Management";
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
        SubcFromLocationCode: Code[10];
        QtyPerUom: Decimal;
    begin
        if not ProdOrderLine.Get(ProdOrderLine.Status::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);

        if not ProdOrderRoutingLine.Get(ProdOrderRoutingLine.Status::Released, PurchaseLine."Prod. Order No.",
             PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.")
        then
            Error(OrderNoDoesNotExistInProdOrderErr, PurchaseLine."Operation No.", PurchOrderNo, PurchaseLine."Routing No.", PurchaseLine."Prod. Order No.");

        if TransferLineAlreadyExists() then
            exit(false);

        Item.SetLoadFields("Base Unit of Measure", "Rounding Precision");
        Item.Get(PurchaseLine."No.");
        QtyPerUom := UnitofMeasureManagement.GetQtyPerUnitOfMeasure(Item, PurchaseLine."Unit of Measure Code");

        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.SetRange("Purchase Order Filter", PurchaseLine."Document No.");
        ProdOrderComponent.SetRange("Subcontracting Type", ProdOrderComponent."Subcontracting Type"::Transfer);
        if ProdOrderComponent.FindSet() then begin
            GetTransferFromLocationCode(SubcFromLocationCode);
            repeat
                Item.Get(ProdOrderComponent."Item No.");
                QtyToPost := MfgCostCalculationMgt.CalcActNeededQtyBase(ProdOrderLine, ProdOrderComponent,
                    Round(PurchaseLine."Outstanding Quantity" * QtyPerUom, UnitofMeasureManagement.QtyRndPrecision()));
                ProdOrderComponent.CalcFields("Qty. in Transit (Base)", "Qty. transf. to Subcontr");
                if QtyToPost > (Abs(ProdOrderComponent."Qty. in Transit (Base)") + Abs(ProdOrderComponent."Qty. transf. to Subcontr")) then
                    QtyToPost := (Abs(ProdOrderComponent."Qty. in Transit (Base)") + Abs(ProdOrderComponent."Qty. transf. to Subcontr"));
                if QtyToPost > 0 then
                    if InsertLine then begin

                        InsertTransferHeader(SubcFromLocationCode, ProdOrderComponent."Orig. Location Code");

                        LineNo := LineNo + 10000;

                        TransferLine.Init();
                        TransferLine."Document No." := TransferHeader."No.";
                        TransferLine."Line No." := LineNo;
                        TransferLine.Validate("Item No.", ProdOrderComponent."Item No.");
                        TransferLine.Validate("Variant Code", ProdOrderComponent."Variant Code");
                        TransferLine."Unit of Measure Code" := ProdOrderComponent."Unit of Measure Code";
                        TransferLine."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
                        TransferLine.Validate(Quantity, Round(QtyToPost / ProdOrderComponent."Qty. per Unit of Measure", Item."Rounding Precision", '>'));
                        TransferLine."Subcontr. Purch. Order No." := PurchaseLine."Document No.";
                        TransferLine."Subcontr. PO Line No." := PurchaseLine."Line No.";
                        TransferLine."Prod. Order No." := PurchaseLine."Prod. Order No.";
                        TransferLine."Prod. Order Line No." := PurchaseLine."Prod. Order Line No.";
                        TransferLine."Prod. Order Comp. Line No." := ProdOrderComponent."Line No.";

                        TransferLine."Routing No." := ProdOrderRoutingLine."Routing No.";
                        TransferLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
                        TransferLine."Work Center No." := ProdOrderRoutingLine."Work Center No.";
                        TransferLine."Operation No." := ProdOrderRoutingLine."Operation No.";

                        TransferLine."Return Order" := true;

                        TransferLine.Insert();

                        SubcontractingManagement.TransferReservationEntryFromProdOrderCompToTransferOrder(TransferLine, ProdOrderComponent);

                        if ProdOrderComponent."Orig. Location Code" = '' then
                            ProdOrderComponent."Orig. Location Code" := ProdOrderComponent."Location Code";
                        if ProdOrderComponent."Orig. Bin Code" = '' then
                            ProdOrderComponent."Orig. Bin Code" := ProdOrderComponent."Bin Code";
                        if TransferHeader."Transfer-to Code" <> ProdOrderComponent."Location Code" then begin
                            ProdOrderComponent.Validate("Location Code", TransferHeader."Transfer-to Code");
                            ProdOrderComponent.GetDefaultBin();
                        end;
                        ProdOrderComponent.Modify();

                        SubcontractingManagement.CreateReservEntryForTransferReceiptToProdOrderComp(TransferLine, ProdOrderComponent);
                    end else
                        exit(true);
            until ProdOrderComponent.Next() = 0;
        end;
        exit(false);
    end;

    local procedure ShowDocument()
    var
        SubcPurchFactboxMgmt: Codeunit "Subc. Purch. Factbox Mgmt.";
    begin
        Commit(); // Used for following call of Transfer Pages

        SubcPurchFactboxMgmt.ShowTransferOrdersAndReturnOrder("Purchase Line", true, true);
    end;

    local procedure TransferLineAlreadyExists(): Boolean
    var
        TransferLine2: Record "Transfer Line";
    begin
        if "Purchase Line"."Document No." = '' then
            exit(false);
        TransferLine2.SetRange("Subcontr. Purch. Order No.", "Purchase Line"."Document No.");
        TransferLine2.SetRange("Subcontr. PO Line No.", "Purchase Line"."Line No.");
        TransferLine2.SetRange("Prod. Order No.", "Purchase Line"."Prod. Order No.");
        TransferLine2.SetRange("Prod. Order Line No.", "Purchase Line"."Prod. Order Line No.");
        if not TransferLine2.IsEmpty() then
            exit(false);
    end;

    local procedure GetTransferFromLocationCode(var TransferToLocationCode: Code[10])
    begin
        TransferToLocationCode := "Purchase Header"."Subc. Location Code";
        if TransferToLocationCode = '' then begin
            TransferToLocationCode := Vendor."Subcontr. Location Code";
            if TransferToLocationCode = '' then
                Vendor.TestField("Subcontr. Location Code");
        end;
    end;

    local procedure HandleWIPReturnForPurchLine(PurchaseLine: Record "Purchase Line"; InsertLine: Boolean): Boolean
    var
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        UOMManagement: Codeunit "Unit of Measure Management";
        CompanyWHLocationCode: Code[10];
        TransferFromLoc: Code[10];
        WIPQtyBase: Decimal;
        WIPQtyInUOM: Decimal;
        WIPSourceQtyDict: Dictionary of [Code[10], Decimal];
        WIPSourceLocationList: List of [Code[10]];
    begin
        if not ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);

        if not ProdOrderRoutingLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.",
                PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.")
        then
            exit(false);

        if not ProdOrderRoutingLine."Transfer WIP Item" then
            exit(false);

        if WIPReturnTransferLineAlreadyExists(PurchaseLine) then
            exit(false);

        CompanyWHLocationCode := ProdOrderLine."Location Code";
        GetWIPReturnFromLocations(ProdOrderLine, ProdOrderRoutingLine, WIPSourceLocationList, WIPSourceQtyDict);

        if WIPSourceLocationList.Count() = 0 then
            exit(false);

        if not InsertLine then
            exit(true);

        Item.SetLoadFields("Base Unit of Measure", "Rounding Precision", Description, "Description 2");
        Item.Get(ProdOrderLine."Item No.");

        foreach TransferFromLoc in WIPSourceLocationList do begin
            WIPQtyBase := WIPSourceQtyDict.Get(TransferFromLoc);
            if ProdOrderLine."Qty. per Unit of Measure" <> 0 then
                WIPQtyInUOM := Round(WIPQtyBase / ProdOrderLine."Qty. per Unit of Measure", UOMManagement.QtyRndPrecision())
            else
                WIPQtyInUOM := Round(WIPQtyBase, UOMManagement.QtyRndPrecision());
            if WIPQtyInUOM > 0 then begin
                InsertTransferHeader(TransferFromLoc, CompanyWHLocationCode);
                InsertWIPReturnTransferLine(PurchaseLine, ProdOrderLine, ProdOrderRoutingLine, WIPQtyInUOM);
            end;
        end;

        exit(false);
    end;

    local procedure GetWIPReturnFromLocations(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var WIPSourceLocationList: List of [Code[10]]; var WIPSourceQtyList: Dictionary of [Code[10], Decimal])
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
        LocationCode: Code[10];
    begin
        WIPLedgerEntry.SetRange("Prod. Order Status", "Production Order Status"::Released);
        WIPLedgerEntry.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        WIPLedgerEntry.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        WIPLedgerEntry.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        WIPLedgerEntry.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        WIPLedgerEntry.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        WIPLedgerEntry.SetRange("In Transit", false);
        if WIPLedgerEntry.FindSet() then
            repeat
                LocationCode := WIPLedgerEntry."Location Code";
                if WIPSourceQtyList.ContainsKey(LocationCode) then
                    WIPSourceQtyList.Set(LocationCode, WIPSourceQtyList.Get(LocationCode) + WIPLedgerEntry."Quantity (Base)")
                else begin
                    WIPSourceLocationList.Add(LocationCode);
                    WIPSourceQtyList.Add(LocationCode, WIPLedgerEntry."Quantity (Base)");
                end;
            until WIPLedgerEntry.Next() = 0;
    end;

    local procedure InsertWIPReturnTransferLine(PurchaseLine: Record "Purchase Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WIPQty: Decimal)
    begin
        LineNo := LineNo + 10000;

        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := LineNo;
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
        TransferLine."Return Order" := true;

        TransferLine.Insert();
    end;

    local procedure WIPReturnTransferLineAlreadyExists(PurchaseLine: Record "Purchase Line"): Boolean
    var
        TransferLineToCheck: Record "Transfer Line";
    begin
        TransferLineToCheck.SetRange("Subcontr. Purch. Order No.", PurchaseLine."Document No.");
        TransferLineToCheck.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        TransferLineToCheck.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        TransferLineToCheck.SetRange("Operation No.", PurchaseLine."Operation No.");
        TransferLineToCheck.SetRange("Transfer WIP Item", true);
        TransferLineToCheck.SetRange("Return Order", true);
        exit(not TransferLineToCheck.IsEmpty());
    end;
}