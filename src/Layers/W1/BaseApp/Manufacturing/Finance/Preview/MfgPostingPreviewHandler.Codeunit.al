// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Preview;

using Microsoft.Manufacturing.Capacity;

codeunit 99000799 "Mfg. Posting Preview Handler"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        TempCapacityLedgerEntry: Record "Capacity Ledger Entry" temporary;

    [EventSubscriber(ObjectType::Table, Database::"Capacity Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnInsertCapacityLedgerEntry(var Rec: Record "Capacity Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if TempCapacityLedgerEntry.Get(Rec."Entry No.") then
            exit;

        TempCapacityLedgerEntry := Rec;
        TempCapacityLedgerEntry."Document No." := '***';
        TempCapacityLedgerEntry.Insert();
    end;

    procedure DeleteAll()
    begin
        TempCapacityLedgerEntry.Reset();
        TempCapacityLedgerEntry.DeleteAll();
    end;

    procedure GetTempCapacityLedgerEntry(var OutTempCapacityLedgerEntry: Record "Capacity Ledger Entry" temporary)
    begin
        OutTempCapacityLedgerEntry.Copy(TempCapacityLedgerEntry, true);
    end;
}
