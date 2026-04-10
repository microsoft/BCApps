// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

codeunit 5620 "FA Reg.-FALedger"
{
    TableNo = "FA Register";

    trigger OnRun()
    begin
        FALedgEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        PAGE.Run(PAGE::"FA Ledger Entries", FALedgEntry);
    end;

    var
        FALedgEntry: Record "FA Ledger Entry";
}

