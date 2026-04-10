// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using Microsoft.Warehouse.Ledger;

codeunit 7309 "Whse. Jnl.-Register+Print"
{
    TableNo = "Warehouse Journal Line";

    trigger OnRun()
    begin
        WhseJnlLine.Copy(Rec);
        Code();
        Rec.Copy(WhseJnlLine);
    end;

    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlLine: Record "Warehouse Journal Line";
        WarehouseReg: Record "Warehouse Register";
        WhseJnlRegisterBatch: Codeunit "Whse. Jnl.-Register Batch";
        TempJnlBatchName: Code[10];
        IsHandled: Boolean;

#pragma warning disable AA0074
        Text001: Label 'Do you want to register the journal lines?';
        Text002: Label 'There is nothing to register.';
        Text003: Label 'The journal lines were successfully registered.';
#pragma warning disable AA0470
        Text004: Label 'You are now in the %1 journal.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    begin
        WhseJnlTemplate.Get(WhseJnlLine."Journal Template Name");
        WhseJnlTemplate.TestField("Registering Report ID");

        if not Confirm(Text001, false) then
            exit;

        IsHandled := false;
        OnAfterConfirm(WhseJnlLine, IsHandled);
        if IsHandled then
            exit;

        TempJnlBatchName := WhseJnlLine."Journal Batch Name";

        WhseJnlRegisterBatch.Run(WhseJnlLine);
        OnAfterRegisterBatch(WhseJnlLine);

        if WarehouseReg.Get(WhseJnlRegisterBatch.GetWhseRegNo()) then begin
            WarehouseReg.SetRecFilter();
            REPORT.Run(WhseJnlTemplate."Registering Report ID", false, false, WarehouseReg);
        end;

        if WhseJnlLine."Line No." = 0 then
            Message(Text002)
        else
            if TempJnlBatchName = WhseJnlLine."Journal Batch Name" then
                Message(Text003)
            else
                Message(
                  Text003 +
                  Text004,
                  WhseJnlLine."Journal Batch Name");

        if not WhseJnlLine.Find('=><') or (TempJnlBatchName <> WhseJnlLine."Journal Batch Name") then begin
            WhseJnlLine.Reset();
            WhseJnlLine.FilterGroup(2);
            WhseJnlLine.SetRange("Journal Template Name", WhseJnlLine."Journal Template Name");
            WhseJnlLine.SetRange("Journal Batch Name", WhseJnlLine."Journal Batch Name");
            WhseJnlLine.SetRange("Location Code", WhseJnlLine."Location Code");
            WhseJnlLine.FilterGroup(0);
            WhseJnlLine."Line No." := 10000;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConfirm(var WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisterBatch(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;
}

