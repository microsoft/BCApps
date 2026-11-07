// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

codeunit 245 "Item Reg.-Show Ledger"
{
    TableNo = "Item Register";

    trigger OnRun()
    begin
        ItemLedgEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        ItemLedgEntry.SetFilter("Item Register No.", '0|%1', Rec."No.");
        PAGE.Run(PAGE::"Item Ledger Entries", ItemLedgEntry);
    end;

    var
        ItemLedgEntry: Record "Item Ledger Entry";
}

