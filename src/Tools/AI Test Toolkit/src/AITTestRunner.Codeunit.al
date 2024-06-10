// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.TestTools.TestRunner;

codeunit 149042 "AIT Test Runner"
{
    TableNo = "AIT Line";
    SingleInstance = true;
    Access = Internal;

    var
        GlobalAITLine: Record "AIT Line";
        GlobalAITHeader: Record "AIT Header";
        ActiveAITHeader: Record "AIT Header";
        GlobalTestMethodLine: Record "Test Method Line";
        NoOfInsertedLogEntries: Integer;
        AccumulatedWaitTimeMs: Integer;

    trigger OnRun();
    begin
        if Rec."Codeunit ID" = 0 then
            exit;
        this.SetAITLine(Rec);

        this.NoOfInsertedLogEntries := 0;
        this.AccumulatedWaitTimeMs := 0;

        this.InitializeAITLineForRun(Rec, this.ActiveAITHeader);
        this.SetAITHeader(this.ActiveAITHeader);

        this.RunAITLine(Rec, this.ActiveAITHeader);
    end;

    local procedure InitializeAITLineForRun(var AITLine: Record "AIT Line"; var AITHeader: Record "AIT Header")
    begin
        AITHeader.Get(AITLine."AIT Code");
        if AITHeader."Started at" < CurrentDateTime() then
            AITHeader."Started at" := CurrentDateTime();

        if AITLine."Input Dataset" = '' then
            AITLine."Input Dataset" := (AITHeader."Input Dataset");

        if AITLine."Delay (ms btwn. iter.)" < 1 then
            AITLine."Delay (ms btwn. iter.)" := AITHeader."Default Delay (ms)";
    end;

    local procedure RunAITLine(var AITLine: Record "AIT Line"; var AITHeader: Record "AIT Header")
    var
        AITHeaderCU: Codeunit "AIT Header";
    begin
        this.GetAndClearAccumulatedWaitTimeMs();

        this.OnBeforeRunIteration(AITHeader, AITLine);
        this.RunIteration(AITLine);
        Commit();

        //TODO override delay from line / default delay
        Sleep(AITLine."Delay (ms btwn. iter.)");

        AITHeaderCU.DecreaseNoOfTestsRunningNow(AITHeader);
    end;

    local procedure RunIteration(var AITLine: Record "AIT Line")
    var
        TestMethodLine: Record "Test Method Line";
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
    begin
        AITLine.Find();
        AITTALTestSuiteMgt.UpdateALTestSuite(AITLine);
        this.SetAITLine(AITLine);

        TestMethodLine.SetRange("Test Codeunit", AITLine."Codeunit ID");
        TestMethodLine.SetRange("Test Suite", AITLine."AL Test Suite");
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        TestMethodLine.FindFirst();
        TestSuiteMgt.RunAllTests(TestMethodLine);
    end;

    procedure GetAITHeaderTag(): Text[20]
    begin
        exit(this.ActiveAITHeader.Tag);
    end;

    local procedure SetAITLine(var AITLine: Record "AIT Line")
    begin
        this.GlobalAITLine := AITLine;
    end;

    /// <summary>
    /// Gets the AIT Line stored through the SetAITLine method.
    /// </summary>
    procedure GetAITLine(var AITLine: Record "AIT Line")
    begin
        AITLine := this.GlobalAITLine;
    end;

    local procedure SetAITHeader(var CurrAITHeader: Record "AIT Header")
    begin
        this.GlobalAITHeader := CurrAITHeader;
    end;

    procedure GetAITHeader(var CurrAITHeader: Record "AIT Header")
    begin
        CurrAITHeader := this.GlobalAITHeader;
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
    procedure OnBeforeRunIteration(var AITHeader: Record "AIT Header"; var AITLine: Record "AIT Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", OnBeforeTestMethodRun, '', false, false)]
    local procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions)
    var
        AITContextCU: Codeunit "AIT Test Context";
    begin
        if this.ActiveAITHeader.Code = '' then // exit the code if not triggered by AIT 
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
        if this.ActiveAITHeader.Code = '' then // exit the code if not triggered by AIT 
            exit;
        if FunctionName = '' then
            exit;

        GlobalTestMethodLine := CurrentTestMethodLine;
        AITContextCU.EndRunProcedureScenario(CurrentTestMethodLine, IsSuccess);
        Commit();
    end;
}