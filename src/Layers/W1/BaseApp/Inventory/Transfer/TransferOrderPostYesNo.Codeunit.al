// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Setup;

codeunit 5706 "TransferOrder-Post (Yes/No)"
{
    TableNo = "Transfer Header";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.SetPreviewMode(PreviewMode);
        TransHeader.Copy(Rec);
        Code();
        Rec := TransHeader;
    end;

    var
        TransHeader: Record "Transfer Header";
        PreviewMode: Boolean;
        PostBatch: Boolean;
        TransferOrderPost: enum "Transfer Order Post";
#pragma warning disable AA0074
        Text000: Label '&Ship,&Receive';
#pragma warning restore AA0074
        ShipReceiveNotEqualErr: Label 'The quantity to ship and quantity to receive must be equal in a direct transfer.';

    local procedure "Code"()
    var
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
        PostReceipt, PostShipment, PostTransfer : Boolean;
        DefaultNumber: Integer;
        Selection: Option " ",Shipment,Receipt;
        IsHandled: Boolean;
    begin
        OnBeforePost(TransHeader, IsHandled, TransferOrderPostShipment, TransferOrderPostReceipt, PostBatch, TransferOrderPost);
        if IsHandled then
            exit;

        DefaultNumber := GetDefaultNumber();

        IsHandled := false;
        OnCodeOnBeforePostTransferOrder(TransHeader, DefaultNumber, Selection, IsHandled, PostBatch, TransferOrderPost, PreviewMode);
        if not IsHandled then begin
            GetPostingOptions(DefaultNumber, Selection, PostShipment, PostReceipt, PostTransfer);
            CheckTransferHeader(TransHeader);
            PostTransferOrder(PostShipment, PostReceipt, PostTransfer);
        end;

        OnAfterPost(TransHeader, Selection);
    end;

    local procedure CheckTransferHeader(var TransferHeader: Record "Transfer Header")
    var
        InventorySetup: Record "Inventory Setup";
        TransferLine: Record "Transfer Line";
    begin
        InventorySetup.Get();

        if TransferHeader."Direct Transfer" and (InventorySetup."Direct Transfer Posting" = InventorySetup."Direct Transfer Posting"::"Receipt and Shipment") then begin
            TransferLine.SetRange("Document No.", TransferHeader."No.");
            TransferLine.SetLoadFields("Qty. to Ship", "Qty. to Receive", "Qty. to Ship (Base)", "Qty. to Receive (Base)");
            if TransferLine.FindSet() then
                repeat
                    // For 'Direct Transfer', "Qty. to Ship" and "Qty. to Receive" should be the same.
                    if TransferLine."Qty. to Receive" <> TransferLine."Qty. to Ship" then
                        Error(ShipReceiveNotEqualErr);
                    if TransferLine."Qty. to Receive (Base)" <> TransferLine."Qty. to Ship (Base)" then
                        Error(ShipReceiveNotEqualErr);
                until TransferLine.Next() = 0;
        end;
    end;

    local procedure GetDefaultNumber() DefaultNumber: Integer
    var
        TransferLine: Record "Transfer Line";
    begin
        if PostBatch or TransHeader."Direct Transfer" then
            exit;

        TransferLine.Reset();
        TransferLine.SetRange("Document No.", TransHeader."No.");
        if TransferLine.Find('-') then
            repeat
                if (TransferLine."Quantity Shipped" < TransferLine.Quantity) and (DefaultNumber = 0) then
                    DefaultNumber := 1;
                if (TransferLine."Quantity Received" < TransferLine.Quantity) and (DefaultNumber = 0) then
                    DefaultNumber := 2;
            until (TransferLine.Next() = 0) or (DefaultNumber > 0);
    end;

    local procedure GetPostingOptions(var DefaultNumber: Integer; var Selection: Option " ",Shipment,Receipt; var PostShipment: Boolean; var PostReceipt: Boolean; var PostTransfer: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPostingOptions(TransHeader, Selection, PostShipment, PostReceipt, IsHandled, PostTransfer, DefaultNumber, PostBatch, PreviewMode);
        if IsHandled then
            exit;

        InventorySetup.Get();

        case true of
            (TransHeader."Direct Transfer") and (InventorySetup."Direct Transfer Posting" = InventorySetup."Direct Transfer Posting"::"Receipt and Shipment"):
                begin
                    PostShipment := true;
                    PostReceipt := true;
                end;
            (TransHeader."Direct Transfer") and (InventorySetup."Direct Transfer Posting" = InventorySetup."Direct Transfer Posting"::"Direct Transfer"):
                PostTransfer := true;
            PostBatch:
                begin
                    PostShipment := TransferOrderPost = TransferOrderPost::Ship;
                    PostReceipt := TransferOrderPost = TransferOrderPost::Receive;
                end;
            else begin
                if DefaultNumber = 0 then
                    DefaultNumber := 1;
                Selection := StrMenu(Text000, DefaultNumber);

                IsHandled := false;
                OnGetPostingOptionsOnAfterSelection(TransHeader, DefaultNumber, Selection, PostShipment, PostReceipt, PostTransfer, IsHandled);
                if IsHandled then
                    exit;

                PostShipment := Selection = Selection::Shipment;
                PostReceipt := Selection = Selection::Receipt;
            end;
        end;
    end;

    procedure PostTransferOrder(PostShipment: Boolean; PostReceipt: Boolean; PostTransfer: Boolean)
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferOrderPostTransfer: Codeunit "TransferOrder-Post Transfer";
    begin
        if PostShipment then begin
            TransferOrderPostShipment.SetHideValidationDialog(PostBatch);
            TransferOrderPostShipment.SetPreviewMode(PreviewMode);
            TransferOrderPostShipment.Run(TransHeader);
        end;

        if PostReceipt then begin
            TransferOrderPostReceipt.SetHideValidationDialog(PostBatch);
            TransferOrderPostReceipt.SetPreviewMode(PreviewMode);
            TransferOrderPostReceipt.Run(TransHeader);
        end;

        if PostTransfer then begin
            TransferOrderPostTransfer.SetPreviewMode(PreviewMode);
            TransferOrderPostTransfer.Run(TransHeader);
        end;

        if PreviewMode then
            GenJnlPostPreview.ThrowError();
    end;

    internal procedure SetParameters(SetPostBatch: Boolean; SetTransferOrderPost: enum "Transfer Order Post")
    begin
        PostBatch := SetPostBatch;
        TransferOrderPost := SetTransferOrderPost;
    end;

    procedure Preview(var TransferHeader: Record "Transfer Header")
    var
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(TransferOrderPostYesNo);
        GenJnlPostPreview.Preview(TransferOrderPostYesNo, TransferHeader);
    end;

    procedure MessageIfPostingPreviewMultipleDocuments(var TransferHeaderToPreview: Record "Transfer Header"; DocumentNo: Code[20])
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RecordRefToPreview: RecordRef;
    begin
        RecordRefToPreview.Open(Database::"Transfer Header");
        RecordRefToPreview.Copy(TransferHeaderToPreview);

        GenJnlPostPreview.MessageIfPostingPreviewMultipleDocuments(RecordRefToPreview, DocumentNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        TransferHeader: Record "Transfer Header";
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
    begin
        TransferHeader.Copy(RecVar);
        TransferOrderPostYesNo.SetPreviewMode(true);
        Result := TransferOrderPostYesNo.Run(TransferHeader);
    end;

    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var TransHeader: Record "Transfer Header"; Selection: Option " ",Shipment,Receipt)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var TransHeader: Record "Transfer Header"; var IsHandled: Boolean; var TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment"; var TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt"; var PostBatch: Boolean; var TransferOrderPost: Enum "Transfer Order Post")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostTransferOrder(var TransHeader: Record "Transfer Header"; var DefaultNumber: Integer; var Selection: Option; var IsHandled: Boolean; var PostBatch: Boolean; var TransferOrderPost: Enum "Transfer Order Post"; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostingOptions(TransferHeader: Record "Transfer Header"; Selection: Option; var PostShipment: Boolean; var PostReceipt: Boolean; var IsHandled: Boolean; var PostTransfer: Boolean; var DefaultNumber: Integer; PostBatch: Boolean; PreviewMode: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPostingOptionsOnAfterSelection(TransferHeader: Record "Transfer Header"; DefaultNumber: Integer; var Selection: Option; var PostShipment: Boolean; var PostReceipt: Boolean; var PostTransfer: Boolean; var IsHandled: Boolean);
    begin
    end;
}
