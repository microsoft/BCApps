// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.Inventory.Ledger;

codeunit 5914 "Invt. Ledger Service Source"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Invt. Ledger Source Mgt.", OnGetSourceOrderNo, '', false, false)]
    local procedure OnGetSourceOrderNo(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; var SourceOrderNo: Code[20])
    var
        ServiceInvoiceHdr: Record "Service Invoice Header";
    begin
        if DocNo = '' then
            exit;

        case DocType of
            DocType::"Service Invoice":
                begin
                    ServiceInvoiceHdr.SetLoadFields("Order No.");
                    if ServiceInvoiceHdr.Get(DocNo) then
                        SourceOrderNo := ServiceInvoiceHdr."Order No.";
                end;
        end;
    end;
}