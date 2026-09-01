// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

codeunit 5643 "FA Reclass. Transfer Batch"
{
    Permissions = TableData "FA Reclass. Journal Batch" = rimd;
    TableNo = "FA Reclass. Journal Line";

    trigger OnRun()
    begin
        FAReclassJnlLine.Copy(Rec);
        Code();
        Rec := FAReclassJnlLine;
    end;

    var
        FAReclassJnlLine: Record "FA Reclass. Journal Line";
        FAReclassJnlTempl: Record "FA Reclass. Journal Template";
        FAReclassJnlBatch: Record "FA Reclass. Journal Batch";
        FAReclassJnlLine2: Record "FA Reclass. Journal Line";
        FAReclassJnlLine3: Record "FA Reclass. Journal Line";
        FAReclassCheckLine: Codeunit "FA Reclass. Check Line";
        FAReclassTransferLine: Codeunit "FA Reclass. Transfer Line";
        Window: Dialog;
        OneFAReclassDone: Boolean;
        LineCounter: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        IsHandled: Boolean;
    begin
        OnBeforeCode(FAReclassJnlLine);

        FAReclassJnlLine.SetRange("Journal Template Name", FAReclassJnlLine."Journal Template Name");
        FAReclassJnlLine.SetRange("Journal Batch Name", FAReclassJnlLine."Journal Batch Name");
        FAReclassJnlLine.LockTable();

        FAReclassJnlTempl.Get(FAReclassJnlLine."Journal Template Name");
        FAReclassJnlBatch.Get(FAReclassJnlLine."Journal Template Name", FAReclassJnlLine."Journal Batch Name");

        if not FAReclassJnlLine.Find('=><') then begin
            FAReclassJnlLine."Line No." := 0;
            exit;
        end;

        Window.Open(
          Text001 +
          Text002 +
          Text003);
        Window.Update(1, FAReclassJnlLine."Journal Batch Name");

        LineCounter := 0;
        StartLineNo := FAReclassJnlLine."Line No.";
        repeat
            LineCounter := LineCounter + 1;
            Window.Update(2, LineCounter);
            FAReclassCheckLine.Run(FAReclassJnlLine);
            if FAReclassJnlLine.Next() = 0 then
                FAReclassJnlLine.Find('-');
        until FAReclassJnlLine."Line No." = StartLineNo;
        NoOfRecords := LineCounter;

        LineCounter := 0;
        OneFAReclassDone := false;
        FAReclassJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "FA Posting Date");
        FAReclassJnlLine.Find('-');

        IsHandled := false;
        OnCodeOnBeforeLoopFAReclassJnlLine(FAReclassJnlLine, NoOfRecords, OneFAReclassDone, IsHandled);
        if not IsHandled then
            repeat
                LineCounter := LineCounter + 1;
                Window.Update(3, LineCounter);
                Window.Update(4, Round(LineCounter / NoOfRecords * 10000, 1));
                FAReclassTransferLine.FAReclassLine(FAReclassJnlLine, OneFAReclassDone);
            until FAReclassJnlLine.Next() = 0;

        FAReclassJnlLine.Init();
        if OneFAReclassDone then
            FAReclassJnlLine."Line No." := 1
        else
            FAReclassJnlLine."Line No." := 0;

        if OneFAReclassDone then begin
            FAReclassJnlLine2.CopyFilters(FAReclassJnlLine);
            FAReclassJnlLine2.SetFilter("FA No.", '<>%1', '');
            if FAReclassJnlLine2.FindLast() then;
            // Remember the last line
            FAReclassJnlLine.DeleteAll();

            FAReclassJnlLine3.SetRange("Journal Template Name", FAReclassJnlLine."Journal Template Name");
            FAReclassJnlLine3.SetRange("Journal Batch Name", FAReclassJnlLine."Journal Batch Name");
            if FAReclassJnlTempl."Increment Batch Name" then
                if not FAReclassJnlLine3.FindLast() then
                    if IncStr(FAReclassJnlLine."Journal Batch Name") <> '' then begin
                        FAReclassJnlBatch.Get(FAReclassJnlLine."Journal Template Name", FAReclassJnlLine."Journal Batch Name");
                        FAReclassJnlBatch.Delete();
                        FAReclassJnlBatch.Name := IncStr(FAReclassJnlLine."Journal Batch Name");
                        if FAReclassJnlBatch.Insert() then;
                        FAReclassJnlLine."Journal Batch Name" := FAReclassJnlBatch.Name;
                    end;

            FAReclassJnlLine3.SetRange("Journal Batch Name", FAReclassJnlLine."Journal Batch Name");
            if not FAReclassJnlLine3.FindLast() then begin
                FAReclassJnlLine3.Init();
                FAReclassJnlLine3."Journal Template Name" := FAReclassJnlLine."Journal Template Name";
                FAReclassJnlLine3."Journal Batch Name" := FAReclassJnlLine."Journal Batch Name";
                FAReclassJnlLine3."Line No." := 10000;
                FAReclassJnlBatch.Get(FAReclassJnlLine."Journal Template Name", FAReclassJnlLine."Journal Batch Name");
                FAReclassJnlLine3."Posting Date" := FAReclassJnlLine2."Posting Date";
                OnBeforeFAReclassJnlLineInsert(FAReclassJnlLine, FAReclassJnlLine2, FAReclassJnlLine3);
                FAReclassJnlLine3.Insert();
            end;
        end;

        Commit();
        Clear(FAReclassCheckLine);
        Clear(FAReclassTransferLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAReclassJnlLineInsert(var FAReclassJournalLine: Record "FA Reclass. Journal Line"; var FAReclassJournalLine2: Record "FA Reclass. Journal Line"; var FAReclassJournalLine3: Record "FA Reclass. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var FAReclassJournalLine: Record "FA Reclass. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeLoopFAReclassJnlLine(var FAReclassJournalLine: Record "FA Reclass. Journal Line"; NoOfRecords: Integer; var OneFAReclassDone: Boolean; var IsHandled: Boolean)
    begin
    end;
}

