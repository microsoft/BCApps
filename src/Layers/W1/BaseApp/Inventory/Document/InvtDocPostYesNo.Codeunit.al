// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Document;

using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.NoSeries;

codeunit 5853 "Invt. Doc.-Post (Yes/No)"
{
    TableNo = "Invt. Document Header";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.SetPreviewMode(PreviewMode);
        InvtDocHeader.Copy(Rec);
        Code();
        Rec := InvtDocHeader;
    end;

    var
        InvtDocHeader: Record "Invt. Document Header";
        ConfirmPostQst: Label 'Do you want to post Inventory Document?';
        PreviewMode: Boolean;

    local procedure "Code"()
    var
        InvtDocPostReceipt: Codeunit "Invt. Doc.-Post Receipt";
        InvtDocPostShipment: Codeunit "Invt. Doc.-Post Shipment";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        if not PreviewMode then
            if not Confirm(ConfirmPostQst, false) then
                exit;
        case InvtDocHeader."Document Type" of
            InvtDocHeader."Document Type"::Receipt:
                begin
                    InvtDocPostReceipt.SetPreviewMode(PreviewMode);
                    InvtDocPostReceipt.Run(InvtDocHeader);
                end;
            InvtDocHeader."Document Type"::Shipment:
                begin
                    InvtDocPostShipment.SetPreviewMode(PreviewMode);
                    InvtDocPostShipment.Run(InvtDocHeader);
                end;
        end;

        if PreviewMode then
            GenJnlPostPreview.ThrowError();
    end;

    internal procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    internal procedure Preview(var InvtDocumentHeader: Record "Invt. Document Header")
    var
        InvtDocPostYesNo: Codeunit "Invt. Doc.-Post (Yes/No)";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
    begin
        BindSubscription(InvtDocPostYesNo);
        GenJnlPostPreview.Preview(InvtDocPostYesNo, InvtDocumentHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Preview", 'OnRunPreview', '', false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocPostYesNo: Codeunit "Invt. Doc.-Post (Yes/No)";
    begin
        InvtDocumentHeader.Copy(RecVar);
        InvtDocPostYesNo.SetPreviewMode(true);
        Result := InvtDocPostYesNo.Run(InvtDocumentHeader);
    end;
}

