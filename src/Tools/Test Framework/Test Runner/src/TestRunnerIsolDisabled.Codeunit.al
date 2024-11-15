// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130451 "Test Runner - Isol. Disabled"
{
    Subtype = TestRunner;
    TableNo = "Test Method Line";
    TestIsolation = Disabled;
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd;

    trigger OnRun()
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        if Rec."Skip Logging Results" then
            TestRunnerMgt.RunTestsWithoutLoggingResults(Rec)
        else begin
            if ALTestSuite.Get(Rec."Test Suite") then
                TestSuiteName := ALTestSuite.Name;

            CurrentTestMethodLine.Copy(Rec);
            TestRunnerMgt.RunTests(Rec);
        end;
    end;

    var
        CurrentTestMethodLine: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";
        TestSuiteName: Code[10];

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        exit(
          TestRunnerMgt.PlatformBeforeTestRun(
            CodeunitID, COPYSTR(CodeunitName, 1, 30), COPYSTR(FunctionName, 1, 128), FunctionTestPermissions, TestSuiteName, CurrentTestMethodLine.GetFilter("Line No.")));
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        TestRunnerMgt.PlatformAfterTestRun(
          CodeunitID, COPYSTR(CodeunitName, 1, 30), COPYSTR(FunctionName, 1, 128), FunctionTestPermissions, IsSuccess, TestSuiteName,
          CurrentTestMethodLine.GetFilter("Line No."));
    end;
}

