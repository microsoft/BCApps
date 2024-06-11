// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

codeunit 149042 "AIT Test Runner"
{
    TableNo = "AIT Test Method Line";
    SingleInstance = true;
    Access = Internal;

    var
        GlobalAITTestMethodLine: Record "AIT Test Method Line";
        GlobalAITTestSuite: Record "AIT Test Suite";
        ActiveAITTestSuite: Record "AIT Test Suite";
        GlobalTestMethodLine: Record "Test Method Line";
        NoOfInsertedLogEntries: Integer;
        AccumulatedWaitTimeMs: Integer;

    trigger OnRun();
    begin
        if Rec."Codeunit ID" = 0 then
            exit;
        this.SetAITTestMethodLine(Rec);

        this.NoOfInsertedLogEntries := 0;
        this.AccumulatedWaitTimeMs := 0;

        this.InitializeAITTestMethodLineForRun(Rec, this.ActiveAITTestSuite);
        this.SetAITTestSuite(this.ActiveAITTestSuite);

        this.RunAITTestMethodLine(Rec, this.ActiveAITTestSuite);
    end;

    local procedure InitializeAITTestMethodLineForRun(var AITTestMethodLine: Record "AIT Test Method Line"; var AITTestSuite: Record "AIT Test Suite")
    begin
        AITTestSuite.Get(AITTestMethodLine."Test Suite Code");
        if AITTestSuite."Started at" < CurrentDateTime() then
            AITTestSuite."Started at" := CurrentDateTime();

        if AITTestMethodLine."Input Dataset" = '' then
            AITTestMethodLine."Input Dataset" := (AITTestSuite."Input Dataset");

        if AITTestMethodLine."Delay (ms btwn. iter.)" < 1 then
            AITTestMethodLine."Delay (ms btwn. iter.)" := AITTestSuite."Default Delay (ms)";
    end;

    local procedure RunAITTestMethodLine(var AITTestMethodLine: Record "AIT Test Method Line"; var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestSuiteCU: Codeunit "AIT Test Suite Mgt.";
    begin
        this.GetAndClearAccumulatedWaitTimeMs();

        this.OnBeforeRunIteration(AITTestSuite, AITTestMethodLine);
        this.RunIteration(AITTestMethodLine);
        Commit();

        //TODO override delay from line / default delay
        Sleep(AITTestMethodLine."Delay (ms btwn. iter.)");

        AITTestSuiteCU.DecreaseNoOfTestsRunningNow(AITTestSuite);
    end;

    local procedure RunIteration(var AITTestMethodLine: Record "AIT Test Method Line")
    var
        TestMethodLine: Record "Test Method Line";
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
    begin
        AITTestMethodLine.Find();
        AITALTestSuiteMgt.UpdateALTestSuite(AITTestMethodLine);
        this.SetAITTestMethodLine(AITTestMethodLine);

        TestMethodLine.SetRange("Test Codeunit", AITTestMethodLine."Codeunit ID");
        TestMethodLine.SetRange("Test Suite", AITTestMethodLine."AL Test Suite");
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        TestMethodLine.FindFirst();
        TestSuiteMgt.RunAllTests(TestMethodLine);
    end;

    procedure GetAITTestSuiteTag(): Text[20]
    begin
        exit(this.ActiveAITTestSuite.Tag);
    end;

    local procedure SetAITTestMethodLine(var AITTestMethodLine: Record "AIT Test Method Line")
    begin
        this.GlobalAITTestMethodLine := AITTestMethodLine;
    end;

    /// <summary>
    /// Gets the AIT Line stored through the SetAITTestMethodLine method.
    /// </summary>
    procedure GetAITTestMethodLine(var AITTestMethodLine: Record "AIT Test Method Line")
    begin
        AITTestMethodLine := this.GlobalAITTestMethodLine;
    end;

    local procedure SetAITTestSuite(var CurrAITTestSuite: Record "AIT Test Suite")
    begin
        this.GlobalAITTestSuite := CurrAITTestSuite;
    end;

    procedure GetAITTestSuite(var CurrAITTestSuite: Record "AIT Test Suite")
    begin
        CurrAITTestSuite := this.GlobalAITTestSuite;
    end;

    procedure AddToNoOfLogEntriesInserted()
    begin
        this.NoOfInsertedLogEntries += 1;
    end;

    procedure GetNoOfLogEntriesInserted(): Integer
    var
        ReturnValue: Integer;
    begin
        ReturnValue := this.NoOfInsertedLogEntries;
        exit(ReturnValue);
    end;

    procedure AddToAccumulatedWaitTimeMs(ms: Integer)
    begin
        this.AccumulatedWaitTimeMs += ms;
    end;

    procedure GetAndClearAccumulatedWaitTimeMs(): Integer
    var
        ReturnValue: Integer;
    begin
        ReturnValue := this.AccumulatedWaitTimeMs;
        this.AccumulatedWaitTimeMs := 0;
        exit(ReturnValue);
    end;

    procedure GetCurrTestMethodLine(): Record "Test Method Line"
    begin
        exit(this.GlobalTestMethodLine);
    end;

    [InternalEvent(false)]
    procedure OnBeforeRunIteration(var AITTestSuite: Record "AIT Test Suite"; var AITTestMethodLine: Record "AIT Test Method Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", OnBeforeTestMethodRun, '', false, false)]
    local procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions)
    var
        AITContextCU: Codeunit "AIT Test Context";
    begin
        if this.ActiveAITTestSuite.Code = '' then // exit the code if not triggered by AIT 
            exit;
        if FunctionName = '' then
            exit;

        GlobalTestMethodLine := CurrentTestMethodLine;

        AITContextCU.StartRunProcedureScenario();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", OnAfterTestMethodRun, '', false, false)]
    local procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    var
        AITContextCU: Codeunit "AIT Test Context";
    begin
        if this.ActiveAITTestSuite.Code = '' then // exit the code if not triggered by AIT 
            exit;
        if FunctionName = '' then
            exit;

        GlobalTestMethodLine := CurrentTestMethodLine;
        AITContextCU.EndRunProcedureScenario(CurrentTestMethodLine, IsSuccess);
        Commit();
    end;
}