// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reversal;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 7000099 "CRT GenJnl Post Reverse"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnReverseCustLedgEntryOnBeforeInsertCustLedgEntry', '', false, false)]
    local procedure OnReverseCustLedgEntryOnBeforeInsertCustLedgEntry(var NewCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        NewCustLedgerEntry."Amount (LCY) stats." := -NewCustLedgerEntry."Amount (LCY) stats.";
        NewCustLedgerEntry."Remaining Amount (LCY) stats." := -NewCustLedgerEntry."Remaining Amount (LCY) stats.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnReverseVendLedgEntryOnBeforeInsertVendLedgEntry', '', false, false)]
    local procedure OnReverseVendLedgEntryOnBeforeInsertVendLedgEntry(var NewVendLedgEntry: Record "Vendor Ledger Entry"; VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        NewVendLedgEntry."Amount (LCY) stats." := -NewVendLedgEntry."Amount (LCY) stats.";
        NewVendLedgEntry."Remaining Amount (LCY) stats." := -NewVendLedgEntry."Remaining Amount (LCY) stats.";
    end;
}
