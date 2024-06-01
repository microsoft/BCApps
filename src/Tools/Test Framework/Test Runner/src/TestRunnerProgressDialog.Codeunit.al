// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130455 "Test Runner - Progress Dialog"
{
    EventSubscriberInstance = Manual;
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Dialog: Dialog;
        ExecutingTestsMsg: Label 'Executing Tests...\', Locked = true;
        TestSuiteMsg: Label 'Test Suite    #1###################\', Locked = true;
        TestCodeunitMsg: Label 'Test Codeunit #2################### @3@@@@@@@@@@@@@\', Locked = true;
        TestFunctionMsg: Label 'Test Function #4################### @5@@@@@@@@@@@@@\', Locked = true;
        NoOfResultsMsg: Label 'No. of Results with:\', Locked = true;
        WindowUpdateDateTime: DateTime;
        WindowTestSuccess: Integer;
        WindowTestFailure: Integer;
        WindowTestSkip: Integer;
        SuccessMsg: Label '    Success   #6######\', Locked = true;
        FailureMsg: Label '    Failure   #7######\', Locked = true;
        SkipMsg: Label '    Skip      #8######\', Locked = true;
        WindowNoOfTestCodeunitTotal: Integer;
        WindowNoOfFunctionTotal: Integer;
        WindowNoOfTestCodeunit: Integer;
        WindowNoOfFunction: Integer;
        CurrentCodeunitNumber: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnRunTestSuite', '', false, false)]
    local procedure OpenWindow(var TestMethodLine: Record "Test Method Line")
    var
        CopyTestMethodLine: Record "Test Method Line";
    begin
        if not GuiAllowed() then
            exit;

        CopyTestMethodLine.Copy(TestMethodLine);
        this.WindowNoOfTestCodeunitTotal := CopyTestMethodLine.Count();
        CopyTestMethodLine.Reset();
        CopyTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        CopyTestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::"Function");

        this.WindowNoOfFunctionTotal := CopyTestMethodLine.Count();

        this.Dialog.HideSubsequentDialogs(true);
        this.Dialog.Open(
          this.ExecutingTestsMsg +
          this.TestSuiteMsg +
          this.TestCodeunitMsg +
          this.TestFunctionMsg +
          this.NoOfResultsMsg +
          this.SuccessMsg +
          this.FailureMsg +
          this.SkipMsg);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterRunTestSuite', '', false, false)]
    local procedure CloseWindow(var TestMethodLine: Record "Test Method Line")
    begin
        if not GuiAllowed() then
            exit;

        this.Dialog.Close();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterTestMethodRun', '', false, false)]
    local procedure UpDateWindow(var CurrentTestMethodLine: Record "Test Method Line"; CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        if not GuiAllowed() then
            exit;

        case CurrentTestMethodLine.Result of
            CurrentTestMethodLine.Result::Failure:
                this.WindowTestFailure += 1;
            CurrentTestMethodLine.Result::Success:
                this.WindowTestSuccess += 1;
            else
                this.WindowTestSkip += 1;
        end;

        this.WindowNoOfFunction += 1;

        if this.CurrentCodeunitNumber <> CurrentTestMethodLine."Test Codeunit" then begin
            if this.CurrentCodeunitNumber <> 0 then
                this.WindowNoOfTestCodeunit += 1;
            this.CurrentCodeunitNumber := CurrentTestMethodLine."Test Codeunit";
        end;

        if this.IsTimeForUpdate() then begin
            this.Dialog.Update(1, CurrentTestMethodLine."Test Suite");
            this.Dialog.Update(2, CurrentTestMethodLine."Test Codeunit");
            this.Dialog.Update(4, FunctionName);
            this.Dialog.Update(6, this.WindowTestSuccess);
            this.Dialog.Update(7, this.WindowTestFailure);
            this.Dialog.Update(8, this.WindowTestSkip);

            if this.WindowNoOfTestCodeunitTotal <> 0 then
                this.Dialog.Update(3, Round(this.WindowNoOfTestCodeunit / this.WindowNoOfTestCodeunitTotal * 10000, 1));
            if this.WindowNoOfFunctionTotal <> 0 then
                this.Dialog.Update(5, Round(this.WindowNoOfFunction / this.WindowNoOfFunctionTotal * 10000, 1));
        end;
    end;

    local procedure IsTimeForUpdate(): Boolean
    begin
        if true in [this.WindowUpdateDateTime = 0DT, CurrentDateTime() - this.WindowUpdateDateTime >= 1000] then begin
            this.WindowUpdateDateTime := CurrentDateTime();
            exit(true);
        end;

        exit(false);
    end;
}

