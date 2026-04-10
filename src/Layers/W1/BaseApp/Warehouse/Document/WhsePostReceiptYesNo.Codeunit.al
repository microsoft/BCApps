// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Finance.GeneralLedger.Preview;

codeunit 5761 "Whse.-Post Receipt (Yes/No)"
{
    TableNo = "Warehouse Receipt Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        WhseReceiptLine.Copy(Rec);
        Code();
        Rec := WhseReceiptLine;
    end;

    var
        WhseReceiptLine: Record "Warehouse Receipt Line";

#pragma warning disable AA0074
        Text000: Label 'Do you want to post the receipt?';
#pragma warning restore AA0074

    local procedure "Code"()
    var
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
        HideDialog: Boolean;
        IsPosted: Boolean;
        IsHandled: Boolean;
    begin
        HideDialog := false;
        IsPosted := false;
        OnBeforeConfirmWhseReceiptPost(WhseReceiptLine, HideDialog, IsPosted);
        if IsPosted then
            exit;

        if WhseReceiptLine.Find() then
            if not HideDialog then
                if not Confirm(Text000, false) then
                    exit;

        IsHandled := false;
        OnAfterConfirmPost(WhseReceiptLine, IsHandled);
        if not IsHandled then begin
            WhsePostReceipt.Run(WhseReceiptLine);
            OnAfterWhsePostReceiptRun(WhseReceiptLine, WhsePostReceipt);
            WhsePostReceipt.GetResultMessage();
            Clear(WhsePostReceipt);
        end;
    end;

    procedure Preview(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        WhsePostReceiptYesNo: Codeunit "Whse.-Post Receipt (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(WhsePostReceiptYesNo);
        GenJnlPostPreview.Preview(WhsePostReceiptYesNo, WarehouseReceiptLine);
    end;

    procedure MessageIfPostingPreviewMultipleDocuments(var WarehouseReceiptHeaderToPreview: Record "Warehouse Receipt Header"; DocumentNo: Code[20])
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        RecordRefToPreview: RecordRef;
    begin
        RecordRefToPreview.Open(Database::"Warehouse Receipt Header");
        RecordRefToPreview.Copy(WarehouseReceiptHeaderToPreview);

        GenJnlPostPreview.MessageIfPostingPreviewMultipleDocuments(RecordRefToPreview, DocumentNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
    begin
        WarehouseReceiptLine.Copy(RecVar);
        WhsePostReceipt.SetPreviewMode(true);
        Result := WhsePostReceipt.Run(WarehouseReceiptLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirmPost(WhseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhsePostReceiptRun(var WhseReceiptLine: Record "Warehouse Receipt Line"; WhsePostReceipt: Codeunit "Whse.-Post Receipt")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmWhseReceiptPost(var WhseReceiptLine: Record "Warehouse Receipt Line"; var HideDialog: Boolean; var IsPosted: Boolean)
    begin
    end;
}

