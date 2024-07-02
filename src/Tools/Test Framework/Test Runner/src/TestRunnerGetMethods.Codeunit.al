// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130452 "Test Runner - Get Methods"
{
    Subtype = TestRunner;
    TableNo = "Test Method Line";
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd;

    trigger OnRun()
    var
        ALTestSuite: Record "AL Test Suite";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
    begin
        this.CurrentTestMethodLine.Copy(Rec);
        ALTestSuite.Get(Rec."Test Suite");

        if this.UpdateTests then
            this.MaxLineNo := TestSuiteMgt.GetNextMethodNumber(Rec)
        else
            this.MaxLineNo := TestSuiteMgt.GetLastTestLineNo(ALTestSuite);

        CODEUNIT.Run(this.CurrentTestMethodLine."Test Codeunit");
    end;

    var
        CurrentTestMethodLine: Record "Test Method Line";
        MaxLineNo: Integer;
        UpdateTests: Boolean;

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        if (FunctionName = 'OnRun') or (FunctionName = '') then
            exit(true);

        this.OnGetTestMethods(CodeunitID, COPYSTR(CodeunitName, 1, 30), COPYSTR(FunctionName, 1, 128), FunctionTestPermissions);
        this.AddTestMethod(CodeunitID, COPYSTR(FunctionName, 1, 128));

        // Do not run the tests
        exit(false);
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        // This method is invoked by platform
        // It is not used to discover individual test methods
    end;

    procedure SetUpdateTests(NewUpdateTests: Boolean)
    begin
        this.UpdateTests := NewUpdateTests;
    end;

    local procedure AddTestMethod(CodeunitID: Integer; FunctionName: Text[128])
    var
        TestMethodLine: Record "Test Method Line";
        Handled: Boolean;
    begin
        if this.UpdateTests then
            this.MaxLineNo += 100
        else
            this.MaxLineNo += 10000;

        TestMethodLine."Line No." := this.MaxLineNo;
        TestMethodLine.Validate("Test Codeunit", CodeunitID);
        TestMethodLine.Validate("Test Suite", this.CurrentTestMethodLine."Test Suite");
        TestMethodLine.Validate("Line Type", TestMethodLine."Line Type"::"Function");
        TestMethodLine.Validate("Function", FunctionName);
        TestMethodLine.Validate(Run, this.CurrentTestMethodLine.Run);
        this.OnBeforeAddTestMethodLine(TestMethodLine, Handled);
        if not Handled then
            TestMethodLine.Insert(true);

        this.OnAfterAddTestMethodLine(TestMethodLine, this.MaxLineNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTestMethods(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions)
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnBeforeAddTestMethodLine(var TestMethodLine: Record "Test Method Line"; var Handled: Boolean)
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnAfterAddTestMethodLine(var TestMethodLine: Record "Test Method Line"; var MaxLineNo: Integer)
    begin
    end;
}

