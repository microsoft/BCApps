// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

codeunit 11325 PurchCrMemoSubformNL
{
    [EventSubscriber(ObjectType::Page, Page::"Purch. Cr. Memo Subform", 'OnAfterNoOnAfterValidate', '', false, false)]
    local procedure OnAfterNoOnAfterValidate(var PurchaseLine: Record "Purchase Line"; var xPurchaseLine: Record "Purchase Line")
    begin
        if PurchaseLine.Type = PurchaseLine.Type::"G/L Account" then
            PurchaseLine.Validate(Quantity, 1);
    end;
}
