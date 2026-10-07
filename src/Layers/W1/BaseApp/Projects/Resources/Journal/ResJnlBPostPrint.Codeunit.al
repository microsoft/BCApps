// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

using Microsoft.Projects.Resources.Ledger;

codeunit 274 "Res. Jnl.-B.Post+Print"
{
    TableNo = "Res. Journal Batch";

    trigger OnRun()
    begin
        ResJnlBatch.Copy(Rec);
        Code();
        Rec := ResJnlBatch;
    end;

    var
        ResJnlTemplate: Record "Res. Journal Template";
        ResJnlBatch: Record "Res. Journal Batch";
        ResJnlLine: Record "Res. Journal Line";
        ResReg: Record "Resource Register";
        ResJnlPostBatch: Codeunit "Res. Jnl.-Post Batch";
        JnlWithErrors: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Do you want to post the journals and print the posting report?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';
#pragma warning restore AA0074

    local procedure "Code"()
    var
        HideDialog: Boolean;
    begin
        ResJnlTemplate.Get(ResJnlBatch."Journal Template Name");
        ResJnlTemplate.TestField("Posting Report ID");

        HideDialog := false;
        OnBeforePostJournalBatch(ResJnlBatch, HideDialog);
        if not HideDialog then
            if not Confirm(Text000) then
                exit;

        ResJnlBatch.Find('-');
        repeat
            ResJnlLine."Journal Template Name" := ResJnlBatch."Journal Template Name";
            ResJnlLine."Journal Batch Name" := ResJnlBatch.Name;
            ResJnlLine."Line No." := 1;
            Clear(ResJnlPostBatch);
            if ResJnlPostBatch.Run(ResJnlLine) then begin
                OnAfterPostJournalBatch(ResJnlBatch);
                ResJnlBatch.Mark(false);
                if ResReg.Get(ResJnlLine."Line No.") then begin
                    ResReg.SetRecFilter();
                    REPORT.Run(ResJnlTemplate."Posting Report ID", false, false, ResReg);
                end;
            end else begin
                ResJnlBatch.Mark(true);
                JnlWithErrors := true;
            end;
        until ResJnlBatch.Next() = 0;

        if not JnlWithErrors then
            Message(Text001)
        else
            Message(
                Text002 +
                Text003);

        if not ResJnlBatch.Find('=><') then begin
            ResJnlBatch.Reset();
            ResJnlBatch.Name := '';
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJournalBatch(var ResJournalBatch: Record "Res. Journal Batch");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var ResJournalBatch: Record "Res. Journal Batch"; var HideDialog: Boolean)
    begin
    end;
}

