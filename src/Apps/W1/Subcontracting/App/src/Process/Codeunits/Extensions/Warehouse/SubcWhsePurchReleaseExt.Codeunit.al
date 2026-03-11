// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Document;

codeunit 99001550 "Subc. WhsePurchRelease Ext"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Purch. Release", OnAfterReleaseSetFilters, '', false, false)]
    local procedure OnAfterReleaseSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.CalcFields("Subcontracting Order");
        if PurchaseHeader."Subcontracting Order" then
            PurchaseLine.SetRange("Work Center No.");
    end;
}