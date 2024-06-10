// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;

codeunit 149036 "AIT Start Tests"
{
    TableNo = "AIT Header";
    Access = Internal;

    trigger OnRun();
    begin
        this.StartAITests(Rec);
    end;

    var
        NothingToRunErr: Label 'There is nothing to run.';
        CannotRunMultipleSuitesInParallelErr: Label 'There is already test run in progress. Start this operaiton after that finishes.';
        RunningTestsMsg: Label 'Running tests...';

    local procedure StartAITests(AITHeader: Record "AIT Header")
    var
        AITLine: Record "AIT Line";
        AITHeaderCU: Codeunit "AIT Header";
    begin
        this.ValidateLines(AITHeader);
        AITHeader.RunID := CreateGuid();
        AITHeader.Validate("Started at", CurrentDateTime);
        AITHeaderCU.SetRunStatus(AITHeader, AITHeader.Status::Running);

        AITHeader."No. of tests running" := 0;
        AITHeader.Version += 1;
        AITHeader.Modify();
        Commit();

        AITLine.SetRange("AIT Code", AITHeader.Code);
        AITLine.SetFilter("Codeunit ID", '<>0');
        AITLine.SetRange("Version Filter", AITHeader.Version);
        if AITLine.FindSet() then begin
            AITLine.ModifyAll(Status, AITLine.Status::Running);
            Commit();
            Codeunit.Run(Codeunit::"AIT Test Runner", AITLine);
        end;
    end;

    internal procedure StartAITSuite(var AITHeader: Record "AIT Header")
    var
        AITHeader2: Record "AIT Header";
        StatusDialog: Dialog;
    begin
        // If there is already a suite running, then error
        AITHeader2.SetRange(Status, AITHeader2.Status::Running);
        if not AITHeader2.IsEmpty then
            Error(this.CannotRunMultipleSuitesInParallelErr);
        Commit();

        StatusDialog.Open(this.RunningTestsMsg);
        Codeunit.Run(Codeunit::"AIT Start Tests", AITHeader);
        StatusDialog.Close();
        if AITHeader.Find() then;
    end;

    internal procedure StopAITSuite(var AITHeader: Record "AIT Header")
    var
        AITHeaderCU: Codeunit "AIT Header";
    begin
        AITHeaderCU.SetRunStatus(AITHeader, AITHeader.Status::Cancelled);
    end;

    internal procedure StartNextTestSuite(AITHeader: Record "AIT Header")
    var
        AITHeader2: Record "AIT Header";
        AITLine: Record "AIT Line";
        AITHeaderCU: Codeunit "AIT Header";
    begin
        AITHeader2.SetRange(Status, AITHeader2.Status::Running);
        AITHeader2.SetFilter(Code, '<> %1', AITHeader.Code);
        if not AITHeader2.IsEmpty() then
            Error(this.CannotRunMultipleSuitesInParallelErr);

        AITHeader.ReadIsolation(IsolationLevel::UpdLock);
        AITHeader.Find();
        if AITHeader.Status <> AITHeader.Status::Running then begin
            AITHeader.RunID := CreateGuid();
            AITHeader.Validate("Started at", CurrentDateTime);
            AITHeaderCU.SetRunStatus(AITHeader, AITHeader.Status::Running);

            AITHeader."No. of tests running" := 0;
            AITHeader.Version += 1;
            AITHeader."No. of tests running" := 0;
            AITHeader.Modify();

            AITLine.SetRange("AIT Code", AITHeader.Code);
            if AITLine.FindSet(true) then
                repeat
                    AITLine.Status := AITLine.Status::" ";
                    AITLine."Total Duration (ms)" := 0;
                    AITLine."No. of Tests" := 0;
                    AITLine.SetRange("Version Filter", AITHeader.Version);
                    AITLine.Modify(true);
                until AITLine.Next() = 0;
        end;

        AITLine.ReadIsolation(IsolationLevel::UpdLock);
        AITLine.SetRange("AIT Code", AITHeader.Code);
        AITLine.SetFilter("Codeunit ID", '<>0');
        AITLine.SetFilter(Status, '%1 | %2', AITLine.Status::" ", AITLine.Status::Starting);
        if AITLine.FindFirst() then begin
            AITHeader."No. of tests running" += 1;
            AITLine.Status := AITLine.Status::Running;
            AITHeader.Modify();
            AITLine.Modify();
            Commit();
            AITLine.SetRange("Line No.", AITLine."Line No.");
            AITLine.SetRange(Status);
            Codeunit.Run(Codeunit::"AIT Test Runner", AITLine);
        end else
            Error(this.NothingToRunErr);
    end;

    local procedure ValidateLines(AITHeader: Record "AIT Header")
    var
        AITLine: Record "AIT Line";
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        AITLine.SetRange("AIT Code", AITHeader.Code);

        if not AITLine.FindSet() then
            Error('There is nothing to run.');

        repeat
            CodeunitMetadata.Get(AITLine."Codeunit ID");
        until AITLine.Next() = 0;
    end;
}