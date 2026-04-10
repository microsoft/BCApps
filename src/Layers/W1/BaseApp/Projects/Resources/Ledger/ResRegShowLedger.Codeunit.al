// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Ledger;

codeunit 275 "Res. Reg.-Show Ledger"
{
    TableNo = "Resource Register";

    trigger OnRun()
    begin
        ResLedgEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        ResLedgEntry.SetFilter("Resource Register No.", '0|%1', Rec."No.");
        PAGE.Run(PAGE::"Resource Ledger Entries", ResLedgEntry);
    end;

    var
        ResLedgEntry: Record "Res. Ledger Entry";
}

