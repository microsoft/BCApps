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
    EventSubscriberInstance = Manual;

    var
        GlobalAITTestMethodLine: Record "AIT Test Method Line";
        GlobalAITTestSuite: Record "AIT Test Suite";
        ActiveAITTestSuite: Record "AIT Test Suite";
        GlobalTestMethodLine: Record "Test Method Line";
        NoOfInsertedLogEntries: Integer;
        DeploymentOverride: Option Default,Latest,Preview;
        GlobalAITokenUsedByLastTestMethodLine: Integer;
        GlobalSessionAITokenUsed: Integer;

    trigger OnRun()
    begin
        if Rec."Codeunit ID" = 0 then
            exit;
        SetAITTestMethodLine(Rec);

        NoOfInsertedLogEntries := 0;
        GlobalAITokenUsedByLastTestMethodLine := 0;

        InitializeAITTestMethodLineForRun(Rec, ActiveAITTestSuite);
        SetAITTestSuite(ActiveAITTestSuite);

        SetDeploymentOverride(ActiveAITTestSuite."Model Version");

        RunAITTestMethodLine(Rec, ActiveAITTestSuite);

        ClearSubscription();
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
    begin
        OnBeforeRunIteration(AITTestSuite, AITTestMethodLine);
        RunIteration(AITTestMethodLine);
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
        AITALTestSuiteMgt.UpdateALTestSuite(AITTestMethodLine);
        SetAITTestMethodLine(AITTestMethodLine);

        TestMethodLine.SetRange("Test Codeunit", AITTestMethodLine."Codeunit ID");
        TestMethodLine.SetRange("Test Suite", AITTestMethodLine."AL Test Suite");
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        TestMethodLine.FindFirst();
        TestSuiteMgt.RunAllTests(TestMethodLine);
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

    procedure AddToNoOfLogEntriesInserted()
    begin
        NoOfInsertedLogEntries += 1;
    end;

    procedure GetNoOfLogEntriesInserted(): Integer
    begin
        exit(NoOfInsertedLogEntries);
    end;

    procedure GetCurrTestMethodLine(): Record "Test Method Line"
    begin
        exit(GlobalTestMethodLine);
    end;

    local procedure SetDeploymentOverride(DeploymentOverrideValue: Option Default,Latest,Preview)
    begin
        BindSubscription(this);
        DeploymentOverride := DeploymentOverrideValue;
    end;

    local procedure ClearSubscription()
    begin
        Clear(DeploymentOverride);
        UnbindSubscription(this);
    end;

    procedure GetAITokenUsedByLastTestMethodLine(): Integer
    begin
        exit(GlobalAITokenUsedByLastTestMethodLine);
    end;

    [InternalEvent(false)]
    procedure OnBeforeRunIteration(var AITTestSuite: Record "AIT Test Suite"; var AITTestMethodLine: Record "AIT Test Method Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", OnBeforeTestMethodRun, '', false, false)]
    local procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions)
    var
        AITContextCU: Codeunit "AIT Test Context Impl.";
        AOAIToken: Codeunit "AOAI Token";
    begin
        if ActiveAITTestSuite.Code = '' then
            exit;
        if FunctionName = '' then
            exit;

        GlobalTestMethodLine := CurrentTestMethodLine;

        // Update AI Token Consumption
        GlobalAITokenUsedByLastTestMethodLine := 0;
        GlobalSessionAITokenUsed := AOAIToken.GetTotalServerSessionTokensConsumed();

        AITContextCU.StartRunProcedureScenario();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", OnAfterTestMethodRun, '', false, false)]
    local procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    var
        AITContextCU: Codeunit "AIT Test Context Impl.";
        AOAIToken: Codeunit "AOAI Token";
    begin
        if ActiveAITTestSuite.Code = '' then
            exit;

        if FunctionName = '' then
            exit;

        GlobalTestMethodLine := CurrentTestMethodLine;
        // Update AI Token Consumption
        GlobalAITokenUsedByLastTestMethodLine := AOAIToken.GetTotalServerSessionTokensConsumed() - GlobalSessionAITokenUsed;

        AITContextCU.EndRunProcedureScenario(CurrentTestMethodLine, IsSuccess);
        Commit();
    end;

    [NonDebuggable]
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AOAI Authorization", OnBeforeGetDeployment, '', false, false)]
    local procedure OverrideOnBeforeGetDeployment(var Deployment: Text)
    begin
        case DeploymentOverride of
            DeploymentOverride::Latest:
                Deployment := Deployment.Replace('preview', 'latest');
            DeploymentOverride::Preview:
                Deployment := Deployment.Replace('latest', 'preview');
        end;
    end;
}