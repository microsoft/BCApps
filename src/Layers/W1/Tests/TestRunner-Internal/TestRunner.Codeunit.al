codeunit 130020 "Test Runner"
{
    Subtype = TestRunner;
    TableNo = "Test Line";
    TestIsolation = Codeunit;

    trigger OnRun()
    begin
        TestLine.Copy(Rec);

        if TestSuite.Get("Test Suite") and TestSuite."Re-run Failing Codeunits" then begin
            BackupMgt.SetEnabled(true);
            BackupMgt.DefaultFixture();
            BackupMgt.SetEnabled(false);
        end;

        RunTests();
    end;

    var
        TestSuite: Record "Test Suite";
        TestLine: Record "Test Line";
        TestLineFunction: Record "Test Line";
        TestMgt: Codeunit "Test Management";
        BackupMgt: Codeunit "Backup Management";
        LibraryRandom: Codeunit "Library - Random";
        PermissionTestCatalog: Codeunit "Permission Test Catalog";
        Window: Dialog;
        MaxLineNo: Integer;
        MinLineNo: Integer;
        "Filter": Text;
        Text000: Label 'Executing Tests...\';
        Text001: Label 'Test Suite    #1###################\';
        Text003: Label 'Test Codeunit #2################### @3@@@@@@@@@@@@@\';
        Text004: Label 'Test Function #4################### @5@@@@@@@@@@@@@\';
        Text005: Label 'No. of Results with:\';
        WindowUpdateDateTime: DateTime;
        WindowIsOpen: Boolean;
        WindowTestSuite: Code[10];
        WindowTestGroup: Text[128];
        WindowTestCodeunit: Text[30];
        WindowTestFunction: Text[128];
        WindowTestSuccess: Integer;
        WindowTestFailure: Integer;
        WindowTestSkip: Integer;
        Text006: Label '    Success   #6######\';
        Text007: Label '    Failure   #7######\';
        Text008: Label '    Skip      #8######\';
        WindowNoOfTestCodeunitTotal: Integer;
        WindowNoOfFunctionTotal: Integer;
        WindowNoOfTestCodeunit: Integer;
        WindowNoOfFunction: Integer;

    local procedure RunTests()
    var
        ChangelistCode: Record "Changelist Code";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        TestProxy: Codeunit "Test Proxy";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";
    begin
        OpenWindow();
        TestLine.ModifyAll(Result, TestLine.Result::" ");
        TestLine.ModifyAll("First Error", '');
        Commit();
        Filter := TestLine.GetView();
        WindowNoOfTestCodeunitTotal := CountTestCodeunitsToRun(TestLine);
        if not (ChangelistCode.IsEmpty() or UpdateTCM()) then
            CodeCoverageMgt.Start(true);

        TestProxy.Initialize();

        if TestLine.Find('-') then
            repeat
                if TestLine."Line Type" = TestLine."Line Type"::Codeunit then begin
                    if UpdateTCM() then
                        CodeCoverageMgt.Start(true);

                    MinLineNo := TestLine."Line No.";
                    MaxLineNo := TestLine.GetMaxCodeunitLineNo(WindowNoOfFunctionTotal);
                    if TestLine.Run then
                        WindowNoOfTestCodeunit += 1;
                    WindowNoOfFunction := 0;

                    if TestMgt.ISPUBLISHMODE() then
                        TestLine.DeleteChildren();

                    AzureKeyVaultTestLibrary.ClearSecrets();
                    // Cleanup key vault cache
                    if not Codeunit.Run(TestLine."Test Codeunit") and
                       TestMgt.ISTESTMODE() and
                       TestSuite."Re-run Failing Codeunits"
                    then begin
                        BackupMgt.SetEnabled(true);
                        Codeunit.Run(TestLine."Test Codeunit");
                        BackupMgt.SetEnabled(false);
                    end;

                    if UpdateTCM() then begin
                        CodeCoverageMgt.Stop();
                        TestMgt.ExtendTestCoverage(TestLine."Test Codeunit");
                    end;
                end;
            until TestLine.Next() = 0;

        if not (ChangelistCode.IsEmpty() or UpdateTCM()) then begin
            CodeCoverageMgt.Stop();
            Codeunit.Run(Codeunit::"Calculate Changelist Coverage");
        end;

        CloseWindow();
    end;

    [Scope('OnPrem')]
    procedure RunTestsOnLines(var TestLineNew: Record "Test Line")
    begin
        TestLine.Copy(TestLineNew);

        RunTests();

        TestLineNew.Copy(TestLine);
    end;

    procedure HandleOnOnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    var
        TestProxy: Codeunit "Test Proxy";
        SnapTestRunner: Codeunit "Snap Test Runner";
    begin
        UpDateWindow(
          TestLine."Test Suite", TestLine.Name, CodeunitName, FunctionName,
          WindowTestSuccess, WindowTestFailure, WindowTestSkip,
          WindowNoOfTestCodeunitTotal, WindowNoOfFunctionTotal,
          WindowNoOfTestCodeunit, WindowNoOfFunction);

        UpdateCodeunit(false, false);

        if FunctionName = '' then begin
            TestLine.Result := TestLine.Result::" ";
            TestLine."Start Time" := CurrentDateTime;
            exit(true);
        end;

        if TestMgt.ISPUBLISHMODE() then
            AddTestMethod(FunctionName)
        else begin
            if not TryFindTestFunctionInGroup(FunctionName) then
                exit(FunctionName = 'OnRun');

            LibraryRandom.SetSeed(1);
            ApplicationArea('');
            SnapTestRunner.BindStopSystemTableChanges();

            UpdateTestFunction(false, false);
            if not TestLineFunction.Run or not TestLine.Run then
                exit(false);

            TestProxy.InvokeOnBeforeTestFunctionRun(CodeunitID, CodeunitName, FunctionName, FunctionTestPermissions);

            Clear(PermissionTestCatalog);
            // todo: move to subscribers
            if FunctionName <> 'OnRun' then
                PermissionTestCatalog.InitializePermissionSetForTest(FunctionTestPermissions);

            UpDateWindow(
              TestLine."Test Suite", TestLine.Name, CodeunitName, FunctionName,
              WindowTestSuccess, WindowTestFailure, WindowTestSkip,
              WindowNoOfTestCodeunitTotal, WindowNoOfFunctionTotal,
              WindowNoOfTestCodeunit, WindowNoOfFunction + 1);
        end;

        if FunctionName = 'OnRun' then
            exit(true);

        exit(TestMgt.ISTESTMODE());
    end;

    trigger OnBeforeTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions): Boolean
    begin
        exit(HandleOnOnBeforeTestRun(CodeunitID, CodeunitName, FunctionName, FunctionTestPermissions));
    end;

    procedure HandleOnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    var
        TestProxy: Codeunit "Test Proxy";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        PermissionErrors: Text;
    begin
        if (FunctionName <> '') and (FunctionName <> 'OnRun') then begin
            TestProxy.InvokeOnAfterTestFunctionRun(CodeunitID, CodeunitName, FunctionName, FunctionTestPermissions, IsSuccess);

            // todo: move to subscribers
            PermissionErrors := PermissionTestCatalog.GetPermissionErrors(FunctionTestPermissions);
            if IsSuccess and (PermissionErrors <> '') then begin // Only show permission errors once everything else succeeds
                asserterror Error(PermissionErrors);
                IsSuccess := false;
            end;

            LibraryNotificationMgt.ClearTemporaryNotificationContext();
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
        end;
        TestLine.Find();
        UpdateCodeunit(true, IsSuccess);

        if FunctionName = '' then
            exit;

        UpdateTestFunction(true, IsSuccess);

        Commit();
        ApplicationArea('');
        ClearLastError();
    end;

    trigger OnAfterTestRun(CodeunitID: Integer; CodeunitName: Text; FunctionName: Text; FunctionTestPermissions: TestPermissions; IsSuccess: Boolean)
    begin
        HandleOnAfterTestRun(CodeunitID, CodeunitName, FunctionName, FunctionTestPermissions, IsSuccess);
    end;

    [Scope('OnPrem')]
    procedure AddTestMethod(FunctionName: Text[128]): Boolean
    var
        NoOfSteps: Integer;
    begin
        TestLineFunction := TestLine;
        TestLineFunction."Line No." := MaxLineNo + 1;
        TestLineFunction."Line Type" := TestLineFunction."Line Type"::"Function";
        TestLineFunction.Validate("Function", FunctionName);
        TestLineFunction.Run := TestLine.Run;
        TestLineFunction."Start Time" := CurrentDateTime;
        TestLineFunction."Finish Time" := CurrentDateTime;
        if TestSuite."Show Test Details" then
            NoOfSteps := TestLineFunction.AddTestSteps();
        if NoOfSteps >= 0 then
            TestLineFunction.Insert(true);
        MaxLineNo := MaxLineNo + NoOfSteps + 1;
        exit(NoOfSteps >= 0);
    end;

    [Scope('OnPrem')]
    procedure UpdateCodeunit(IsOnAfterTestRun: Boolean; IsSuccessOnAfterTestRun: Boolean)
    begin
        if not IsOnAfterTestRun then begin
            if TestMgt.ISTESTMODE() and (TestLine.Result = TestLine.Result::" ") then
                TestLine.Result := TestLine.Result::Skipped;
        end else
            if TestMgt.ISPUBLISHMODE() and IsSuccessOnAfterTestRun then
                TestLine.Result := TestLine.Result::" "
            else
                if TestLine.Result <> TestLine.Result::Failure then
                    if not IsSuccessOnAfterTestRun then begin
                        TestLine."First Error" := CopyStr(GetLastErrorText, 1, MaxStrLen(TestLine."First Error"));
                        TestLine.Result := TestLine.Result::Failure
                    end else
                        TestLine.Result := TestLine.Result::Success;
        TestLine."Finish Time" := CurrentDateTime;
        TestLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure UpdateTestFunction(IsOnAfterTestRun: Boolean; IsSuccessOnAfterTestRun: Boolean)
    begin
        if not TestLineFunction.Find() then
            exit;

        if not IsOnAfterTestRun then begin
            TestLineFunction."Start Time" := CurrentDateTime;
            TestLineFunction.Result := TestLineFunction.Result::Skipped;
        end else
            if not IsSuccessOnAfterTestRun then begin
                TestLineFunction."First Error" := CopyStr(GetLastErrorText, 1, MaxStrLen(TestLineFunction."First Error"));
                TestLineFunction.Result := TestLineFunction.Result::Failure
            end else
                TestLineFunction.Result := TestLine.Result::Success;

        TestLineFunction."Finish Time" := CurrentDateTime;
        TestLineFunction.Modify();
    end;

    [Scope('OnPrem')]
    procedure TryFindTestFunctionInGroup(FunctionName: Text[128]): Boolean
    begin
        TestLineFunction.Reset();
        TestLineFunction.SetView(Filter);
        TestLineFunction.SetRange("Test Suite", TestLine."Test Suite");
        TestLineFunction.SetRange("Test Codeunit", TestLine."Test Codeunit");
        TestLineFunction.SetRange("Function", FunctionName);
        if TestLineFunction.Find('-') then
            repeat
                if TestLineFunction."Line No." in [MinLineNo .. MaxLineNo] then
                    exit(true);
            until TestLineFunction.Next() = 0;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure CountTestCodeunitsToRun(var TestLine: Record "Test Line") NoOfTestCodeunits: Integer
    begin
        if not TestMgt.ISTESTMODE() then
            exit;

        if TestLine.Find('-') then
            repeat
                if (TestLine."Line Type" = TestLine."Line Type"::Codeunit) and TestLine.Run then
                    NoOfTestCodeunits += 1;
            until TestLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure UpdateTCM(): Boolean
    var
        TestCoverageMap: Record "Test Coverage Map";
    begin
        exit(TestMgt.ISTESTMODE() and not TestCoverageMap.IsEmpty())
    end;

    local procedure OpenWindow()
    begin
        if not TestMgt.ISTESTMODE() then
            exit;

        Window.Open(
          Text000 +
          Text001 +
          Text003 +
          Text004 +
          Text005 +
          Text006 +
          Text007 +
          Text008);
        WindowIsOpen := true;
    end;

    local procedure UpDateWindow(NewWindowTestSuite: Code[10]; NewWindowTestGroup: Text[128]; NewWindowTestCodeunit: Text[30]; NewWindowTestFunction: Text[128]; NewWindowTestSuccess: Integer; NewWindowTestFailure: Integer; NewWindowTestSkip: Integer; NewWindowNoOfTestCodeunitTotal: Integer; NewWindowNoOfFunctionTotal: Integer; NewWindowNoOfTestCodeunit: Integer; NewWindowNoOfFunction: Integer)
    begin
        if not TestMgt.ISTESTMODE() then
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
        if not TestMgt.ISTESTMODE() then
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
}

