// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Posting;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Warehouse.Ledger;
using System.Utilities;

codeunit 244 "Item Jnl.-B.Post+Print"
{
    TableNo = "Item Journal Batch";

    trigger OnRun()
    begin
        ItemJnlBatch.Copy(Rec);
        Code();
        Rec := ItemJnlBatch;
    end;

    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemReg: Record "Item Register";
        WhseReg: Record "Warehouse Register";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        JnlWithErrors: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Do you want to post the journals and print the posting report?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now shown.';
#pragma warning restore AA0074

    local procedure "Code"()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        HideDialog: Boolean;
    begin
        ItemJnlTemplate.Get(ItemJnlBatch."Journal Template Name");
        ItemJnlTemplate.TestField("Posting Report ID");

        HideDialog := false;
        OnBeforePostJournalBatch(ItemJnlBatch, HideDialog);
        if not HideDialog then
            if not ConfirmManagement.GetResponseOrDefault(Text000, false) then
                exit;

        ItemJnlBatch.FindSet();
        repeat
            ItemJnlLine."Journal Template Name" := ItemJnlBatch."Journal Template Name";
            ItemJnlLine."Journal Batch Name" := ItemJnlBatch.Name;
            ItemJnlLine."Line No." := 1;
            Clear(ItemJnlPostBatch);
            if ItemJnlPostBatch.Run(ItemJnlLine) then begin
                OnAfterPostJournalBatch(ItemJnlBatch);
                ItemJnlBatch.Mark(false);
                if ItemReg.Get(ItemJnlPostBatch.GetItemRegNo()) then
                    PrintItemRegister();

                if WhseReg.Get(ItemJnlPostBatch.GetWhseRegNo()) then
                    PrintWhseRegister();
            end else begin
                ItemJnlBatch.Mark(true);
                JnlWithErrors := true;
            end;
        until ItemJnlBatch.Next() = 0;

        if not JnlWithErrors then
            Message(Text001)
        else
            Message(
              Text002 +
              Text003);

        if not ItemJnlBatch.Find('=><') then begin
            ItemJnlBatch.Reset();
            ItemJnlBatch.Name := '';
        end;
    end;

    local procedure PrintItemRegister()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintItemRegister(ItemReg, ItemJnlTemplate, IsHandled);
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
        OnBeforePrintWhseRegister(WhseReg, ItemJnlTemplate, IsHandled);
        if IsHandled then
            exit;

        WhseReg.SetRecFilter();
        Report.Run(ItemJnlTemplate."Whse. Register Report ID", false, false, WhseReg);
    end;

    procedure JournalWithPostingErrors(): Boolean
    begin
        exit(JnlWithErrors);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJournalBatch(var ItemJournalBatch: Record "Item Journal Batch");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintItemRegister(ItemRegister: Record "Item Register"; ItemJnlTemplate: Record "Item Journal Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintWhseRegister(WarehouseRegister: Record "Warehouse Register"; ItemJnlTemplate: Record "Item Journal Template"; var IsHandled: Boolean)
    begin
    end;
}

