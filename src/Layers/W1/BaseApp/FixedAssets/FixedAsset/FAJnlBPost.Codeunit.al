// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

using Microsoft.FixedAssets.Journal;

codeunit 5637 "FA. Jnl.-B.Post"
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
        FAJnlPostBatch: Codeunit "FA Jnl.-Post Batch";
        JournalWithErrors: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';
#pragma warning restore AA0074

    local procedure "Code"()
    begin
        FAJnlTemplate.Get(FAJnlBatch."Journal Template Name");
        FAJnlTemplate.TestField("Force Posting Report", false);

        if not Confirm(Text000, false) then
            exit;

        FAJnlBatch.Find('-');
        repeat
            FAJnlLine."Journal Template Name" := FAJnlBatch."Journal Template Name";
            FAJnlLine."Journal Batch Name" := FAJnlBatch.Name;
            FAJnlLine."Line No." := 1;
            Clear(FAJnlPostBatch);
            if FAJnlPostBatch.Run(FAJnlLine) then
                FAJnlBatch.Mark(false)
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
}

