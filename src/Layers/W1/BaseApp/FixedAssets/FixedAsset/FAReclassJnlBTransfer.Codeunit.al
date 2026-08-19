// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

codeunit 5645 "FA Reclass. Jnl.-B.Transfer"
{
    TableNo = "FA Reclass. Journal Batch";

    trigger OnRun()
    begin
        FAReclassJnlBatch.Copy(Rec);
        Code();
        Rec.Copy(FAReclassJnlBatch);
    end;

    var
        FAReclassJnlTempl: Record "FA Reclass. Journal Template";
        FAReclassJnlBatch: Record "FA Reclass. Journal Batch";
        FAReclassJnlLine: Record "FA Reclass. Journal Line";
        FAReclassTransferBatch: Codeunit "FA Reclass. Transfer Batch";
        JournalWithErrors: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Do you want to reclassify the journals?';
        Text001: Label 'The journals were successfully reclassified.';
        Text002: Label 'It was not possible to reclassify all of the journals. ';
        Text003: Label 'The journals that were not successfully reclassified are now marked.';
#pragma warning restore AA0074

    local procedure "Code"()
    begin
        FAReclassJnlTempl.Get(FAReclassJnlBatch."Journal Template Name");

        if not Confirm(Text000, false) then
            exit;

        FAReclassJnlBatch.Find('-');
        repeat
            FAReclassJnlLine."Journal Template Name" := FAReclassJnlBatch."Journal Template Name";
            FAReclassJnlLine."Journal Batch Name" := FAReclassJnlBatch.Name;
            FAReclassJnlLine."Line No." := 1;

            Clear(FAReclassTransferBatch);
            if FAReclassTransferBatch.Run(FAReclassJnlLine) then
                FAReclassJnlBatch.Mark(false)
            else begin
                FAReclassJnlBatch.Mark(true);
                JournalWithErrors := true;
            end;
        until FAReclassJnlBatch.Next() = 0;

        if not JournalWithErrors then
            Message(Text001)
        else
            Message(
              Text002 +
              Text003);

        if not FAReclassJnlBatch.Find('=><') then begin
            FAReclassJnlBatch.Reset();
            FAReclassJnlBatch.FilterGroup := 2;
            FAReclassJnlBatch.SetRange("Journal Template Name", FAReclassJnlBatch."Journal Template Name");
            FAReclassJnlBatch.FilterGroup := 0;
            FAReclassJnlBatch.Name := '';
        end;
    end;
}

