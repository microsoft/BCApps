// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Opens the Bank Account Ledger Entries page filtered to show entries from a specific G/L register.
/// Links general ledger register records to their corresponding bank account ledger entries for audit trails.
/// </summary>
codeunit 377 "G/L Reg.-Bank Account Ledger"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        BankAccLedgEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        PAGE.Run(PAGE::"Bank Account Ledger Entries", BankAccLedgEntry);
    end;

    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
}

