namespace System.TestTools.TestRunner;

using System.TestTools.CodeCoverage;

codeunit 130400 "CAL Test Runner"
{
    Subtype = TestRunner;
    TableNo = "CAL Test Line";
    TestIsolation = Codeunit;

    trigger OnRun()
    begin
        if CALTestSuite.Get(Rec."Test Suite") then begin
            CALTestLine.Copy(Rec);
            CALTestLine.SetRange("Test Suite", Rec."Test Suite");
            RunTests();
        end;
    end;

    var
        CALTestSuite: Record "CAL Test Suite";
        CALTestLine: Record "CAL Test Line";
        CALTestLineFunction: Record "CAL Test Line";
        CALTestMgt: Codeunit "CAL Test Management";
        CALTestRunnerPublisher: Codeunit "CAL Test Runner Publisher";
        Window: Dialog;
        CompanyWorkDate: Date;
        TestRunNo: Integer;
        MaxLineNo: Integer;
        MinLineNo: Integer;
        "Filter": Text;
        ExecutingTestsMsg: Label 'Executing Tests...\', Locked = true;
        TestSuiteMsg: Label 'Test Suite    #1###################\', Locked = true;
        TestCodeunitMsg: Label 'Test Codeunit #2################### @3@@@@@@@@@@@@@\', Locked = true;
        TestFunctionMsg: Label 'Test Function #4################### @5@@@@@@@@@@@@@\', Locked = true;
        NoOfResultsMsg: Label 'No. of Results with:\', Locked = true;
        WindowUpdateDateTime: DateTime;
        WindowIsOpen: Boolean;
        WindowTestSuite: Code[10];
        WindowTestGroup: Text;
        WindowTestCodeunit: Text;
        WindowTestFunction: Text;
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

    local procedure RunTests()
    var
        CALTestResult: Record "CAL Test Result";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
    begin
        OnBeforeRunTests(CALTestLine);
        OpenWindow();
        CALTestLine.ModifyAll(Result, CALTestLine.Result::" ");
        CALTestLine.ModifyAll("First Error", '');
        Commit();
        TestRunNo := CALTestResult.LastTestRunNo() + 1;
        CompanyWorkDate := WorkDate();
        Filter := CALTestLine.GetView();
        WindowNoOfTestCodeunitTotal := CountTestCodeunitsToRun(CALTestLine);
        CALTestLine.SetRange("Line Type", CALTestLine."Line Type"::Codeunit);
        if CALTestLine.Find('-') then
            repeat
                if UpdateTCM() then
                    CodeCoverageMgt.Start(true);

                MinLineNo := CALTestLine."Line No.";
                MaxLineNo := CALTestLine.GetMaxCodeunitLineNo(WindowNoOfFunctionTotal);
                if CALTestLine.Run then
                    WindowNoOfTestCodeunit += 1;
                WindowNoOfFunction := 0;

                if CALTestMgt.ISPUBLISHMODE() then
                    CALTestLine.DeleteChildren();

                CODEUNIT.Run(CALTestLine."Test Codeunit");

                if UpdateTCM() then begin
                    CodeCoverageMgt.Stop();
                    CALTestMgt.ExtendTestCoverage(CALTestLine."Test Codeunit");
                end;
            until CALTestLine.Next() = 0;

        CloseWindow();
    end;

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        CALTestRunnerPublisher.SetSeed(1);
        ApplicationArea('');
        WorkDate := CompanyWorkDate;
        UpDateWindow(
          CALTestLine."Test Suite", CALTestLine.Name, CodeunitName, FunctionName,
          WindowTestSuccess, WindowTestFailure, WindowTestSkip,
          WindowNoOfTestCodeunitTotal, WindowNoOfFunctionTotal,
          WindowNoOfTestCodeunit, WindowNoOfFunction);

        InitCodeunitLine();

        if FunctionName = '' then begin
            CALTestLine.Result := CALTestLine.Result::" ";
            CALTestLine."Start Time" := CurrentDateTime;
            exit(true);
        end;

        if CALTestMgt.ISPUBLISHMODE() then
            AddTestMethod(FunctionName)
        else begin
            if not TryFindTestFunctionInGroup(FunctionName) then
                exit(false);

            InitTestFunctionLine();
            if not CALTestLineFunction.Run or not CALTestLine.Run then
                exit(false);

            UpDateWindow(
              CALTestLine."Test Suite", CALTestLine.Name, CodeunitName, FunctionName,
              WindowTestSuccess, WindowTestFailure, WindowTestSkip,
              WindowNoOfTestCodeunitTotal, WindowNoOfFunctionTotal,
              WindowNoOfTestCodeunit, WindowNoOfFunction + 1);
        end;

        if FunctionName = 'OnRun' then
            exit(true);
        exit(CALTestMgt.ISTESTMODE());
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        if (FunctionName <> '') and (FunctionName <> 'OnRun') then
            if IsSuccess then
                UpDateWindow(
                  WindowTestSuite, WindowTestGroup, WindowTestCodeunit, WindowTestFunction,
                  WindowTestSuccess + 1, WindowTestFailure, WindowTestSkip,
                  WindowNoOfTestCodeunitTotal, WindowNoOfFunctionTotal,
                  WindowNoOfTestCodeunit, WindowNoOfFunction)
            else
                UpDateWindow(
                  WindowTestSuite, WindowTestGroup, WindowTestCodeunit, WindowTestFunction,
                  WindowTestSuccess, WindowTestFailure + 1, WindowTestSkip,
                  WindowNoOfTestCodeunitTotal, WindowNoOfFunctionTotal,
                  WindowNoOfTestCodeunit, WindowNoOfFunction);

        UpdateCodeunitLine(IsSuccess);

        if FunctionName = '' then
            exit;

        UpdateTestFunctionLine(IsSuccess);

        Commit();
        ApplicationArea('');
        ClearLastError();
    end;

    procedure AddTestMethod(FunctionName: Text[128])
    begin
        CALTestLineFunction := CALTestLine;
        CALTestLineFunction."Line No." := MaxLineNo + 1;
        CALTestLineFunction."Line Type" := CALTestLineFunction."Line Type"::"Function";
        CALTestLineFunction.Validate("Function", FunctionName);
        CALTestLineFunction.Run := CALTestLine.Run;
        CALTestLineFunction."Start Time" := CurrentDateTime;
        CALTestLineFunction."Finish Time" := CurrentDateTime;
        CALTestLineFunction.Insert(true);
        MaxLineNo := MaxLineNo + 1;
    end;

    procedure InitCodeunitLine()
    begin
        if CALTestMgt.ISTESTMODE() and (CALTestLine.Result = CALTestLine.Result::" ") then
            CALTestLine.Result := CALTestLine.Result::Skipped;
        CALTestLine."Finish Time" := CurrentDateTime;
        CALTestLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure UpdateCodeunitLine(IsSuccess: Boolean)
    begin
        if CALTestMgt.ISPUBLISHMODE() and IsSuccess then
            CALTestLine.Result := CALTestLine.Result::" "
        else
            if CALTestLine.Result <> CALTestLine.Result::Failure then
                if IsSuccess then
                    CALTestLine.Result := CALTestLine.Result::Success
                else begin
                    CALTestLine."First Error" := CopyStr(GetLastErrorText, 1, MaxStrLen(CALTestLine."First Error"));
                    CALTestLine.Result := CALTestLine.Result::Failure
                end;
        CALTestLine."Finish Time" := CurrentDateTime;
        CALTestLine.Modify();
    end;

    procedure InitTestFunctionLine()
    begin
        CALTestLineFunction."Start Time" := CurrentDateTime;
        CALTestLineFunction."Finish Time" := CALTestLineFunction."Start Time";
        CALTestLineFunction.Result := CALTestLineFunction.Result::Skipped;
        CALTestLineFunction.Modify();
    end;

    [Scope('OnPrem')]
    procedure UpdateTestFunctionLine(IsSuccess: Boolean)
    var
        CALTestResult: Record "CAL Test Result";
    begin
        if IsSuccess then
            CALTestLineFunction.Result := CALTestLine.Result::Success
        else begin
            CALTestLineFunction."First Error" := CopyStr(GetLastErrorText, 1, MaxStrLen(CALTestLineFunction."First Error"));
            CALTestLineFunction.Result := CALTestLineFunction.Result::Failure
        end;
        CALTestLineFunction."Finish Time" := CurrentDateTime;
        CALTestLineFunction.Modify();

        CALTestResult.Add(CALTestLineFunction, TestRunNo);
    end;

    procedure TryFindTestFunctionInGroup(FunctionName: Text[128]): Boolean
    begin
        CALTestLineFunction.Reset();
        CALTestLineFunction.SetView(Filter);
        CALTestLineFunction.SetRange("Test Suite", CALTestLine."Test Suite");
        CALTestLineFunction.SetRange("Test Codeunit", CALTestLine."Test Codeunit");
        CALTestLineFunction.SetRange("Function", FunctionName);
        if CALTestLineFunction.Find('-') then
            repeat
                if CALTestLineFunction."Line No." in [MinLineNo .. MaxLineNo] then
                    exit(true);
            until CALTestLineFunction.Next() = 0;
        exit(false);
    end;

    procedure CountTestCodeunitsToRun(var CALTestLine: Record "CAL Test Line") NoOfTestCodeunits: Integer
    begin
        if not CALTestMgt.ISTESTMODE() then
            exit;

        CALTestLine.SetRange("Line Type", CALTestLine."Line Type"::Codeunit);
        CALTestLine.SetRange(Run, true);
        NoOfTestCodeunits := CALTestLine.Count;
    end;

    procedure UpdateTCM(): Boolean
    begin
        exit(CALTestMgt.ISTESTMODE() and CALTestSuite."Update Test Coverage Map");
    end;

    local procedure OpenWindow()
    begin
        if not CALTestMgt.ISTESTMODE() then
            exit;

        Window.Open(
          ExecutingTestsMsg +
          TestSuiteMsg +
          TestCodeunitMsg +
          TestFunctionMsg +
          NoOfResultsMsg +
          SuccessMsg +
          FailureMsg +
          SkipMsg);
        WindowIsOpen := true;
    end;

    local procedure UpDateWindow(NewWindowTestSuite: Code[10]; NewWindowTestGroup: Text; NewWindowTestCodeunit: Text; NewWindowTestFunction: Text; NewWindowTestSuccess: Integer; NewWindowTestFailure: Integer; NewWindowTestSkip: Integer; NewWindowNoOfTestCodeunitTotal: Integer; NewWindowNoOfFunctionTotal: Integer; NewWindowNoOfTestCodeunit: Integer; NewWindowNoOfFunction: Integer)
    begin
        if not CALTestMgt.ISTESTMODE() then
            exit;

        WindowTestSuite := NewWindowTestSuite;
        WindowTestGroup := NewWindowTestGroup;
        WindowTestCodeunit := NewWindowTestCodeunit;
        WindowTestFunction := NewWindowTestFunction;
        WindowTestSuccess := NewWindowTestSuccess;
        WindowTestFailure := NewWindowTestFailure;
        WindowTestSkip := NewWindowTestSkip;

        WindowNoOfTestCodeunitTotal := NewWindowNoOfTestCodeunitTotal;
        WindowNoOfFunctionTotal := NewWindowNoOfFunctionTotal;
        WindowNoOfTestCodeunit := NewWindowNoOfTestCodeunit;
        WindowNoOfFunction := NewWindowNoOfFunction;

        if IsTimeForUpdate() then begin
            if not WindowIsOpen then
                OpenWindow();
            Window.Update(1, WindowTestSuite);
            Window.Update(2, WindowTestCodeunit);
            Window.Update(4, WindowTestFunction);
            Window.Update(6, WindowTestSuccess);
            Window.Update(7, WindowTestFailure);
            Window.Update(8, WindowTestSkip);

            if NewWindowNoOfTestCodeunitTotal <> 0 then
                Window.Update(3, Round(NewWindowNoOfTestCodeunit / NewWindowNoOfTestCodeunitTotal * 10000, 1));
            if NewWindowNoOfFunctionTotal <> 0 then
                Window.Update(5, Round(NewWindowNoOfFunction / NewWindowNoOfFunctionTotal * 10000, 1));
        end;
    end;

    local procedure CloseWindow()
    begin
        if not CALTestMgt.ISTESTMODE() then
            exit;

        if WindowIsOpen then begin
            Window.Close();
            WindowIsOpen := false;
        end;
    end;

    local procedure IsTimeForUpdate(): Boolean
    begin
        if true in [WindowUpdateDateTime = 0DT, CurrentDateTime - WindowUpdateDateTime >= 1000] then begin
            WindowUpdateDateTime := CurrentDateTime;
            exit(true);
        end;
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunTests(var CALTestLine: Record "CAL Test Line")
    begin
    end;
}

