// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Service.Document;

codeunit 6487 "Serv. VAT Setup Mgt."
{
    Permissions = TableData "Service Line" = rimd;

    [EventSubscriber(ObjectType::Table, Database::"VAT Setup Posting Groups", 'OnBeforeCheckExistingItemAndServiceWithVAT', '', false, false)]
    local procedure OnBeforeCheckExistingItemAndServiceWithVAT(VATProdPostingGroupCode: Code[20]; var Result: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Result := not ServiceLine.IsEmpty();
    end;

    [EventSubscriber(ObjectType::Page, Page::"VAT Setup Wizard", 'OnBeforeDeleteVATProdPostingGroup', '', false, false)]
    local procedure OnBeforeDeleteVATProdPostingGroup(var VATProductPostingGroup: Record "VAT Product Posting Group"; var ShouldDelete: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        if (not ServiceLine.IsEmpty()) then
            ShouldDelete := false;
    end;
}
