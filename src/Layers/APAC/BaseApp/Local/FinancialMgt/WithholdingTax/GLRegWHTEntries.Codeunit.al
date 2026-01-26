// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 28041 "G/L Reg.-WHT Entries"
{
    TableNo = "G/L Register";

    trigger OnRun()
    begin
        WHTEntry.SetRange("Entry No.", Rec."From WHT Entry No.", Rec."To WHT Entry No.");
        PAGE.Run(PAGE::"WHT Entry", WHTEntry);
    end;

    var
        WHTEntry: Record "WHT Entry";
}

