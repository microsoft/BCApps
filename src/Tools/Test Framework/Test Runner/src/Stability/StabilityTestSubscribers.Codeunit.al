// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.Reflection;

/// <summary>
/// Applies the active stability presets while a generated suite runs and records the outcome of
/// every test method. All work is a no-op unless the stability context is active, so the
/// subscribers have no effect on regular test runs.
/// </summary>
codeunit 130473 "Stability Test Subscribers"
{
    SingleInstance = true;
    Access = Internal;

    var
        StabilityContext: Codeunit "Stability Context";
        StabilityPreset: Codeunit "Stability Preset";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    local procedure ApplyWorkDateOnBeforeTestMethodRun(FunctionName: Text[128])
    begin
        if not StabilityContext.IsActive() then
            exit;

        if not TestSuiteMgt.IsTestMethodLine(FunctionName) then
            exit;

        if StabilityContext.WorkDateOffset() = '' then
            exit;

        WorkDate(StabilityPreset.GetShiftedWorkDate(StabilityContext.BaseWorkDate(), StabilityContext.WorkDateOffset()));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterTestMethodRun', '', false, false)]
    local procedure CaptureResultOnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; FunctionName: Text[128]; IsSuccess: Boolean)
    var
        StabilityRunResult: Record "Stability Run Result";
    begin
        if not StabilityContext.IsActive() then
            exit;

        if not TestSuiteMgt.IsTestMethodLine(FunctionName) then
            exit;

        StabilityRunResult.Init();
        StabilityRunResult."Base Suite" := StabilityContext.BaseSuite();
        StabilityRunResult."Configuration" := StabilityContext.Combination();
        StabilityRunResult."Generated Suite" := StabilityContext.GeneratedSuite();
        StabilityRunResult."Test Codeunit" := CodeunitID;
        StabilityRunResult."Codeunit Name" := CopyStr(GetCodeunitName(CurrentTestMethodLine), 1, MaxStrLen(StabilityRunResult."Codeunit Name"));
        StabilityRunResult."Method" := CopyStr(FunctionName, 1, MaxStrLen(StabilityRunResult."Method"));
        if IsSuccess then
            StabilityRunResult."Result" := StabilityRunResult."Result"::Success
        else
            StabilityRunResult."Result" := StabilityRunResult."Result"::Failure;
        StabilityRunResult."Seed" := StabilityContext.Seed();
        StabilityRunResult."Seed Overridden" := StabilityContext.IsSeedOverridden();
        StabilityRunResult."WorkDate Offset" := StabilityContext.WorkDateOffset();
        StabilityRunResult."WorkDate" := StabilityPreset.GetShiftedWorkDate(StabilityContext.BaseWorkDate(), StabilityContext.WorkDateOffset());
        StabilityRunResult."Reverse Codeunits" := StabilityContext.ReverseCodeunits();
        StabilityRunResult."Reverse Methods" := StabilityContext.ReverseMethods();
        StabilityRunResult."One By One" := StabilityContext.OneByOne();
        StabilityRunResult."Duration" := GetTestDuration(CurrentTestMethodLine);
        StabilityRunResult."Executed At" := CurrentDateTime();

        if not IsSuccess then begin
            StabilityRunResult."Error Message Preview" := CurrentTestMethodLine."Error Message Preview";
            StabilityRunResult.SetErrorMessage(TestSuiteMgt.GetFullErrorMessage(CurrentTestMethodLine));
            StabilityRunResult.SetErrorCallStack(TestSuiteMgt.GetErrorCallStack(CurrentTestMethodLine));
        end;

        StabilityRunResult.Insert(true);
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
