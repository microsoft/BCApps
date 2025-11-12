// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Threading;

using System.Environment;
using System.IO;
using System.Utilities;

codeunit 490 "Parallel Session Management"
{

    trigger OnRun()
    begin
    end;

    var
        TempParallelSessionEntry: Record "Parallel Session Entry" temporary;
        TempIntegerFreeMemMapFile: Record "Integer" temporary;
        TempInteger: Record "Integer" temporary;
        ActiveSession: Record "Active Session";
        MemoryMappedFile: array[1000] of Codeunit "Memory Mapped File";
        NoOfPSEntries: Integer;
        NoOfActiveSessions: Integer;
        RemainingTasksMsg: Label 'Waiting for background tasks to finish.\Remaining tasks: #1####', Comment = '#1## shows a number.';
        MaxNoOfSessions: Integer;
        NoOfMemMappedFiles: Integer;

    [Scope('OnPrem')]
    procedure NewSessionRunCodeunitWithRecord(CodeunitId: Integer; Parameter: Text; RecordIDToRun: RecordID): Boolean
    begin
        if not CreateNewPSEntry(CodeunitId, Parameter) then
            exit(false);
        TempParallelSessionEntry."Record ID to Process" := RecordIDToRun;
        TempParallelSessionEntry.Modify();
        StartNewSessions();
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure NewSessionRunCodeunitWithBlob(CodeunitId: Integer; Parameter: Text; var TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        if NoOfMemMappedFiles > ArrayLen(MemoryMappedFile) then
            exit(false);
        if not CreateNewPSEntry(CodeunitId, Parameter) then
            exit(false);

        if (NoOfMemMappedFiles = 0) and (TempIntegerFreeMemMapFile.Count = 0) then // init
            for TempIntegerFreeMemMapFile.Number := 1 to ArrayLen(MemoryMappedFile) do
                TempIntegerFreeMemMapFile.Insert();

        if not TempIntegerFreeMemMapFile.FindFirst() then
            exit(false);

        TempParallelSessionEntry."File Exists" := true;
        TempParallelSessionEntry.Modify();

        MemoryMappedFile[TempIntegerFreeMemMapFile.Number].CreateMemoryMappedFileFromTempBlob(
          TempBlob, Format(TempParallelSessionEntry.ID));
        TempIntegerFreeMemMapFile.Delete();
        NoOfMemMappedFiles += 1;

        StartNewSessions();
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure NewSessionRunCodeunit(CodeunitId: Integer; Parameter: Text): Boolean
    begin
        if not CreateNewPSEntry(CodeunitId, Parameter) then
            exit(false);
        StartNewSessions();
        exit(true);
    end;

    local procedure CreateNewPSEntry(CodeunitId: Integer; Parameter: Text): Boolean
    begin
        NoOfPSEntries += 1;
        TempParallelSessionEntry.Init();
        TempParallelSessionEntry.ID := CreateGuid();
        TempParallelSessionEntry."Object ID to Run" := CodeunitId;
        TempParallelSessionEntry.Parameter := CopyStr(Parameter, 1, MaxStrLen(TempParallelSessionEntry.Parameter));
        TempParallelSessionEntry.Insert();
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure NoOfActiveJobs(): Integer
    begin
        exit(NoOfPSEntries + NoOfActiveSessions);
    end;

    [Scope('OnPrem')]
    procedure WaitForAllToFinish(TimeOutInSeconds: Integer): Boolean
    var
        Window: Dialog;
        T0: DateTime;
    begin
        if TimeOutInSeconds = 0 then
            TimeOutInSeconds := 3600;
        T0 := CurrentDateTime + 1000 * TimeOutInSeconds;
        if GuiAllowed then
            Window.Open(RemainingTasksMsg);
        while (NoOfPSEntries > 0) and (CurrentDateTime < T0) do begin
            if GuiAllowed then
                Window.Update(1, NoOfActiveJobs());
            WaitForFreeSessions(TimeOutInSeconds, GetMaxNoOfSessions() - 1);
            StartNewSessions();
        end;
        if GuiAllowed then
            Window.Close();
        exit(WaitForFreeSessions(TimeOutInSeconds, 0));
    end;

    local procedure WaitForFreeSessions(TimeOutInSeconds: Integer; NoOfRemainingSessions: Integer): Boolean
    begin
        if TempInteger.IsEmpty() then
            exit(true);
        if TimeOutInSeconds = 0 then
            TimeOutInSeconds := 3600;
        RefreshActiveSessions();
        while (NoOfActiveSessions > NoOfRemainingSessions) and (TimeOutInSeconds > 0) do begin
            Sleep(2000);
            TimeOutInSeconds -= 2;
            RefreshActiveSessions();
        end;
        exit(NoOfActiveSessions <= NoOfRemainingSessions);
    end;

    local procedure StartNewSessions()
    begin
        RefreshActiveSessions();
        if NoOfActiveSessions >= GetMaxNoOfSessions() then
            exit;

        TempParallelSessionEntry.Reset();
        TempParallelSessionEntry.SetRange(Processed, false);
        if TempParallelSessionEntry.FindSet() then
            repeat
                TempInteger.Init();
                StartSession(TempInteger.Number, TempParallelSessionEntry."Object ID to Run", CompanyName, TempParallelSessionEntry);
                TempInteger.Insert();
                TempParallelSessionEntry.Processed := true;
                TempParallelSessionEntry."Session ID" := TempInteger.Number;
                TempParallelSessionEntry.Modify();
                NoOfActiveSessions += 1;
                NoOfPSEntries -= 1;
            until (TempParallelSessionEntry.Next() = 0) or (NoOfActiveSessions >= GetMaxNoOfSessions());
    end;

    [Scope('OnPrem')]
    procedure RunHeartbeat()
    begin
        StartNewSessions();
    end;

    local procedure RefreshActiveSessions()
    var
        i: Integer;
        MemMappedFileFound: Boolean;
    begin
        TempParallelSessionEntry.Reset();
        if TempInteger.FindSet() then
            repeat
                if not ActiveSession.Get(ServiceInstanceId(), TempInteger.Number) then begin
                    TempInteger.Delete();
                    NoOfActiveSessions -= 1;
                    TempParallelSessionEntry.SetRange("Session ID", TempInteger.Number);
                    if TempParallelSessionEntry.FindFirst() then begin
                        if TempParallelSessionEntry."File Exists" then begin
                            i := 1;
                            MemMappedFileFound := false;
                            while (i < ArrayLen(MemoryMappedFile)) and (not MemMappedFileFound) do begin
                                if not TempIntegerFreeMemMapFile.Get(i) then
                                    if MemoryMappedFile[i].GetName() = Format(TempParallelSessionEntry.ID) then begin
                                        MemoryMappedFile[i].Dispose();
                                        TempIntegerFreeMemMapFile.Number := i;
                                        TempIntegerFreeMemMapFile.Insert();
                                        NoOfMemMappedFiles -= 1;
                                    end;
                                i += 1;
                            end;
                        end;
                        TempParallelSessionEntry.Delete();
                    end;
                end;
            until TempInteger.Next() = 0;
        TempParallelSessionEntry.Reset();
    end;

    [Scope('OnPrem')]
    procedure GetMaxNoOfSessions(): Integer
    begin
        if MaxNoOfSessions <= 0 then
            SetMaxNoOfSessions(10);
        exit(MaxNoOfSessions);
    end;

    [Scope('OnPrem')]
    procedure SetMaxNoOfSessions(NewMaxNoOfSessions: Integer)
    begin
        MaxNoOfSessions := NewMaxNoOfSessions;
        if MaxNoOfSessions > ArrayLen(MemoryMappedFile) then
            MaxNoOfSessions := ArrayLen(MemoryMappedFile);
    end;
}

