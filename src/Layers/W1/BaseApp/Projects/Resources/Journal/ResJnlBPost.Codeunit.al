// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Journal;

codeunit 273 "Res. Jnl.-B.Post"
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
        ResJnlPostBatch: Codeunit "Res. Jnl.-Post Batch";
        JnlWithErrors: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';
#pragma warning restore AA0074

    local procedure "Code"()
    begin
        ResJnlTemplate.Get(ResJnlBatch."Journal Template Name");
        ResJnlTemplate.TestField("Force Posting Report", false);

        if not Confirm(Text000) then
            exit;

        ResJnlBatch.Find('-');
        repeat
            ResJnlLine."Journal Template Name" := ResJnlBatch."Journal Template Name";
            ResJnlLine."Journal Batch Name" := ResJnlBatch.Name;
            ResJnlLine."Line No." := 1;
            Clear(ResJnlPostBatch);
            if ResJnlPostBatch.Run(ResJnlLine) then
                ResJnlBatch.Mark(false)
            else begin
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
            ResJnlBatch.FilterGroup(2);
            ResJnlBatch.SetRange("Journal Template Name", ResJnlBatch."Journal Template Name");
            ResJnlBatch.FilterGroup(0);
            ResJnlBatch.Name := '';
        end;
    end;
}

