// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using System.Environment;
using System.Diagnostics;

codeunit 149929 "Subc WIP Concurrent Worker"
{
    Access = Internal;
    TableNo = "Subc WIP Concurrent Signal";

    trigger OnRun()
    var
        Succeeded: Boolean;
        Failure: Text;
    begin
        Rec.Get(Rec."Run ID", Rec.Worker);
        Rec."Session ID" := SessionId();
        Rec.Ready := true;
        Rec.Modify();
        Commit();
        Succeeded := Codeunit.Run(Codeunit::"Subc WIP Concurrent Action", Rec);
        if not Succeeded then
            Failure := GetLastErrorText();
        Rec.Get(Rec."Run ID", Rec.Worker);
        Rec.Done := true;
        Rec.Succeeded := Succeeded;
        Rec.Failure := CopyStr(Failure, 1, MaxStrLen(Rec.Failure));
        Rec.Modify();
        Commit();
    end;

    internal procedure StartWorker(Signal: Record "Subc WIP Concurrent Signal"): Integer
    var
        NewSessionID: Integer;
    begin
        if not StartSession(NewSessionID, Codeunit::"Subc WIP Concurrent Worker", Signal.CurrentCompany(), Signal) then begin
            Signal.Get(Signal."Run ID", Signal.Worker);
            Signal.Done := true;
            Signal.Succeeded := false;
            Signal.Failure := 'The task-owned WIP test session could not be started.';
            Signal.Modify();
            exit(0);
        end;
        exit(NewSessionID);
    end;

    internal procedure WaitForBlocked(WorkerSessionID: Integer)
    var
        Locks: Record "Database Locks";
        StartedAt: DateTime;
    begin
        if WorkerSessionID = 0 then
            Error('The competing task-owned WIP test session could not be started.');
        StartedAt := CurrentDateTime();
        repeat
            SelectLatestVersion();
            Locks.Reset();
            Locks.SetRange("Session ID", WorkerSessionID);
            if Locks.FindSet() then
                repeat
                    if Format(Locks."Request Status").ToUpper().Contains('WAIT') then
                        exit;
                until Locks.Next() = 0;
            if not IsSessionActive(WorkerSessionID) then
                Error('The competing WIP test session ended without reaching the database-lock barrier.');
            Sleep(10);
        until CurrentDateTime() - StartedAt > 30000;
        Error('The competing WIP test session did not reach the database-lock barrier.');
    end;

    internal procedure WaitForEnd(WorkerSessionID: Integer): Boolean
    var
        StartedAt: DateTime;
    begin
        if WorkerSessionID = 0 then
            exit(false);
        StartedAt := CurrentDateTime();
        while IsSessionActive(WorkerSessionID) do begin
            if CurrentDateTime() - StartedAt > 120000 then begin
                StopSession(WorkerSessionID);
                exit(false);
            end;
            Sleep(10);
        end;
        SelectLatestVersion();
        exit(true);
    end;

    internal procedure ExerciseHeaderRace()
    var
        Company: Record Company;
        Signal: Record "Subc WIP Concurrent Signal";
        Creator: Record "Subc WIP Concurrent Signal";
        Assert: Codeunit Assert;
        RunID: Guid;
        SessionID: Integer;
        Failure: Text;
        Pass: Integer;
    begin
        for Pass := 1 to 2 do begin
            Company.Init();
            Company.Name := CopyStr(Format(CreateGuid(), 0, 4), 1, MaxStrLen(Company.Name));
            Company.Insert(true);
            RunID := CreateGuid();
            Signal.ChangeCompany(Company.Name);
            Signal.Init();
            Signal."Run ID" := RunID;
            Signal.Action := 'PrepareCutover';
            Signal."Order No." := CopyStr(Format(CreateGuid(), 0, 4), 1, MaxStrLen(Signal."Order No."));
            Signal.Insert();
            Creator.ChangeCompany(Company.Name);
            Creator := Signal;
            Creator.Worker := 2;
            Creator.Action := 'CreateHeader';
            Creator."Order No." := CopyStr(Format(CreateGuid(), 0, 4), 1, MaxStrLen(Creator."Order No."));
            Creator."Run Trigger" := Pass = 1;
            Creator.Insert();
            Commit();
            SessionID := StartWorker(Signal);
            WaitForEnd(SessionID);
            Signal.Get(RunID, 0);
            Failure := Signal.Failure;
            if not Signal.Done then
                Failure := 'Cutover preparation timed out.';
            if Signal.Succeeded then begin
                Signal.Worker := 1;
                Signal.Action := 'Activate';
                Signal.Done := false;
                Signal.Succeeded := false;
                Signal.Insert();
                Commit();
                SessionID := StartWorker(Signal);
                WaitForEnd(SessionID);
                Signal.Get(RunID, 1);
                Failure := Signal.Failure;
                if not Signal.Done then
                    Failure := 'Activation timed out.';
                Creator.Get(RunID, 2);
                if Creator."Session ID" <> 0 then
                    WaitForEnd(Creator."Session ID");
                Creator.Get(RunID, 2);
                if not Signal."Blocked Observed" or not Creator.Succeeded or
                   (Creator.Cohort <> Creator.Cohort::StateV1) or IsNullGuid(Creator."Lineage ID")
                then
                    Failure += ' Concurrent header was not serialized and enrolled after activation. ' + Creator.Failure;
                if Failure = '' then begin
                    Creator.Worker := 3;
                    Creator."Order No." := CopyStr(Format(CreateGuid(), 0, 4), 1, MaxStrLen(Creator."Order No."));
                    Creator.Done := false;
                    Creator.Succeeded := false;
                    Creator.Insert();
                    Commit();
                    SessionID := StartWorker(Creator);
                    WaitForEnd(SessionID);
                    Creator.Get(RunID, 3);
                    if not Creator.Succeeded or (Creator.Cohort <> Creator.Cohort::StateV1) then
                        Failure := 'Insertion after the committed marker failed: ' + Creator.Failure;
                end;
            end;
            CleanupCompany(Company, RunID);
            Assert.AreEqual('', Failure, 'Actual header-creation/cutover race failed.');
        end;
    end;

    internal procedure ExerciseClaimRace()
    var
        Company: Record Company;
        Signal: Record "Subc WIP Concurrent Signal";
        Assert: Codeunit Assert;
        RunID: Guid;
        WorkerSessionID: Integer;
        Failure: Text;
        Pass: Integer;
    begin
        RunID := CreateGuid();
        Company.Name := CopyStr(Format(RunID, 0, 4), 1, MaxStrLen(Company.Name));
        CopyCompany(CompanyName(), Company.Name);
        Company.Get(Company.Name);
        Signal.ChangeCompany(Company.Name);
        Signal."Run ID" := RunID;
        Signal.Action := 'PrepareClaims';
        Signal.Insert();
        Commit();
        WorkerSessionID := StartWorker(Signal);
        WaitForEnd(WorkerSessionID);
        Signal.Get(RunID, 0);
        Failure := Signal.Failure;
        if not Signal.Done then
            Failure := 'Native claim-fixture preparation timed out.';
        for Pass := 1 to 2 do
            if Failure = '' then begin
                Signal.Get(RunID, 1);
                Signal.Done := false;
                Signal.Succeeded := false;
                Signal."Expected Available" := 3 - Pass;
                Signal.Modify();
                Commit();
                WorkerSessionID := StartWorker(Signal);
                WaitForEnd(WorkerSessionID);
                Signal.Get(RunID, 1);
                Failure := Signal.Failure;
                if not Signal.Succeeded then
                    Failure := 'Leader claim failed: ' + Failure
                else begin
                    Signal.Worker := 5;
                    Signal.Action := 'VerifyClaims';
                    Signal.Done := false;
                    Signal.Succeeded := false;
                    Signal.Insert();
                    Commit();
                    WorkerSessionID := StartWorker(Signal);
                    WaitForEnd(WorkerSessionID);
                    Signal.Get(RunID, 5);
                    Failure := Signal.Failure;
                    if not Signal.Done then
                        Failure := 'Claim verification timed out.';
                    Signal.Delete();
                    if (Pass = 1) and (Failure = '') then begin
                        Signal.Get(RunID, 1);
                        Signal.Worker := 4;
                        Signal.Action := 'ReleaseClaim';
                        Signal.Done := false;
                        Signal.Succeeded := false;
                        Signal.Insert();
                        Commit();
                        WorkerSessionID := StartWorker(Signal);
                        WaitForEnd(WorkerSessionID);
                        Signal.Get(RunID, 4);
                        Failure := Signal.Failure;
                        if not Signal.Done then
                            Failure := 'Releasing the previous native claim timed out.';
                    end;
                end;
            end;
        CleanupCompany(Company, RunID);
        Assert.AreEqual('', Failure, 'Actual concurrent claim confirmation failed.');
    end;

    local procedure CleanupCompany(var Company: Record Company; RunID: Guid)
    var
        Signal: Record "Subc WIP Concurrent Signal";
    begin
        Signal.ChangeCompany(Company.Name);
        Signal.SetRange("Run ID", RunID);
        if Signal.FindSet() then
            repeat
                if Signal."Session ID" <> 0 then
                    if IsSessionActive(Signal."Session ID") then
                        StopSession(Signal."Session ID");
            until Signal.Next() = 0;
        Company.Delete(true);
        Commit();
    end;
}
