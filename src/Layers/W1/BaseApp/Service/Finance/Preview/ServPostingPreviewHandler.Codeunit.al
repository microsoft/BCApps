// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Preview;

using Microsoft.Service.Ledger;

codeunit 6499 "Serv. Posting Preview Handler"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        TempServiceLedgerEntry: Record "Service Ledger Entry" temporary;
        TempWarrantyLedgerEntry: Record "Warranty Ledger Entry" temporary;

    [EventSubscriber(ObjectType::Table, Database::"Service Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnInsertServiceLedgerEntry(var Rec: Record "Service Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if TempServiceLedgerEntry.Get(Rec."Entry No.") then
            exit;

        TempServiceLedgerEntry := Rec;
        TempServiceLedgerEntry."Document No." := '***';
        TempServiceLedgerEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Ledger Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnModifyServiceLedgerEntry(var Rec: Record "Service Ledger Entry"; var xRec: Record "Service Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempServiceLedgerEntry := Rec;
        TempServiceLedgerEntry."Document No." := '***';
        if not TempServiceLedgerEntry.Insert() then
            TempServiceLedgerEntry.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warranty Ledger Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnInsertWarrantyLedgerEntry(var Rec: Record "Warranty Ledger Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        TempWarrantyLedgerEntry := Rec;
        TempWarrantyLedgerEntry."Document No." := '***';
        TempWarrantyLedgerEntry.Insert();
    end;

    procedure DeleteAll()
    begin
        TempServiceLedgerEntry.Reset();
        TempServiceLedgerEntry.DeleteAll();
        TempWarrantyLedgerEntry.Reset();
        TempWarrantyLedgerEntry.DeleteAll();
    end;

    procedure GetTempServiceLedgerEntry(var OutTempServiceLedgerEntry: Record "Service Ledger Entry" temporary)
    begin
        OutTempServiceLedgerEntry.Copy(TempServiceLedgerEntry, true);
    end;

    procedure GetTempWarrantyLedgerEntry(var OutTempWarrantyLedgerEntry: Record "Warranty Ledger Entry" temporary)
    begin
        OutTempWarrantyLedgerEntry.Copy(TempWarrantyLedgerEntry, true);
    end;
}
