// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Inventory.Journal;
using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;

codeunit 7350 "Mfg. Put Away Helper"
{
    var
        CanCreateProdPutAwayQst: Label 'Do you want to create Warehouse Put Away for Production Order with Status %1, No. %2 ?', Comment = '%1 = Production Order Status, %2 = Production Order No.';

    procedure IsLastOperation(ItemJnlLine: Record "Item Journal Line"): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderLine.SetLoadFields(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.");
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ItemJnlLine."Order No.", ItemJnlLine."Order Line No.");

        ProdOrderRoutingLine.SetLoadFields("Next Operation No.");
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetRange(Type, ItemJnlLine.Type);
        ProdOrderRoutingLine.SetRange("No.", ItemJnlLine."No.");
        if ProdOrderRoutingLine.FindFirst() then
            exit(ProdOrderRoutingLine."Next Operation No." = '')
        else
            exit(true);
    end;

    procedure DeleteBlankBinContent(WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetBaseLoadFields();
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.DeleteBinContent(WarehouseActivityLine."Action Type"::Place.AsInteger());
            until WarehouseActivityLine.Next() = 0;
    end;

    procedure CanCreateProdWhsePutAway(var ProdOrder: Record "Production Order"): Boolean
    begin
        if not GuiAllowed() then
            exit(true);

        exit(Confirm(StrSubstNo(CanCreateProdPutAwayQst, ProdOrder.Status, ProdOrder."No."), false));
    end;

    procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemJnlLine: Record "Item Journal Line")
    begin
        ProdOrderLine.SetBaseLoadFields();
        ProdOrderLine.SetRange("Prod. Order No.", ItemJnlLine."Order No.");
        ProdOrderLine.SetRange("Line No.", ItemJnlLine."Order Line No.");
        ProdOrderLine.SetFilter(Status, '%1|%2', ProdOrderLine.Status::Released, ProdOrderLine.Status::Finished);
        ProdOrderLine.FindFirst();
    end;

    procedure CreateWhsePutAwayRequestForProdOutput(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line")
    var
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        Bin: Record Bin;
    begin
        WhsePutAwayRequest."Document Type" := WhsePutAwayRequest."Document Type"::Production;
        WhsePutAwayRequest."Document No." := ProdOrder."No.";
        WhsePutAwayRequest."Location Code" := ProdOrderLine."Location Code";
        WhsePutAwayRequest."Bin Code" := ProdOrderLine."Bin Code";
        if Bin.Get(ProdOrderLine."Location Code", ProdOrderLine."Bin Code") then
            WhsePutAwayRequest."Zone Code" := Bin."Zone Code";
        if WhsePutAwayRequest.Insert() then;
    end;
}
