// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;

codeunit 5671 "FA. Jnl.-B.Post+Print"
{
    TableNo = "FA Journal Batch";

    trigger OnRun()
    begin
        FAJnlBatch.Copy(Rec);
        Code();
        Rec.Copy(FAJnlBatch);
    end;

    var
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlBatch: Record "FA Journal Batch";
        FAJnlLine: Record "FA Journal Line";
        FAReg: Record "FA Register";
        JournalWithErrors: Boolean;

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
        FAJnlTemplate.Get(FAJnlBatch."Journal Template Name");
        FAJnlTemplate.TestField("Posting Report ID");
        FAJnlTemplate.TestField("Maint. Posting Report ID");

        HideDialog := false;
        OnBeforePostJournalBatch(FAJnlBatch, HideDialog);
        if not HideDialog then
            if not Confirm(Text000, false) then
                exit;

        FAJnlBatch.Find('-');
        repeat
            FAJnlLine."Journal Template Name" := FAJnlBatch."Journal Template Name";
            FAJnlLine."Journal Batch Name" := FAJnlBatch.Name;
            FAJnlLine."Line No." := 1;
            if CODEUNIT.Run(CODEUNIT::"FA Jnl.-Post Batch", FAJnlLine) then begin
                if FAReg.Get(FAJnlLine."Line No.") then begin
                    FAReg.SetRecFilter();
                    if FAReg."From Entry No." > 0 then
                        REPORT.Run(FAJnlTemplate."Posting Report ID", false, false, FAReg);
                    if FAReg."From Maintenance Entry No." > 0 then
                        REPORT.Run(FAJnlTemplate."Maint. Posting Report ID", false, false, FAReg);
                end;
                FAJnlBatch.Mark(false);
            end
            else begin
                FAJnlBatch.Mark(true);
                JournalWithErrors := true;
            end;
        until FAJnlBatch.Next() = 0;

        if not JournalWithErrors then
            Message(Text001)
        else
            Message(
              Text002 +
              Text003);

        if not FAJnlBatch.Find('=><') then begin
            FAJnlBatch.Reset();
            FAJnlBatch.FilterGroup := 2;
            FAJnlBatch.SetRange("Journal Template Name", FAJnlBatch."Journal Template Name");
            FAJnlBatch.FilterGroup := 0;
            FAJnlBatch.Name := '';
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJournalBatch(var FAJournalBatch: Record "FA Journal Batch"; var HideDialog: Boolean)
    begin
    end;
}

