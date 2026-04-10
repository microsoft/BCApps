// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Integration.Entity;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 5528 "Graph Mgt - Purch. Inv. Lines"
{

    trigger OnRun()
    begin
    end;

    procedure GetUnitOfMeasureJSON(var PurchInvLineAggregate: Record "Purch. Inv. Line Aggregate"): Text
    var
        Item: Record Item;
        GraphCollectionMgtItem: Codeunit "Graph Collection Mgt - Item";
        GraphMgtComplexTypes: Codeunit "Graph Mgt - Complex Types";
        UnitOfMeasureJSON: Text;
    begin
        if PurchInvLineAggregate."No." = '' then
            exit;

        case PurchInvLineAggregate.Type of
            PurchInvLineAggregate.Type::Item:
                begin
                    if not Item.Get(PurchInvLineAggregate."No.") then
                        exit;

                    UnitOfMeasureJSON := GraphCollectionMgtItem.ItemUnitOfMeasureToJSON(Item, PurchInvLineAggregate."Unit of Measure Code");
                end;
            else
                UnitOfMeasureJSON := GraphMgtComplexTypes.GetUnitOfMeasureJSON(PurchInvLineAggregate."Unit of Measure Code");
        end;

        exit(UnitOfMeasureJSON);
    end;

    [Scope('Cloud')]
    procedure GetPurchaseOrderDocumentIdFilterFromSystemId(Id: Guid): Text
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
    begin
        if not PurchaseLine.GetBySystemId(Id) then
            exit(' ');
        PurchaseOrderEntityBuffer.Get(PurchaseLine."Document No.");
        exit(Format(PurchaseOrderEntityBuffer.Id));
    end;

    [Scope('Cloud')]
    procedure GetPurchaseCreditMemoDocumentIdFilterFromSystemId(Id: Guid): Text
    var
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
    begin
        if PurchCrMemoLine.GetBySystemId(Id) then
            if PurchCrMemoEntityBuffer.Get(PurchCrMemoLine."Document No.", true) then
                exit(Format(PurchCrMemoEntityBuffer.Id));
        if PurchaseLine.GetBySystemId(Id) then
            if PurchCrMemoEntityBuffer.Get(PurchaseLine."Document No.", false) then
                exit(Format(PurchCrMemoEntityBuffer.Id));
        exit(' ');
    end;
}

