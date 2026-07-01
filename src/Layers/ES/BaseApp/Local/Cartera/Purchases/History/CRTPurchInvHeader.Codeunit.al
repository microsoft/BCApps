// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Purchases.Payables;

codeunit 7000106 "CRT Purch. Inv. Header"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Header", 'OnLookupAppliesToDocNoOnAfterSetFilters', '', false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var VendLedgEntry: Record "Vendor Ledger Entry"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        VendLedgEntry.SetRange("Bill No.", PurchInvHeader."Applies-to Bill No.");
    end;
}