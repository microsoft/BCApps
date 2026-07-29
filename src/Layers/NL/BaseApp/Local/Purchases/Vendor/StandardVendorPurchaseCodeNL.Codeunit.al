// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Purchases.Document;

codeunit 11330 StandardVendorPurchaseCodeNL
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Standard Vendor Purchase Code", 'OnBeforeApplyStdCodesToPurchaseLines', '', false, false)]
    local procedure OnBeforeApplyStdCodesToPurchaseLines(var PurchLine: Record "Purchase Line"; StdPurchLine: Record "Standard Purchase Line")
    begin
        if not StdPurchLine.EmptyLine() then
            PurchLine."Suggested Line" := true;
    end;
}
