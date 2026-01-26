// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Sales.Receivables;

/// <summary>
/// Opens Customer Ledger Entries page filtered by G/L register entry range.
/// Provides navigation from G/L register to related customer ledger entries for audit and analysis.
/// </summary>
/// <remarks>
/// TableNo = G/L Register. Filters Customer Ledger Entries by entry number range from the register.
/// Used for drill-down functionality from G/L Registers page to see related customer transactions.
/// </remarks>
codeunit 236 "G/L Reg.-Cust.Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        CustLedgEntry.SetCurrentKey("Transaction No.");
        CustLedgEntry.SetRange("Transaction No.", Rec."No.");
        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
    end;

    var
        CustLedgEntry: Record "Cust. Ledger Entry";
}

