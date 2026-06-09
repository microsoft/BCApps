// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

codeunit 99001567 "Subc. Pst. Prev. Event Handler"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        TempSubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry" temporary;
        DocumentMaskTok: Label '***', Locked = true;
#if not CLEAN29
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#endif

    [EventSubscriber(ObjectType::Table, Database::"Subcontractor WIP Ledger Entry", OnAfterInsertEvent, '', false, false)]
    local procedure OnInsertWIPEntry(var Rec: Record "Subcontractor WIP Ledger Entry")
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit;

#endif
        if Rec.IsTemporary() then
            exit;

        if TempSubcontractorWIPLedgerEntry.Get(Rec."Entry No.") then
            exit;

        TempSubcontractorWIPLedgerEntry := Rec;
        TempSubcontractorWIPLedgerEntry."Document No." := DocumentMaskTok;
        TempSubcontractorWIPLedgerEntry.Insert();
    end;

    procedure DeleteAll()
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit;
#endif
        TempSubcontractorWIPLedgerEntry.Reset();
        TempSubcontractorWIPLedgerEntry.DeleteAll();
    end;

    procedure GetTempSubcontractorWIPLedgerEntry(var OutTempSubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry" temporary)
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit;
#endif
        OutTempSubcontractorWIPLedgerEntry.Copy(TempSubcontractorWIPLedgerEntry, true);
    end;
}
