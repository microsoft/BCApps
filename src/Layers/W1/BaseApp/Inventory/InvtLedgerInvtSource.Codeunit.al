// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;

codeunit 5858 "Invt. Ledger Invt. Source"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Invt. Ledger Source Mgt.", OnGetSourceDescription, '', false, false)]
    local procedure OnGetSourceDescription(SourceType: Enum "Analysis Source Type"; SourceNo: Code[20]; var SourceDescription: Text)
    var
        Item: Record Item;
    begin
        if SourceNo = '' then
            exit;

        if SourceType = SourceType::Item then begin
            Item.SetLoadFields(Description);
            if Item.Get(SourceNo) then
                SourceDescription := Item.Description;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Invt. Ledger Source Mgt.", OnGetSourceOrderNo, '', false, false)]
    local procedure OnGetSourceOrderNo(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; var SourceOrderNo: Code[20])
    var
        DirectTransHdr: Record "Direct Trans. Header";
        InvtReceiptHdr: Record "Invt. Receipt Header";
        InvtShipmentHdr: Record "Invt. Shipment Header";
        TransShptHdr: Record "Transfer Shipment Header";
        TransRcptHdr: Record "Transfer Receipt Header";
    begin
        if DocNo = '' then
            exit;

        case DocType of
            DocType::"Transfer Shipment":
                begin
                    TransShptHdr.SetLoadFields("Transfer Order No.");
                    if TransShptHdr.Get(DocNo) then
                        SourceOrderNo := TransShptHdr."Transfer Order No.";
                end;
            DocType::"Transfer Receipt":
                begin
                    TransRcptHdr.SetLoadFields("Transfer Order No.");
                    if TransRcptHdr.Get(DocNo) then
                        SourceOrderNo := TransRcptHdr."Transfer Order No.";
                end;
            DocType::"Direct Transfer":
                begin
                    DirectTransHdr.SetLoadFields("No.");
                    if DirectTransHdr.Get(DocNo) then
                        SourceOrderNo := DirectTransHdr."No.";
                end;
            DocType::"Inventory Receipt":
                begin
                    InvtReceiptHdr.SetLoadFields("No.");
                    if InvtReceiptHdr.Get(DocNo) then
                        SourceOrderNo := InvtReceiptHdr."No.";
                end;
            DocType::"Inventory Shipment":
                begin
                    InvtShipmentHdr.SetLoadFields("No.");
                    if InvtShipmentHdr.Get(DocNo) then
                        SourceOrderNo := InvtShipmentHdr."No.";
                end;
        end;
    end;
}