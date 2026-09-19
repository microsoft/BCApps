// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Transfer;

tableextension 11799 "Item Ledger Entry CZL" extends "Item Ledger Entry"
{
    procedure SetFilterFromInvtReceiptHeaderCZL(InvtReceiptHeader: Record "Invt. Receipt Header")
    begin
        SetCurrentKey("Document No.");
        SetRange("Document No.", InvtReceiptHeader."No.");
        SetRange("Posting Date", InvtReceiptHeader."Posting Date");
    end;

    procedure SetFilterFromInvtShipmentHeaderCZL(InvtShipmentHeader: Record "Invt. Shipment Header")
    begin
        SetCurrentKey("Document No.");
        SetRange("Document No.", InvtShipmentHeader."No.");
        SetRange("Posting Date", InvtShipmentHeader."Posting Date");
    end;

    procedure SetFilterFromDirectTransHeaderCZL(DirectTransHeader: Record "Direct Trans. Header")
    begin
        SetCurrentKey("Document No.");
        SetRange("Document No.", DirectTransHeader."No.");
        SetRange("Posting Date", DirectTransHeader."Posting Date");
    end;

    procedure GetRegisterUserIDCZL(): Code[50]
    var
        ItemRegister: Record "Item Register";
    begin
        if ItemRegister.FindByEntryNoCZL("Entry No.") then
            exit(ItemRegister."User ID");
    end;
}
