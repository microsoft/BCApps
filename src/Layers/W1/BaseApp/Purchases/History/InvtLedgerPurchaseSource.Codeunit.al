// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Vendor;

codeunit 5859 "Invt. Ledger Purchase Source"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Invt. Ledger Source Mgt.", OnGetSourceDescription, '', false, false)]
    local procedure OnGetSourceDescription(SourceType: Enum "Analysis Source Type"; SourceNo: Code[20]; var SourceDescription: Text)
    var
        Vendor: Record Vendor;
    begin
        if SourceNo = '' then
            exit;

        if SourceType = SourceType::Vendor then begin
            Vendor.SetLoadFields(Name);
            if Vendor.Get(SourceNo) then
                SourceDescription := Vendor.Name;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Invt. Ledger Source Mgt.", OnGetSourceOrderNo, '', false, false)]
    local procedure OnGetSourceOrderNo(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; DocLineNo: Integer; var SourceOrderNo: Code[20])
    var
        ReturnShptHdr: Record "Return Shipment Header";
        PurchRcptHdr: Record "Purch. Rcpt. Header";
        PurchInvHdr: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvLine: Record "Purch. Inv. Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        if DocNo = '' then
            exit;

        case DocType of
            DocType::"Purchase Receipt":
                begin
                    PurchRcptHdr.SetLoadFields("Order No.");
                    if PurchRcptHdr.Get(DocNo) then
                        SourceOrderNo := PurchRcptHdr."Order No.";
                end;
            DocType::"Purchase Invoice":
                begin
                    if DocLineNo = 0 then begin
                        PurchInvHdr.SetLoadFields("Order No.");
                        if PurchInvHdr.Get(DocNo) then
                            SourceOrderNo := PurchInvHdr."Order No.";
                        exit;
                    end;
                    PurchInvLine.SetLoadFields("Order No.");
                    if PurchInvLine.Get(DocNo, DocLineNo) then
                        SourceOrderNo := PurchInvLine."Order No.";
                end;
            DocType::"Purchase Return Shipment":
                begin
                    ReturnShptHdr.SetLoadFields("Return Order No.");
                    if ReturnShptHdr.Get(DocNo) then
                        SourceOrderNo := ReturnShptHdr."Return Order No.";
                end;
            DocType::"Purchase Credit Memo":
                begin
                    if DocLineNo = 0 then begin
                        PurchCrMemoHdr.SetLoadFields("Return Order No.");
                        if PurchCrMemoHdr.Get(DocNo) then
                            SourceOrderNo := PurchCrMemoHdr."Return Order No.";
                        exit;
                    end;
                    PurchCrMemoLine.SetLoadFields("Order No.");
                    if PurchCrMemoLine.Get(DocNo, DocLineNo) then
                        SourceOrderNo := PurchCrMemoLine."Order No.";
                end;
        end;
    end;
}