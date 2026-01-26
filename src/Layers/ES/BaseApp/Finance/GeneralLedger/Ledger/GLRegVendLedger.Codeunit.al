// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Purchases.Payables;

/// <summary>
/// Opens Vendor Ledger Entries page filtered by G/L register entry range.
/// Provides navigation from G/L register to related vendor ledger entries for audit and analysis.
/// </summary>
/// <remarks>
/// TableNo = G/L Register. Filters Vendor Ledger Entries by entry number range from the register.
/// Used for drill-down functionality from G/L Registers page to see related vendor transactions.
/// </remarks>
codeunit 237 "G/L Reg.-Vend.Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        VendLedgEntry.SetCurrentKey("Transaction No.");
        VendLedgEntry.SetRange("Transaction No.", Rec."No.");
        PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
    end;

    var
        VendLedgEntry: Record "Vendor Ledger Entry";
}

