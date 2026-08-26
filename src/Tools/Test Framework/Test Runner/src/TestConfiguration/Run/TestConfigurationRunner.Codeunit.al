// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.Reflection;

/// <summary>
/// Applies the active configuration while a generated suite runs and records the outcome of every
/// test method. For each enabled line of the active configuration the matching provider is asked to
/// contribute per method behavior. All work is a no-op unless a configuration is active, so regular
/// test runs are unaffected.
/// </summary>
codeunit 130474 "Test Configuration Runner"
{
    SingleInstance = true;
    Access = Internal;

    var
        TestConfigurationContext: Codeunit "Test Configuration Context";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    local procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; FunctionName: Text[128])
    var
        TestConfigurationLine: Record "Test Configuration Line";
        Provider: Interface "ITest Configuration Provider";
    begin
        if not TestConfigurationContext.IsActive() then
            exit;
        if CurrentTestMethodLine."Test Suite" <> TestConfigurationContext.GeneratedSuite() then
            exit;
        if not TestSuiteMgt.IsTestMethodLine(FunctionName) then
            exit;

        TestConfigurationLine.SetRange("Configuration Code", TestConfigurationContext.ConfigCode());
        TestConfigurationLine.SetRange("Enabled", true);
        if TestConfigurationLine.FindSet() then
            repeat
                Provider := TestConfigurationLine."Provider";
                Provider.OnBeforeTestMethodRun(CurrentTestMethodLine, TestConfigurationLine.GetSettings(), TestConfigurationContext);
            until TestConfigurationLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterTestMethodRun', '', false, false)]
    local procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; FunctionName: Text[128]; IsSuccess: Boolean)
    var
        TestConfigurationLine: Record "Test Configuration Line";
        Provider: Interface "ITest Configuration Provider";
    begin
        if not TestConfigurationContext.IsActive() then
            exit;
        if CurrentTestMethodLine."Test Suite" <> TestConfigurationContext.GeneratedSuite() then
            exit;
        if not TestSuiteMgt.IsTestMethodLine(FunctionName) then
            exit;

        TestConfigurationLine.SetRange("Configuration Code", TestConfigurationContext.ConfigCode());
        TestConfigurationLine.SetRange("Enabled", true);
        if TestConfigurationLine.FindSet() then
            repeat
                Provider := TestConfigurationLine."Provider";
                Provider.OnAfterTestMethodRun(CurrentTestMethodLine, IsSuccess, TestConfigurationLine.GetSettings(), TestConfigurationContext);
            until TestConfigurationLine.Next() = 0;

        CaptureResult(CurrentTestMethodLine, CodeunitID, FunctionName, IsSuccess);
    end;

    local procedure CaptureResult(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; FunctionName: Text[128]; IsSuccess: Boolean)
    var
        TestConfigurationRunResult: Record "Test Configuration Run Result";
    begin
        TestConfigurationRunResult.Init();
        TestConfigurationRunResult."Base Suite" := TestConfigurationContext.BaseSuite();
        TestConfigurationRunResult."Configuration" := TestConfigurationContext.ConfigCode();
        TestConfigurationRunResult."Generated Suite" := TestConfigurationContext.GeneratedSuite();
        TestConfigurationRunResult."Test Codeunit" := CodeunitID;
        TestConfigurationRunResult."Codeunit Name" := CopyStr(GetCodeunitName(CurrentTestMethodLine), 1, MaxStrLen(TestConfigurationRunResult."Codeunit Name"));
        TestConfigurationRunResult."Method" := CopyStr(FunctionName, 1, MaxStrLen(TestConfigurationRunResult."Method"));
        if IsSuccess then
            TestConfigurationRunResult."Result" := TestConfigurationRunResult."Result"::Success
        else
            TestConfigurationRunResult."Result" := TestConfigurationRunResult."Result"::Failure;
        TestConfigurationRunResult."Seed" := TestConfigurationContext.Seed();
        TestConfigurationRunResult."Seed Set" := TestConfigurationContext.IsSeedSet();
        TestConfigurationRunResult."WorkDate Offset" := TestConfigurationContext.WorkDateFormula();
        TestConfigurationRunResult."WorkDate" := TestConfigurationContext.GetShiftedWorkDate();
        TestConfigurationRunResult."Reverse Codeunits" := TestConfigurationContext.ReverseCodeunits();
        TestConfigurationRunResult."Reverse Methods" := TestConfigurationContext.ReverseMethods();
        TestConfigurationRunResult."One By One" := TestConfigurationContext.OneByOne();
        TestConfigurationRunResult."Duration" := GetTestDuration(CurrentTestMethodLine);
        TestConfigurationRunResult."Executed At" := CurrentDateTime();

        if not IsSuccess then begin
            TestConfigurationRunResult."Error Message Preview" := CurrentTestMethodLine."Error Message Preview";
            TestConfigurationRunResult.SetErrorMessage(TestSuiteMgt.GetFullErrorMessage(CurrentTestMethodLine));
            TestConfigurationRunResult.SetErrorCallStack(TestSuiteMgt.GetErrorCallStack(CurrentTestMethodLine));
        end;

        TestConfigurationRunResult.Insert(true);
    end;

    local procedure GetCodeunitName(TestMethodLine: Record "Test Method Line"): Text
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Codeunit);
        AllObj.SetRange("Object ID", TestMethodLine."Test Codeunit");
        if AllObj.FindFirst() then
            exit(AllObj."Object Name");
        exit(TestMethodLine.Name);
    end;

    local procedure GetTestDuration(TestMethodLine: Record "Test Method Line"): Duration
    begin
        if (TestMethodLine."Start Time" = 0DT) or (TestMethodLine."Finish Time" = 0DT) then
            exit(0);
        exit(TestMethodLine."Finish Time" - TestMethodLine."Start Time");
    end;
}
