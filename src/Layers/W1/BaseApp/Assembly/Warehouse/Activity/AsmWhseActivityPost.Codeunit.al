// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Assembly.Document;

codeunit 932 "Asm. Whse. Activity Post"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", 'OnUpdateSourceDocumentOnBeforeSalesLineModify', '', false, false)]
    local procedure OnUpdateSourceDocumentOnBeforeSalesLineModify(WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        if WarehouseActivityLine."Assemble to Order" then begin
            ATOLink.UpdateQtyToAsmFromInvtPickLine(WarehouseActivityLine);
            ATOLink.UpdateAsmBinCodeFromInvtPickLine(WarehouseActivityLine);
        end;
    end;
}
