// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.History;

using Microsoft.Inventory.Ledger;

codeunit 907 "Invt. Ledger Assembly Source"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Invt. Ledger Source Mgt.", OnGetSourceOrderNo, '', false, false)]
    local procedure OnGetSourceOrderNo(DocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; var SourceOrderNo: Code[20])
    var
        PostedAssemblyHdr: Record "Posted Assembly Header";
    begin
        if DocNo = '' then
            exit;

        case DocType of
            DocType::"Posted Assembly":
                begin
                    PostedAssemblyHdr.SetLoadFields("Order No.");
                    if PostedAssemblyHdr.Get(DocNo) then
                        SourceOrderNo := PostedAssemblyHdr."Order No.";
                end;
        end;
    end;
}