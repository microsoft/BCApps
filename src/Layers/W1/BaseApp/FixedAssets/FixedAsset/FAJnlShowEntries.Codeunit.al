// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;

codeunit 5634 "FA Jnl.-Show Entries"
{
    TableNo = "FA Journal Line";

    trigger OnRun()
    begin
        if Rec."FA Posting Type" <> Rec."FA Posting Type"::Maintenance then begin
            DepreciationCalc.SetFAFilter(FALedgEntry, Rec."FA No.", Rec."Depreciation Book Code", false);
            if Rec."Depreciation Book Code" = '' then
                FALedgEntry.SetRange("Depreciation Book Code");
            if FALedgEntry.Find('+') then;
            PAGE.Run(PAGE::"FA Ledger Entries", FALedgEntry);
        end else begin
            MaintenanceLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
            MaintenanceLedgEntry.SetRange("FA No.", Rec."FA No.");
            if Rec."Depreciation Book Code" <> '' then
                MaintenanceLedgEntry.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
            if MaintenanceLedgEntry.FindLast() then;
            PAGE.Run(PAGE::"Maintenance Ledger Entries", MaintenanceLedgEntry);
        end;
    end;

    var
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        DepreciationCalc: Codeunit "Depreciation Calculation";
}

