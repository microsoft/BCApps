// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;

codeunit 5708 "Release Transfer Document"
{
    TableNo = "Transfer Header";
    Permissions = TableData "Transfer Header" = rm;

    trigger OnRun()
    begin
        TransferHeader.Copy(Rec);
        Code();
        Rec := TransferHeader;
    end;

    local procedure Code()
    var
        TransLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        if TransferHeader.Status = TransferHeader.Status::Released then
            exit;

        OnBeforeReleaseTransferDoc(TransferHeader);

        TransferHeader.TestField("Transfer-from Code");
        TransferHeader.TestField("Transfer-to Code");

        IsHandled := false;
        OnBeforeCheckTransferCode(TransferHeader, IsHandled);
        if not IsHandled then
            if TransferHeader."Transfer-from Code" = TransferHeader."Transfer-to Code" then
                Error(Text001, TransferHeader."No.", TransferHeader.FieldCaption("Transfer-from Code"), TransferHeader.FieldCaption("Transfer-to Code"));

        InvtSetup.Get();
        IsHandled := false;
        OnBeforeCheckTransitLocations(TransferHeader, IsHandled);
        if not IsHandled then
            if not TransferHeader."Direct Transfer" then
                TransferHeader.TestField("In-Transit Code")
            else
                if InvtSetup."Direct Transfer Posting" = InvtSetup."Direct Transfer Posting"::"Receipt and Shipment" then begin
                    TransferHeader.VerifyNoOutboundWhseHandlingOnLocation(TransferHeader."Transfer-from Code");
                    TransferHeader.VerifyNoInboundWhseHandlingOnLocation(TransferHeader."Transfer-to Code");
                end;

        TransferHeader.TestField(Status, TransferHeader.Status::Open);

        CheckTransLines(TransLine, TransferHeader);

        IsHandled := false;
        OnRunOnBeforeSetStatusReleased(TransferHeader, IsHandled);
        if IsHandled then
            exit;

        TransferHeader.Validate(Status, TransferHeader.Status::Released);
        TransferHeader.Modify();

        if not (
            TransferHeader."Direct Transfer" and
            (InvtSetup."Direct Transfer Posting" = InvtSetup."Direct Transfer Posting"::"Direct Transfer"))
        then
            WhseTransferRelease.SetCallFromTransferOrder(true);

        WhseTransferRelease.Release(TransferHeader);

        OnAfterReleaseTransferDoc(TransferHeader);
    end;

    var
        TransferHeader: Record "Transfer Header";
        InvtSetup: Record "Inventory Setup";
        WhseTransferRelease: Codeunit "Whse.-Transfer Release";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The transfer order %1 cannot be released because %2 and %3 are the same.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        NothingToReleaseErr: Label 'There is nothing to release for transfer order %1.';
#pragma warning restore AA0470

    procedure Reopen(var TransHeader: Record "Transfer Header")
    begin
        if TransHeader.Status = TransHeader.Status::Open then
            exit;

        OnBeforeReopenTransferDoc(TransHeader);
        WhseTransferRelease.Reopen(TransHeader);
        TransHeader.Validate(Status, TransHeader.Status::Open);
        TransHeader.Modify();

        OnAfterReopenTransferDoc(TransHeader);
    end;

    procedure Release(var TransHeader: Record "Transfer Header")
    begin
        if TransHeader.Status = TransHeader.Status::Released then
            exit;

        TransferHeader.Copy(TransHeader);
        Code();
        TransHeader := TransferHeader;
    end;

    local procedure CheckTransLines(var TransLine: Record "Transfer Line"; TransHeader: Record "Transfer Header")
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTransLines(TransLine, IsHandled, TransHeader);
        if IsHandled then
            exit;

        TransLine.SetLoadFields("Document No.", Quantity, "Item No.", "Variant Code");
        TransLine.SetRange("Document No.", TransHeader."No.");
        TransLine.SetFilter(Quantity, '<>0');
        if TransLine.IsEmpty() then
            Error(NothingToReleaseErr, TransHeader."No.");

        TransLine.SetFilter("Item No.", '<>%1', '');
        if TransLine.FindSet() then
            repeat
                Item.Get(TransLine."Item No.");
                if Item.IsInventoriableType() then
                    TransLine.TestField("Unit of Measure Code");
                if Item.IsVariantMandatory() then
                    TransLine.TestField("Variant Code");
            until TransLine.Next() = 0;
        TransLine.SetFilter("Item No.", '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransLines(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean; TransHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseTransferDoc(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenTransferDoc(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseTransferDoc(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopenTransferDoc(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransferCode(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransitLocations(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeSetStatusReleased(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;
}

