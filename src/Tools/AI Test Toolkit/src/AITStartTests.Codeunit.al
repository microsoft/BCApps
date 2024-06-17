// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Reflection;

codeunit 149036 "AIT Start Tests"
{
    TableNo = "AIT Test Suite";
    Access = Internal;

    trigger OnRun();
    begin
        this.StartAITests(Rec);
    end;

    var
        NothingToRunErr: Label 'There is nothing to run.';
        CannotRunMultipleSuitesInParallelErr: Label 'There is already test run in progress. Start this operaiton after that finishes.';
        RunningTestsMsg: Label 'Running tests...';

    local procedure StartAITests(AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITTestSuiteCU: Codeunit "AIT Test Suite Mgt.";
    begin
        this.ValidateLines(AITTestSuite);
        AITTestSuite.RunID := CreateGuid();
        AITTestSuite.Validate("Started at", CurrentDateTime);
        AITTestSuiteCU.SetRunStatus(AITTestSuite, AITTestSuite.Status::Running);

        AITTestSuite."No. of tests running" := 0;
        AITTestSuite.Version += 1;
        AITTestSuite.Modify();
        Commit();

        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite.Code);
        AITTestMethodLine.SetFilter("Codeunit ID", '<>0');
        AITTestMethodLine.SetRange("Version Filter", AITTestSuite.Version);
        if AITTestMethodLine.IsEmpty() then
            exit;

        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::" ");

        if AITTestMethodLine.FindSet() then
            repeat
                AITTestMethodLine.Validate(Status, AITTestMethodLine.Status::Running);
                AITTestMethodLine.Modify();
                Commit();
                Codeunit.Run(Codeunit::"AIT Test Runner", AITTestMethodLine);
                if AITTestMethodLine.Find() then begin
                    AITTestMethodLine.Validate(Status, AITTestMethodLine.Status::Completed);
                    AITTestMethodLine.Modify();
                    Commit();
                end;
            until AITTestMethodLine.Next() = 0;
    end;

    internal procedure StartAITSuite(var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestSuite2: Record "AIT Test Suite";
        StatusDialog: Dialog;
    begin
        // If there is already a suite running, then error
        AITTestSuite2.SetRange(Status, AITTestSuite2.Status::Running);
        if not AITTestSuite2.IsEmpty then
            Error(this.CannotRunMultipleSuitesInParallelErr);
        Commit();

        StatusDialog.Open(this.RunningTestsMsg);
        Codeunit.Run(Codeunit::"AIT Start Tests", AITTestSuite);
        StatusDialog.Close();
        if AITTestSuite.Find() then;
    end;

    internal procedure StopAITSuite(var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestSuiteCU: Codeunit "AIT Test Suite Mgt.";
    begin
        AITTestSuiteCU.SetRunStatus(AITTestSuite, AITTestSuite.Status::Cancelled);
    end;

    local procedure ValidateLines(AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        CodeunitMetadata: Record "CodeUnit Metadata";
    begin
        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite.Code);

        if not AITTestMethodLine.FindSet() then
            Error(NothingToRunErr);

        repeat
            CodeunitMetadata.Get(AITTestMethodLine."Codeunit ID");
        until AITTestMethodLine.Next() = 0;
    end;
}