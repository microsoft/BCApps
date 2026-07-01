// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Posting;

using Microsoft.CostAccounting.Journal;

codeunit 1107 "CA Jnl.-B. Post"
{
    TableNo = "Cost Journal Batch";

    trigger OnRun()
    begin
        CostJnlBatch.Copy(Rec);
        Code();
        Rec := CostJnlBatch;
    end;

    var
        CostJnlBatch: Record "Cost Journal Batch";
#pragma warning disable AA0074
        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'Not all journals were posted. The journals that were not successfully posted are now marked.';
#pragma warning restore AA0074

    local procedure "Code"()
    var
        CostJnlLine: Record "Cost Journal Line";
        CAJnlPostBatch: Codeunit "CA Jnl.-Post Batch";
        JnlWithErrors: Boolean;
    begin
        if not Confirm(Text000) then
            exit;

        CostJnlBatch.Find('-');
        repeat
            CostJnlLine."Journal Template Name" := CostJnlBatch."Journal Template Name";
            CostJnlLine."Journal Batch Name" := CostJnlBatch.Name;
            CostJnlLine."Line No." := 1;
            Clear(CAJnlPostBatch);
            if CAJnlPostBatch.Run(CostJnlLine) then
                CostJnlBatch.Mark(false)
            else begin
                CostJnlBatch.Mark(true);
                JnlWithErrors := true;
            end;
        until CostJnlBatch.Next() = 0;

        if not JnlWithErrors then
            Message(Text001)
        else
            Message(Text002);

        if not CostJnlBatch.Find('=><') then begin
            CostJnlBatch.Reset();
            CostJnlBatch.FilterGroup(2);
            CostJnlBatch.SetRange("Journal Template Name", CostJnlBatch."Journal Template Name");
            CostJnlBatch.FilterGroup(0);
            CostJnlBatch.Name := '';
        end;
    end;
}

