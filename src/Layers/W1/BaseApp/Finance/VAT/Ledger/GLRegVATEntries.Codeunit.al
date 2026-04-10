// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Navigation codeunit for displaying VAT entries associated with a specific G/L register.
/// Filters VAT entries by entry number range from the selected G/L register and opens VAT Entries page.
/// </summary>
/// <remarks>
/// Triggered from G/L Register page to show related VAT entries for a posting batch.
/// Uses G/L Register's From/To VAT Entry No. range to filter VAT entries for display.
/// Provides traceability between G/L posting operations and corresponding VAT transactions.
/// </remarks>
codeunit 238 "G/L Reg.-VAT Entries"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        VATEntry.SetRange("Entry No.", Rec."From VAT Entry No.", Rec."To VAT Entry No.");
        PAGE.Run(PAGE::"VAT Entries", VATEntry);
    end;

    var
        VATEntry: Record "VAT Entry";
}

