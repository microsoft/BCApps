// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestTools.TestRunner;

using System.TestTools.CodeCoverage;

codeunit 130402 "CAL Command Line Test Runner"
{
    Subtype = TestRunner;
    TestIsolation = Codeunit;

    trigger OnRun()
    var
        CALTestEnabledCodeunit: Record "CAL Test Enabled Codeunit";
        CALTestResult: Record "CAL Test Result";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        CALTestMgt: Codeunit "CAL Test Management";
    begin
        SelectLatestVersion();
        TestRunNo := CALTestResult.LastTestRunNo() + 1;
        CompanyWorkDate := WorkDate();

        if CALTestEnabledCodeunit.FindSet() then
            repeat
                if CALTestMgt.DoesTestCodeunitExist(CALTestEnabledCodeunit."Test Codeunit ID") then begin
                    CodeCoverageMgt.Start(true);
                    CODEUNIT.Run(CALTestEnabledCodeunit."Test Codeunit ID");
                    CodeCoverageMgt.Stop();
                    CALTestMgt.ExtendTestCoverage(CALTestEnabledCodeunit."Test Codeunit ID");
                end;
            until CALTestEnabledCodeunit.Next() = 0
    end;

    var
        CALTestRunnerPublisher: Codeunit "CAL Test Runner Publisher";
        TestRunNo: Integer;
        CompanyWorkDate: Date;

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    var
        CALTestResult: Record "CAL Test Result";
    begin
        if FunctionName = '' then
            exit(true);

        CALTestRunnerPublisher.SetSeed(1);
        ApplicationArea('');

        WorkDate := CompanyWorkDate;

        ClearLastError();
        CALTestResult.Initialize(TestRunNo, CodeunitID, FunctionName, CurrentDateTime);
        exit(true)
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; Success: Boolean)
    var
        CALTestResult: Record "CAL Test Result";
    begin
        if FunctionName = '' then
            exit;

        CALTestResult.FindLast();
        CALTestResult.Update(Success, CurrentDateTime);

        ApplicationArea('');
    end;
}

