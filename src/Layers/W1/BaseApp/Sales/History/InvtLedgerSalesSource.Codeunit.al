// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;

codeunit 5860 "Invt. Ledger Sales Source"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Invt. Ledger Source Mgt.", OnGetSourceDescription, '', false, false)]
    local procedure OnGetSourceDescription(SourceType: Enum "Analysis Source Type"; SourceNo: Code[20]; var SourceDescription: Text)
    var
        Customer: Record Customer;
    begin
        if SourceNo = '' then
            exit;

        if SourceType = SourceType::Customer then begin
            Customer.SetLoadFields(Name);
            if Customer.Get(SourceNo) then
                SourceDescription := Customer.Name;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Invt. Ledger Source Mgt.", OnGetSourceOrderNo, '', false, false)]
    local procedure OnGetSourceOrderNo(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; var SourceOrderNo: Code[20])
    var
        SalesShptHdr: Record "Sales Shipment Header";
        SalesInvHdr: Record "Sales Invoice Header";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        ReturnRcptHdr: Record "Return Receipt Header";
    begin
        if DocNo = '' then
            exit;

        case DocType of
            DocType::"Sales Shipment":
                begin
                    SalesShptHdr.SetLoadFields("Order No.");
                    if SalesShptHdr.Get(DocNo) then
                        SourceOrderNo := SalesShptHdr."Order No.";
                end;
            DocType::"Sales Invoice":
                begin
                    SalesInvHdr.SetLoadFields("Order No.");
                    if SalesInvHdr.Get(DocNo) then
                        SourceOrderNo := SalesInvHdr."Order No.";
                end;
            DocType::"Sales Return Receipt":
                begin
                    ReturnRcptHdr.SetLoadFields("Return Order No.");
                    if ReturnRcptHdr.Get(DocNo) then
                        SourceOrderNo := ReturnRcptHdr."Return Order No.";
                end;
            DocType::"Sales Credit Memo":
                begin
                    SalesCrMemoHdr.SetLoadFields("Return Order No.");
                    if SalesCrMemoHdr.Get(DocNo) then
                        SourceOrderNo := SalesCrMemoHdr."Return Order No.";
                end;
        end;
    end;
}