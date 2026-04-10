// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Posting;

using Microsoft.Inventory.Journal;
using System.Utilities;

codeunit 243 "Item Jnl.-B.Post"
{
    TableNo = "Item Journal Batch";

    trigger OnRun()
    begin
        ItemJnlBatch.Copy(Rec);
        Code();
        Rec.Copy(ItemJnlBatch);
    end;

    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        JnlWithErrors: Boolean;
        IsHandled: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now shown.';
#pragma warning restore AA0074

    local procedure "Code"()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ItemJnlTemplate.Get(ItemJnlBatch."Journal Template Name");
        ItemJnlTemplate.TestField("Force Posting Report", false);

        IsHandled := false;
        OnCodeOnBeforeConfirm(IsHandled);
        if not IsHandled then
            if not ConfirmManagement.GetResponseOrDefault(Text000, false) then
                exit;

        ItemJnlBatch.FindSet();
        repeat
            ItemJnlLine."Journal Template Name" := ItemJnlBatch."Journal Template Name";
            ItemJnlLine."Journal Batch Name" := ItemJnlBatch.Name;
            ItemJnlLine."Line No." := 1;
            Clear(ItemJnlPostBatch);
            if ItemJnlPostBatch.Run(ItemJnlLine) then
                ItemJnlBatch.Mark(false)
            else begin
                ItemJnlBatch.Mark(true);
                JnlWithErrors := true;
            end;
        until ItemJnlBatch.Next() = 0;

        IsHandled := false;
        OnCodeOnBeforeMessage(IsHandled);
        if not IsHandled then
            if not JnlWithErrors then
                Message(Text001)
            else
                Message(Text002 + Text003);

        if not ItemJnlBatch.Find('=><') then begin
            ItemJnlBatch.Reset();
            ItemJnlBatch.FilterGroup(2);
            ItemJnlBatch.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
            ItemJnlBatch.FilterGroup(0);
            ItemJnlBatch.Name := '';
        end;

        OnAfterCode(JnlWithErrors);
    end;

    procedure JournalWithPostingErrors(): Boolean
    begin
        exit(JnlWithErrors);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(JnlWithErrors: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeConfirm(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeMessage(var IsHandled: Boolean)
    begin
    end;
}

