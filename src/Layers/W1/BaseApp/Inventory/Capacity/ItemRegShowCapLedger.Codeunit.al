// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Inventory.Ledger;

codeunit 5835 "Item Reg.-Show Cap. Ledger"
{
    TableNo = "Item Register";

    trigger OnRun()
    begin
        CapLedgEntry.SetRange("Entry No.", Rec."From Capacity Entry No.", Rec."To Capacity Entry No.");
        CapLedgEntry.SetFilter("Item Register No.", '0|%1', Rec."No.");
        PAGE.Run(PAGE::"Capacity Ledger Entries", CapLedgEntry);
    end;

    var
        CapLedgEntry: Record "Capacity Ledger Entry";
}

