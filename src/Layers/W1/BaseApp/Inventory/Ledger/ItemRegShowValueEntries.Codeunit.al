// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

codeunit 5800 "Item Reg.- Show Value Entries"
{
    TableNo = "Item Register";

    trigger OnRun()
    begin
        ValueEntry.SetRange("Entry No.", Rec."From Value Entry No.", Rec."To Value Entry No.");
        ValueEntry.SetFilter("Item Register No.", '0|%1', Rec."No.");
        PAGE.Run(PAGE::"Value Entries", ValueEntry);
    end;

    var
        ValueEntry: Record "Value Entry";
}

