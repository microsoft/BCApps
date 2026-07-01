// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Purchases.Payables;

codeunit 7000101 "CRT Purch. Cr. Memo Hdr."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Cr. Memo Hdr.", 'OnLookupAppliesToDocNoOnAfterSetFilters', '', false, false)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var VendLedgEntry: Record "Vendor Ledger Entry"; PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.")
    begin
        VendLedgEntry.SetRange("Bill No.", PurchCrMemoHeader."Applies-to Bill No.");
    end;

}