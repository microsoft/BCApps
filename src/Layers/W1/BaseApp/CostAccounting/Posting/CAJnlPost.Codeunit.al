// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Posting;

using Microsoft.CostAccounting.Journal;
using Microsoft.Finance.GeneralLedger.Journal;

codeunit 1108 "CA Jnl.-Post"
{
    TableNo = "Cost Journal Line";

    trigger OnRun()
    begin
        CostJnlLine.Copy(Rec);
        Code();
        Rec := CostJnlLine;
    end;

    var
        CostJnlLine: Record "Cost Journal Line";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
#pragma warning disable AA0074
        Text001: Label 'Do you want to post the journal lines?';
        Text003: Label 'The journal lines were successfully posted.';
#pragma warning disable AA0470
        Text004: Label 'The journal lines were successfully posted. You are now in the %1 journal.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        TempJnlBatchName: Code[10];
    begin
        if not Confirm(Text001) then
            exit;

        TempJnlBatchName := CostJnlLine."Journal Batch Name";
        CODEUNIT.Run(CODEUNIT::"CA Jnl.-Post Batch", CostJnlLine);

        if CostJnlLine."Line No." = 0 then
            Message(JournalErrorsMgt.GetNothingToPostErrorMsg())
        else
            if TempJnlBatchName = CostJnlLine."Journal Batch Name" then
                Message(Text003)
            else
                Message(Text004, CostJnlLine."Journal Batch Name");

        if not CostJnlLine.Find('=><') or (TempJnlBatchName <> CostJnlLine."Journal Batch Name") then begin
            CostJnlLine.Reset();
            CostJnlLine.FilterGroup(2);
            CostJnlLine.SetRange("Journal Template Name", CostJnlLine."Journal Template Name");
            CostJnlLine.SetRange("Journal Batch Name", CostJnlLine."Journal Batch Name");
            CostJnlLine.FilterGroup(0);
            CostJnlLine."Line No." := 1;
        end;
    end;
}

