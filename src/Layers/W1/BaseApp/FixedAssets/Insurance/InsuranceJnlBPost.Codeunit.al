// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

codeunit 5655 "Insurance Jnl.-B.Post"
{
    TableNo = "Insurance Journal Batch";

    trigger OnRun()
    begin
        InsuranceJnlBatch.Copy(Rec);
        Code();
        Rec.Copy(InsuranceJnlBatch);
    end;

    var
        InsuranceJnlTempl: Record "Insurance Journal Template";
        InsuranceJnlBatch: Record "Insurance Journal Batch";
        InsuranceJnlLine: Record "Insurance Journal Line";
        InsuranceJnlPostBatch: Codeunit "Insurance Jnl.-Post Batch";
        JournalWithErrors: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Do you want to post the journals?';
        Text001: Label 'The journals were successfully posted.';
        Text002: Label 'It was not possible to post all of the journals. ';
        Text003: Label 'The journals that were not successfully posted are now marked.';
#pragma warning restore AA0074

    local procedure "Code"()
    begin
        InsuranceJnlTempl.Get(InsuranceJnlBatch."Journal Template Name");
        InsuranceJnlTempl.TestField("Force Posting Report", false);

        if not Confirm(Text000, false) then
            exit;

        InsuranceJnlBatch.Find('-');
        repeat
            InsuranceJnlLine."Journal Template Name" := InsuranceJnlBatch."Journal Template Name";
            InsuranceJnlLine."Journal Batch Name" := InsuranceJnlBatch.Name;
            InsuranceJnlLine."Line No." := 1;

            Clear(InsuranceJnlPostBatch);
            if InsuranceJnlPostBatch.Run(InsuranceJnlLine) then
                InsuranceJnlBatch.Mark(false)
            else begin
                InsuranceJnlBatch.Mark(true);
                JournalWithErrors := true;
            end;
        until InsuranceJnlBatch.Next() = 0;

        if not JournalWithErrors then
            Message(Text001)
        else
            Message(
              Text002 +
              Text003);

        if not InsuranceJnlBatch.Find('=><') then begin
            InsuranceJnlBatch.Reset();
            InsuranceJnlBatch.FilterGroup := 2;
            InsuranceJnlBatch.SetRange("Journal Template Name", InsuranceJnlBatch."Journal Template Name");
            InsuranceJnlBatch.FilterGroup := 0;
            InsuranceJnlBatch.Name := '';
        end;
    end;
}

