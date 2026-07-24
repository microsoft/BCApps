// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Inventory.Ledger;

codeunit 5914 "Invt. Ledger Service Source"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Invt. Ledger Source Mgt.", OnGetSourceOrderNo, '', true, false)]
    local procedure OnGetSourceOrderNo(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; DocLineNo: Integer; var SourceOrderNo: Code[20])
    var

        ServiceInvoiceHdr: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        if DocNo = '' then
            exit;

        case DocType of
            DocType::"Service Invoice":
                begin
                    if DocLineNo = 0 then begin
                        ServiceInvoiceHdr.SetLoadFields("Order No.");
                        if ServiceInvoiceHdr.Get(DocNo) then
                            SourceOrderNo := ServiceInvoiceHdr."Order No.";
                        exit;
                    end;
                    ServiceInvoiceLine.SetLoadFields("Order No.");
                    if ServiceInvoiceLine.Get(DocNo, DocLineNo) then
                        SourceOrderNo := ServiceInvoiceLine."Order No.";
                end;
        end;
    end;
}