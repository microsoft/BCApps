// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Posting;

codeunit 99001546 "Subc. Whse Direct Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Act.-Post (Yes/No)", OnBeforeSelectForOtherTypes, '', false, false)]
    local procedure OnBeforeSelectForOtherTypes(var WhseActivLine: Record "Warehouse Activity Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
        WhseActYesNoQuestion(WhseActivLine, Result, IsHandled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", OnBeforeCode, '', false, false)]
    local procedure OnBeforeCode_WhseActivityPost(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SuppressCommit: Boolean; var IsHandled: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        if SuppressCommit then
            exit;
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        SuppressCommit := PostInboundTransferInOneStep(WarehouseActivityHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", OnBeforeCheckWhseShptLines, '', false, false)]
    local procedure OnBeforeCheckWhseShptLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; Invoice: Boolean; var SuppressCommit: Boolean)
    var
        TransferHeader: Record "Transfer Header";
    begin
        if SuppressCommit then
            exit;
        if WarehouseShipmentLine."Source Document" <> "Warehouse Activity Source Document"::"Outbound Transfer" then
            exit;
        TransferHeader.Get(WarehouseShipmentLine."Source No.");
        SuppressCommit := IsDirectTransfer(TransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", OnBeforeTransferOrderPostShipment, '', false, false)]
    local procedure OnBeforeTransferOrderPostShipment(var Sender: Codeunit "TransferOrder-Post Shipment"; var TransferHeader: Record "Transfer Header"; var CommitIsSuppressed: Boolean)
    begin
        if CommitIsSuppressed then
            exit;
        CommitIsSuppressed := IsDirectTransfer(TransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", OnAfterPostWhseActivHeader, '', false, false)]
    local procedure OnAfterPostWhseActivHeader(WhseActivHeader: Record "Warehouse Activity Header"; var PurchaseHeader: Record "Purchase Header"; var SalesHeader: Record "Sales Header"; var TransferHeader: Record "Transfer Header")
    begin
        if not PostInboundTransferInOneStep(WhseActivHeader) then
            exit;

        PostRelatedInboundTransfer(TransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Transfer Whse. Post Shipment", OnAfterTransferPostShipment, '', false, false)]
    local procedure OnAfterTransferPostShipment(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; TransferHeader: Record "Transfer Header")
    begin
        if IsDirectTransfer(TransferHeader) then
            PostRelatedInboundTransfer(TransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Transfer Whse. Post Shipment", OnBeforeTryPostSourceTransferDocument, '', false, false)]
    local procedure OnBeforeTryPostSourceTransferDocument(var TransferPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;
        if not IsDirectTransfer(TransHeader) then
            exit;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Transfer Whse. Post Shipment", OnAfterTryPostSourceTransferDocument, '', false, false)]
    local procedure OnAfterTryPostSourceTransferDocument(var CounterSourceDocOK: Integer; var TransferPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransHeader: Record "Transfer Header"; Result: Boolean)
    begin
        PostDirectTransferInTryPosting(CounterSourceDocOK, TransferPostShipment, TransHeader, Result);
    end;

    local procedure PostDirectTransferInTryPosting(var CounterSourceDocOK: Integer; var TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransferHeader: Record "Transfer Header"; Result: Boolean)
    begin
        if Result then
            exit;
        if IsDirectTransfer(TransferHeader) then begin
            TransferOrderPostShipment.Run(TransferHeader);
            CounterSourceDocOK := CounterSourceDocOK + 1;
        end;
    end;

    local procedure PostInboundTransferInOneStep(var WarehouseActivityHeader: Record "Warehouse Activity Header"): Boolean
    var
        TransferHeader: Record "Transfer Header";
    begin
        if WarehouseActivityHeader."Source Type" <> Database::"Transfer Line" then
            exit(false);
        if WarehouseActivityHeader.Type = "Warehouse Activity Type"::"Invt. Put-away" then
            exit(false);
        TransferHeader.SetLoadFields("Direct Transfer", "Transfer-to Code", "Direct Transfer Posting");
        TransferHeader.Get(WarehouseActivityHeader."Source No.");
        exit(IsDirectTransfer(TransferHeader));
    end;

    local procedure IsDirectTransfer(var TransferHeader: Record "Transfer Header"): Boolean
    begin
        if TransferHeader."Direct Transfer" then
            exit(false);
        if InboundWhseHandlingOnLocation(TransferHeader."Transfer-to Code") then
            exit(false);
        if TransferHeader."Direct Transfer Posting" in ["Direct Transfer Post. Type"::Empty, "Direct Transfer Post. Type"::"Direct Transfer"] then
            exit(false);
        exit(true);
    end;

    procedure InboundWhseHandlingOnLocation(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        Location.SetLoadFields("Require Put-away", "Require Receive");
        Location.Get(LocationCode);
        exit(Location."Require Put-away" or Location."Require Receive");
    end;

    local procedure PostRelatedInboundTransfer(var TransferHeader: Record "Transfer Header")
    var
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
    begin
        TransferOrderPostReceipt.SetSuppressCommit(true);
        TransferOrderPostReceipt.SetHideValidationDialog(true);
        TransferOrderPostReceipt.Run(TransferHeader);
    end;

    local procedure WhseActYesNoQuestion(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Result: Boolean; var IsHandled: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PostingQst: Label 'Do you want to post the %1 for the %2 and the %3?', Comment = '%1=Activity Type, %2=Source Document, %3=Target Document';
    begin
        if WarehouseActivityLine."Source Document" <> "Warehouse Activity Source Document"::"Outbound Transfer" then
            exit;
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        if not PostInboundTransferInOneStep(WarehouseActivityHeader) then
            exit;

        Result := Confirm(PostingQst, false, WarehouseActivityLine."Activity Type", WarehouseActivityLine."Source Document", "Warehouse Activity Source Document"::"Inbound Transfer");
        IsHandled := true;
    end;
}