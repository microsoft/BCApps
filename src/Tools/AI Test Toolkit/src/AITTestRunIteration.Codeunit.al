// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.AI;
using System.TestTools.TestRunner;

codeunit 149042 "AIT Test Run Iteration"
{
    TableNo = "AIT Test Method Line";
    SingleInstance = true;
    Access = Internal;

    var
        GlobalAITTestMethodLine: Record "AIT Test Method Line";
        GlobalAITTestSuite: Record "AIT Test Suite";
        ActiveAITTestSuite: Record "AIT Test Suite";
        GlobalTestMethodLine: Record "Test Method Line";
        NoOfExecutedLogEntries: Integer;
        UpdateTestSuite: Boolean;
        RunAllTests: Boolean;
        GlobalAITokenUsedByLastTestMethodLine: Integer;
        GlobalExternalAITokenUsedByLastTestMethodLine: Integer;
        GlobalNumberOfTurnsForLastTestMethodLine: Integer;
        GlobalNumberOfTurnsPassedForLastTestMethodLine: Integer;
        GlobalTestAccuracy: Decimal;
        GlobalSessionAITokenUsed: Integer;

    trigger OnRun()
    begin
        if Rec."Codeunit ID" = 0 then
            exit;
        SetAITTestMethodLine(Rec);

        NoOfExecutedLogEntries := 0;
        GlobalAITokenUsedByLastTestMethodLine := 0;
        GlobalExternalAITokenUsedByLastTestMethodLine := 0;
        UpdateTestSuite := true;
        RunAllTests := true;

        InitializeAITTestMethodLineForRun(Rec, ActiveAITTestSuite);
        SetAITTestSuite(ActiveAITTestSuite);

        RunAITTestMethodLine(Rec, ActiveAITTestSuite);
    end;

    local procedure InitializeAITTestMethodLineForRun(var AITTestMethodLine: Record "AIT Test Method Line"; var AITTestSuite: Record "AIT Test Suite")
    begin
        AITTestSuite.Get(AITTestMethodLine."Test Suite Code");
        if AITTestSuite."Started at" < CurrentDateTime() then
            AITTestSuite."Started at" := CurrentDateTime();

        if AITTestMethodLine."Input Dataset" = '' then
            AITTestMethodLine."Input Dataset" := (AITTestSuite."Input Dataset");
    end;

    local procedure RunAITTestMethodLine(var AITTestMethodLine: Record "AIT Test Method Line"; var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        AITEvalLimitProvider: Interface "AIT Eval Limit Provider";
    begin
        AITEvalLimitProvider := GlobalAITTestSuite."Test Type";

        OnBeforeRunIteration(AITTestSuite, AITTestMethodLine, RunAllTests, UpdateTestSuite);
        RunIteration(AITTestMethodLine);

        if AITEvalLimitProvider.IsLimitReached() then
            SetLineStatusToSkipped();

        Commit();

        AITTestSuiteMgt.DecreaseNoOfTestsRunningNow(AITTestSuite);
    end;

    local procedure RunIteration(var AITTestMethodLine: Record "AIT Test Method Line")
    var
        TestMethodLine: Record "Test Method Line";
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
    begin
        AITTestMethodLine.Find();

        if UpdateTestSuite then
            AITALTestSuiteMgt.UpdateALTestSuite(AITTestMethodLine);

        SetAITTestMethodLine(AITTestMethodLine);

        TestMethodLine.SetRange("Test Codeunit", AITTestMethodLine."Codeunit ID");
        TestMethodLine.SetRange("Test Suite", AITTestMethodLine."AL Test Suite");
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        OnBeforeRunTestMethodLine(TestMethodLine);

        TestMethodLine.FindFirst();

        if RunAllTests then
            TestSuiteMgt.RunAllTests(TestMethodLine)
        else
            TestSuiteMgt.RunSelectedTests(TestMethodLine);
    end;

    procedure GetAITTestSuiteTag(): Text[20]
    begin
        exit(ActiveAITTestSuite.Tag);
    end;

    local procedure SetAITTestMethodLine(var AITTestMethodLine: Record "AIT Test Method Line")
    begin
        GlobalAITTestMethodLine := AITTestMethodLine;
    end;

    /// <summary>
    /// Gets the Test Method Line stored through the SetAITTestMethodLine method.
    /// </summary>
    procedure GetAITTestMethodLine(var AITTestMethodLine: Record "AIT Test Method Line")
    begin
        AITTestMethodLine := GlobalAITTestMethodLine;
    end;

    local procedure SetAITTestSuite(var CurrAITTestSuite: Record "AIT Test Suite")
    begin
        GlobalAITTestSuite := CurrAITTestSuite;
    end;

    internal procedure GetAITTestSuite(var CurrAITTestSuite: Record "AIT Test Suite")
    begin
        CurrAITTestSuite := GlobalAITTestSuite;
    end;

    procedure AddToNoOfLogEntriesExecuted()
    begin
        NoOfExecutedLogEntries += 1;
    end;

    procedure GetNoOfLogEntriesExecuted(): Integer
    begin
        exit(NoOfExecutedLogEntries);
    end;

    procedure GetCurrTestMethodLine(): Record "Test Method Line"
    begin
        exit(GlobalTestMethodLine);
    end;

    procedure GetAITokenUsedByLastTestMethodLine(): Integer
    begin
        exit(GlobalAITokenUsedByLastTestMethodLine);
    end;

    procedure GetNumberOfTurnsForLastTestMethodLine(): Integer
    begin
        exit(GlobalNumberOfTurnsForLastTestMethodLine);
    end;

    procedure GetNumberOfTurnsPassedForLastTestMethodLine(): Integer
    begin
        exit(GlobalNumberOfTurnsPassedForLastTestMethodLine);
    end;

    procedure GetAccuracyForLastTestMethodLine(): Decimal
    begin
        exit(GlobalTestAccuracy);
    end;

    procedure SetExternalAITokenUsedByLastTestMethodLine(TokensUsed: Integer)
    begin
        GlobalExternalAITokenUsedByLastTestMethodLine += TokensUsed;
    end;

    local procedure SetLineStatusToSkipped()
    var
        AITTestMethodLine: Record "AIT Test Method Line";
    begin
        if GlobalAITTestMethodLine."Test Suite Code" = '' then
            exit;

        if AITTestMethodLine.Get(GlobalAITTestMethodLine."Test Suite Code", GlobalAITTestMethodLine."Line No.") then begin
            AITTestMethodLine.Validate(Status, AITTestMethodLine.Status::Skipped);
            AITTestMethodLine.Modify(true);
        end;
    end;

    [InternalEvent(false)]
    procedure OnBeforeRunIteration(var AITTestSuite: Record "AIT Test Suite"; var AITTestMethodLine: Record "AIT Test Method Line"; var RunAllTests: Boolean; var UpdateTestSuite: Boolean)
    begin
    end;

    [InternalEvent(false)]
    procedure OnBeforeRunTestMethodLine(var TestMethodLine: Record "Test Method Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", OnBeforeTestMethodRun, '', false, false)]
    local procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var Skip: Boolean)
    var
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        AITContextCU: Codeunit "AIT Test Context Impl.";
        AOAIToken: Codeunit "AOAI Token";
        AITEvalLimitProvider: Interface "AIT Eval Limit Provider";
    begin
        if ActiveAITTestSuite.Code = '' then
            exit;

        if FunctionName = '' then
            exit;

        AITEvalLimitProvider := GlobalAITTestSuite."Test Type";

        // Check if credit limit was reached - if so, skip this test and log it
        if AITEvalLimitProvider.IsLimitReached() then begin
            Skip := true;
            AITTestSuiteMgt.LogSkippedEval(GlobalAITTestMethodLine, FunctionName);
            exit;
        end;

        GlobalTestMethodLine := CurrentTestMethodLine;

        // Update AI Token Consumption
        GlobalAITokenUsedByLastTestMethodLine := 0;
        GlobalExternalAITokenUsedByLastTestMethodLine := 0;

        // Update Turns
        GlobalNumberOfTurnsPassedForLastTestMethodLine := 0;
        GlobalNumberOfTurnsForLastTestMethodLine := 1;

        // Update Test Accuracy
        GlobalTestAccuracy := 0;

        GlobalSessionAITokenUsed := AOAIToken.GetTotalServerSessionTokensConsumed();

        AITContextCU.StartRunProcedureScenario();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", OnAfterTestMethodRun, '', false, false)]
    local procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    var
        AITContextCU: Codeunit "AIT Test Context Impl.";
        AOAIToken: Codeunit "AOAI Token";
        AITEvalLimitProvider: Interface "AIT Eval Limit Provider";
        Accuracy: Decimal;
    begin
        if ActiveAITTestSuite.Code = '' then
            exit;

        if FunctionName = '' then
            exit;

        AITEvalLimitProvider := GlobalAITTestSuite."Test Type";

        // If credit limit was already reached, this test was skipped by the platform - don't log it
        if AITEvalLimitProvider.IsLimitReached() then
            exit;

        GlobalTestMethodLine := CurrentTestMethodLine;

        // Update AI Token Consumption
        GlobalAITokenUsedByLastTestMethodLine := AOAIToken.GetTotalServerSessionTokensConsumed() - GlobalSessionAITokenUsed + GlobalExternalAITokenUsedByLastTestMethodLine;

        // Update Turns
        GlobalNumberOfTurnsForLastTestMethodLine := AITContextCU.GetNumberOfTurns();
        GlobalNumberOfTurnsPassedForLastTestMethodLine := AITContextCU.GetCurrentTurn();

        if not IsSuccess then
            GlobalNumberOfTurnsPassedForLastTestMethodLine -= 1;

        // Update Test Accuracy
        if AITContextCU.GetAccuracy(Accuracy) then
            GlobalTestAccuracy := Accuracy
        else
            GlobalTestAccuracy := GlobalNumberOfTurnsPassedForLastTestMethodLine / GlobalNumberOfTurnsForLastTestMethodLine;

        AITContextCU.EndRunProcedureScenario(CurrentTestMethodLine, IsSuccess);
        Commit();
    end;
}