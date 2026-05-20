// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Ledger;

codeunit 5911 "Serv Reg.-Show Ledger Entries"
{
    TableNo = "Service Register";

    trigger OnRun()
    begin
        ServLedgEntry.Reset();
        ServLedgEntry.SetRange("Entry No.", Rec."From Entry No.", Rec."To Entry No.");
        ServLedgEntry.SetFilter("Service Register No.", '0|%1', Rec."No.");
        Page.Run(Page::"Service Ledger Entries", ServLedgEntry);
    end;

    var
        ServLedgEntry: Record "Service Ledger Entry";
}

