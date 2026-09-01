// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

codeunit 7303 "Whse. Jnl.-Register"
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
        TempJnlBatchName: Code[10];

#pragma warning disable AA0074
        Text001: Label 'Do you want to register the journal lines?';
        Text002: Label 'There is nothing to register.';
        Text003: Label 'The journal lines were successfully registered.';
#pragma warning disable AA0470
        Text004: Label 'You are now in the %1 journal.';
#pragma warning restore AA0470
        Text005: Label 'Do you want to register and post the journal lines?';
#pragma warning restore AA0074

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(WhseJnlLine, IsHandled);
        if IsHandled then
            exit;

        WhseJnlTemplate.Get(WhseJnlLine."Journal Template Name");
        WhseJnlTemplate.TestField("Force Registering Report", false);

        if not ConfirmRegisterLines(WhseJnlLine) then
            exit;

        TempJnlBatchName := WhseJnlLine."Journal Batch Name";

        CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register Batch", WhseJnlLine);

        IsHandled := false;
        OnCodeOnBeforeRegisterWarehouseJournalLine(WhseJnlLine, TempJnlBatchName, IsHandled);
        if not IsHandled then
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

    local procedure ConfirmRegisterLines(WhseJnlLine: Record "Warehouse Journal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConfirmRegisterLines(WhseJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if WhseJnlLine.ItemTrackingReclass(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", WhseJnlLine."Location Code", 0) then begin
            if not Confirm(Text005, false) then
                exit(false)
        end else
            if not Confirm(Text001, false) then
                exit(false);

        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WhseJnlLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmRegisterLines(var WhseJnlLine: Record "Warehouse Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCodeOnBeforeRegisterWarehouseJournalLine(var WarehouseJnlLine: Record "Warehouse Journal Line"; var TempJnlBatchName: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

