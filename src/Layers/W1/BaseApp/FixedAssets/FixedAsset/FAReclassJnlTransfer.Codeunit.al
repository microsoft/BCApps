// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

codeunit 5644 "FA Reclass. Jnl.-Transfer"
{
    TableNo = "FA Reclass. Journal Line";

    trigger OnRun()
    begin
        FAReclassJnlLine.Copy(Rec);
        Code();
        Rec.Copy(FAReclassJnlLine);
    end;

    var
        FAReclassJnlTempl: Record "FA Reclass. Journal Template";
        FAReclassJnlLine: Record "FA Reclass. Journal Line";
        JnlBatchName2: Code[10];

#pragma warning disable AA0074
        Text000: Label 'Do you want to reclassify the journal lines?';
        Text001: Label 'There is nothing to reclassify.';
        Text002: Label 'The journal lines were successfully reclassified.';
#pragma warning disable AA0470
        Text003: Label 'The journal lines were successfully reclassified. You are now in the %1 journal.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCode(FAReclassJnlLine, IsHandled);
        if IsHandled then
            exit;

        FAReclassJnlTempl.Get(FAReclassJnlLine."Journal Template Name");

        if not Confirm(Text000, false) then
            exit;

        JnlBatchName2 := FAReclassJnlLine."Journal Batch Name";

        CODEUNIT.Run(CODEUNIT::"FA Reclass. Transfer Batch", FAReclassJnlLine);

        if FAReclassJnlLine."Line No." = 0 then
            Message(Text001)
        else
            if JnlBatchName2 = FAReclassJnlLine."Journal Batch Name" then
                Message(Text002)
            else
                Message(
                  Text003,
                  FAReclassJnlLine."Journal Batch Name");

        if not FAReclassJnlLine.Find('=><') or (JnlBatchName2 <> FAReclassJnlLine."Journal Batch Name") then begin
            FAReclassJnlLine.Reset();
            FAReclassJnlLine.FilterGroup := 2;
            FAReclassJnlLine.SetRange("Journal Template Name", FAReclassJnlLine."Journal Template Name");
            FAReclassJnlLine.SetRange("Journal Batch Name", FAReclassJnlLine."Journal Batch Name");
            FAReclassJnlLine.FilterGroup := 0;
            FAReclassJnlLine."Line No." := 1;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var FAReclassJournalLine: Record "FA Reclass. Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

