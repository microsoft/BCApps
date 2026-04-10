// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Warehouse.Ledger;

codeunit 242 "Item Jnl.-Post+Print"
{
    TableNo = "Item Journal Line";

    trigger OnRun()
    begin
        ItemJnlLine.Copy(Rec);
        Code();
        Rec.Copy(ItemJnlLine);
    end;

    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlLine: Record "Item Journal Line";
        ItemReg: Record "Item Register";
        WhseReg: Record "Warehouse Register";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        TempJnlBatchName: Code[10];

#pragma warning disable AA0074
        Text000: Label 'cannot be filtered when posting recurring journals';
        Text001: Label 'Do you want to post the journal lines and print the posting report?';
        Text003: Label 'The journal lines were successfully posted.';
        Text004: Label 'The journal lines were successfully posted. ';
#pragma warning disable AA0470
        Text005: Label 'You are now in the %1 journal.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        HideDialog: Boolean;
        SuppressCommit: Boolean;
        IsHandled: Boolean;
    begin
        ItemJnlTemplate.Get(ItemJnlLine."Journal Template Name");
        ItemJnlTemplate.TestField("Posting Report ID");
        if ItemJnlTemplate.Recurring and (ItemJnlLine.GetFilter(ItemJnlLine."Posting Date") <> '') then
            ItemJnlLine.FieldError("Posting Date", Text000);

        HideDialog := false;
        SuppressCommit := false;
        IsHandled := false;
        OnBeforePostJournalBatch(ItemJnlLine, HideDialog, SuppressCommit, IsHandled);
        if IsHandled then
            exit;

        if not HideDialog then
            if not Confirm(Text001, false) then
                exit;

        TempJnlBatchName := ItemJnlLine."Journal Batch Name";

        ItemJnlPostBatch.SetSuppressCommit(SuppressCommit);
        OnCodeOnBeforeItemJnlPostBatchRun(ItemJnlLine);
        ItemJnlPostBatch.Run(ItemJnlLine);

        OnAfterPostJournalBatch(ItemJnlLine);

        if ItemReg.Get(ItemJnlPostBatch.GetItemRegNo()) then
            PrintItemRegister();

        if WhseReg.Get(ItemJnlPostBatch.GetWhseRegNo()) then
            PrintWhseRegister();

        if not HideDialog then
            if (ItemJnlPostBatch.GetItemRegNo() = 0) and
               (ItemJnlPostBatch.GetWhseRegNo() = 0)
            then
                Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
            else
                if TempJnlBatchName = ItemJnlLine."Journal Batch Name" then
                    Message(Text003)
                else
                    Message(
                      Text004 +
                      Text005,
                      ItemJnlLine."Journal Batch Name");

        if not ItemJnlLine.Find('=><') or (TempJnlBatchName <> ItemJnlLine."Journal Batch Name") then begin
            ItemJnlLine.Reset();
            ItemJnlLine.FilterGroup(2);
            ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
            ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
            ItemJnlLine.FilterGroup(0);
            ItemJnlLine."Line No." := 1;
        end;
    end;

    local procedure PrintItemRegister()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintItemRegister(ItemReg, ItemJnlTemplate, IsHandled, ItemJnlLine);
        if IsHandled then
            exit;

        ItemReg.SetRecFilter();
        Report.Run(ItemJnlTemplate."Posting Report ID", false, false, ItemReg);
    end;

    local procedure PrintWhseRegister()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintWhseRegister(WhseReg, ItemJnlTemplate, IsHandled, ItemJnlLine);
        if IsHandled then
            exit;

        WhseReg.SetRecFilter();
        Report.Run(ItemJnlTemplate."Whse. Register Report ID", false, false, WhseReg);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJournalBatch(var ItemJournalLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var ItemJournalLine: Record "Item Journal Line"; var HideDialog: Boolean; var SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintItemRegister(ItemRegister: Record "Item Register"; ItemJournalTemplate: Record "Item Journal Template"; var IsHandled: Boolean; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintWhseRegister(WarehouseRegister: Record "Warehouse Register"; ItemJournalTemplate: Record "Item Journal Template"; var IsHandled: Boolean; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeItemJnlPostBatchRun(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
}

