// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Purchases.Payables;

codeunit 7000102 "CRT Purch. Rcpt. Header"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Rcpt. Header", 'OnLookupAppliesToDocNoOnAfterSetFilters', '', true, true)]
    local procedure OnLookupAppliesToDocNoOnAfterSetFilters(var VendLedgEntry: Record "Vendor Ledger Entry"; PurchRcptHeader: Record "Purch. Rcpt. Header")
    begin
        VendLedgEntry.SetRange("Bill No.", PurchRcptHeader."Applies-to Bill No.");
    end;

}