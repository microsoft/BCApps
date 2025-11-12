// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Document;

tableextension 99000800 "Mfg. Inventory Adjmt. Entry" extends "Inventory Adjmt. Entry (Order)"
{
    fields
    {
        field(7; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header"."No.";
        }
        field(8; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            DataClassification = CustomerContent;
        }
    }

    [InherentPermissions(PermissionObjectType::TableData, Database::"Inventory Adjmt. Entry (Order)", 'I')]
    procedure SetProdOrderLine(ProdOrderLine: Record "Prod. Order Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetProdOrderLine(Rec, ProdOrderLine, IsHandled);
        if IsHandled then
            exit;

        Init();
        "Order Type" := "Order Type"::Production;
        "Order No." := ProdOrderLine."Prod. Order No.";
        "Order Line No." := ProdOrderLine."Line No.";
        "Item No." := ProdOrderLine."Item No.";
        "Routing No." := ProdOrderLine."Routing No.";
        "Routing Reference No." := ProdOrderLine."Routing Reference No.";
        "Cost is Adjusted" := false;
        "Is Finished" := ProdOrderLine.Status = ProdOrderLine.Status::Finished;
        "Indirect Cost %" := ProdOrderLine."Indirect Cost %";
        "Overhead Rate" := ProdOrderLine."Overhead Rate";
        OnAfterSetProdOrderLineTransferFields(Rec, ProdOrderLine);

        GetUnitCostsFromProdOrderLine();
        if not Insert() then;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetProdOrderLineTransferFields(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetProdOrderLine(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;
}
