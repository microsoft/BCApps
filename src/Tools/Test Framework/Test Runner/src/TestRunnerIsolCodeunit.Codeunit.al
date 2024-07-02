// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130450 "Test Runner - Isol. Codeunit"
{
    Subtype = TestRunner;
    TableNo = "Test Method Line";
    TestIsolation = Codeunit;
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd;

    trigger OnRun()
    begin
        this.ALTestSuite.Get(Rec."Test Suite");
        this.CurrentTestMethodLine.Copy(Rec);
        this.TestRunnerMgt.RunTests(Rec);
    end;

    var
        ALTestSuite: Record "AL Test Suite";
        CurrentTestMethodLine: Record "Test Method Line";
        TestRunnerMgt: Codeunit "Test Runner - Mgt";

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        exit(
          this.TestRunnerMgt.PlatformBeforeTestRun(
            CodeunitID, COPYSTR(CodeunitName, 1, 30), COPYSTR(FunctionName, 1, 128), FunctionTestPermissions, this.ALTestSuite.Name, this.CurrentTestMethodLine.GetFilter("Line No.")));
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        this.TestRunnerMgt.PlatformAfterTestRun(
          CodeunitID, COPYSTR(CodeunitName, 1, 30), COPYSTR(FunctionName, 1, 128), FunctionTestPermissions, IsSuccess, this.ALTestSuite.Name,
          this.CurrentTestMethodLine.GetFilter("Line No."));
    end;
}

