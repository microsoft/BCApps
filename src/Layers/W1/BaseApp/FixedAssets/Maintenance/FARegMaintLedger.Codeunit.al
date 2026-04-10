// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Maintenance;

using Microsoft.FixedAssets.Ledger;

codeunit 5650 "FA Reg.-MaintLedger"
{
    TableNo = "FA Register";

    trigger OnRun()
    begin
        MaintenanceLedgEntry.SetRange("Entry No.", Rec."From Maintenance Entry No.", Rec."To Maintenance Entry No.");
        PAGE.Run(PAGE::"Maintenance Ledger Entries", MaintenanceLedgEntry);
    end;

    var
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
}

