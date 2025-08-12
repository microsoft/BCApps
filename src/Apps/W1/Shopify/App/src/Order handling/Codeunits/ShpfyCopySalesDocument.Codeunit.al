// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Document;
using Microsoft.Utilities;

codeunit 30408 "Shpfy Copy Sales Document"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopySalesHeaderArchive', '', false, false)]
    local procedure OnAfterCopySalesHeaderArchive(var ToSalesHeader: Record "Sales Header")
    begin
        if (ToSalesHeader."Shpfy Order Id" = 0) and (ToSalesHeader."Shpfy Order No." = '') then
            exit;

        Clear(ToSalesHeader."Shpfy Order Id");
        Clear(ToSalesHeader."Shpfy Order No.");
        ToSalesHeader.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopySalesDocSalesLineArchive', '', false, false)]
    local procedure OnAfterCopySalesDocSalesLineArchive(ToSalesLine: Record "Sales Line")
    begin
        if (ToSalesLine."Shpfy Order Line Id" = 0) and (ToSalesLine."Shpfy Order No." = '') then
            exit;

        Clear(ToSalesLine."Shpfy Order Line Id");
        Clear(ToSalesLine."Shpfy Order No.");
        ToSalesLine.Modify();
    end;
}