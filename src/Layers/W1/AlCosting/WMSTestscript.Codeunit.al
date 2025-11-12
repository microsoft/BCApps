codeunit 103302 "WMS Testscript"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        if not KeepUseCases then begin
            TestSetupMgmt.CreateUseCases();
            TestSetupMgmt.CreateTestCases();
            TestCase.Reset();
            TestSetupMgmt.CreateIterations(TestCase, true, false);
        end;

        WMSTestscriptMgmt.DeleteTestscriptResult();
        Commit();

        if not QASetup.Get() then
            QASetup.Init();
        if QASetup."Run Test Log" then
            CoverageLine.DeleteAll();

        Offset := 103200;
        if LastIteration <> '' then begin
            TestLevel := TestLevel::All;
            CallTestScript(Offset, LastUseCaseNo, true);
        end else
            while not ContinueProcessing do begin
                i := 0;
                Clear(Selection);
                Clear(SelectionText);

                UseCase.Reset();
                if UseCase.Find('-') then
                    repeat
                        TestCase.Reset();
                        TestCase.SetRange("Project Code", UseCase."Project Code");
                        TestCase.SetRange("Use Case No.", UseCase."Use Case No.");
                        TestCase.SetRange("Testscript Completed", true);
                        if TestCase.FindFirst() then begin
                            i := UseCase."Use Case No.";
                            if i <= ArrayLen(SelectionText) then
                                SelectionText[i] := Format(i) + '. ' + UseCase.Description;
                        end;
                    until UseCase.Next() = 0;

                SelectionForm.SetSelection(SelectionText, false, 0, 'Select Use Case');
                SelectionForm.LookupMode := true;
                if SelectionForm.RunModal() <> ACTION::LookupOK then
                    Error('Cancelled.');
                SelectionForm.GetSelection(TestLevel, Selection, ShowAlsoPassTests);
                Clear(SelectionForm);

                i := 1;
                ContinueProcessing := true;
                while (i <= ArrayLen(SelectionText)) and ContinueProcessing do begin
                    if SelectionText[i] <> '' then
                        ContinueProcessing := CallTestScript(Offset, i, Selection[i]);
                    i := i + 1;
                end;
            end;

        Commit();
        if ShowScriptResults then begin
            if QASetup."Use Hardcoded Reference" then
                WMSTestscriptMgmt.ShowTestscriptResult()
            else begin
                WMSTestscriptMgmt.ShowTestscriptResult();
                WMSTestscriptMgmt.SetNumbers(NoOfRecords, NoOfFields);
                WMSTestscriptMgmt.WriteQuantities();
            end;
            Commit();

            if QASetup."Run Test Log" then
                TestLog.SaveAsPdf(WMSTestscriptMgmt.GetTestResultsPath() + 'TestLog.pdf');
        end;
    end;

    var
        UseCase: Record "Whse. Use Case";
        TestCase: Record "Whse. Test Case";
        TestscriptResult: Record "Whse. Testscript Result";
        QASetup: Record "Whse. QA Setup";
        CoverageLine: Record "Code Coverage";
        SelectionForm: Page "Whse. Test Selection";
        TestLog: Report "Whse. Test Log";
        WMSTestscriptMgmt: Codeunit "WMS TestscriptManagement";
        TestSetupMgmt: Codeunit "WMS TestSetupManagement";
        SelectionText: array[50] of Text[100];
        LastIteration: Text[30];
        LastProjectCode: Code[10];
        TestLevel: Option All,Selected;
        i: Integer;
        LastUseCaseNo: Integer;
        LastTestCaseNo: Integer;
        Offset: Integer;
        NoOfRecords: array[20] of Integer;
        NoOfFields: array[20] of Integer;
        ObjectNo: Integer;
        Selection: array[50] of Boolean;
        KeepUseCases: Boolean;
        ShowAlsoPassTests: Boolean;
        ContinueProcessing: Boolean;
        ShowScriptResults: Boolean;

    [Scope('OnPrem')]
    procedure CallTestScript(Offset: Integer; UseCaseNo: Integer; TestUseCase: Boolean): Boolean
    var
        TestUseCase2: Codeunit "WMS Test Use Case 2";
        TestUseCase3: Codeunit "WMS Test Use Case 3";
        TestUseCase4: Codeunit "WMS Test Use Case 4";
        TestUseCase5: Codeunit "WMS Test Use Case 5";
        TestUseCase6: Codeunit "WMS Test Use Case 6";
        TestUseCase7: Codeunit "WMS Test Use Case 7";
        TestUseCase8: Codeunit "WMS Test Use Case 8";
        TestUseCase9: Codeunit "WMS Test Use Case 9";
        TestUseCase10: Codeunit "WMS Test Use Case 10";
        TestUseCase11: Codeunit "WMS Test Use Case 11";
        TestUseCase15: Codeunit "WMS Test Use Case 15";
        TestUseCase16: Codeunit "WMS Test Use Case 16";
        TestUseCase17: Codeunit "WMS Test Use Case 17";
        TestUseCase18: Codeunit "WMS Test Use Case 18";
        TestUseCase19: Codeunit "WMS Test Use Case 19";
        TestUseCase20: Codeunit "WMS Test Use Case 20";
        TestUseCase21: Codeunit "WMS Test Use Case 21";
        TestUseCase22: Codeunit "WMS Test Use Case 22";
        TestUseCase23: Codeunit "WMS Test Use Case 23";
        TestUseCase25: Codeunit "WMS Test Use Case 25";
        TestUseCase26: Codeunit "WMS Test Use Case 26";
        TestUseCase27: Codeunit "WMS Test Use Case 27";
        TestUseCase28: Codeunit "WMS Test Use Case 28";
    begin
        if TestLevel = TestLevel::Selected then
            if not TestUseCase then
                exit(true);

        ObjectNo := Offset + UseCaseNo;

        case UseCaseNo of
            2:
                begin
                    TestUseCase2.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase2.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase2.GetNumbers(NoOfRecords, NoOfFields);
                end;
            3:
                begin
                    TestUseCase3.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase3.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase3.GetNumbers(NoOfRecords, NoOfFields);
                end;
            4:
                begin
                    TestUseCase4.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase4.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase4.GetNumbers(NoOfRecords, NoOfFields);
                end;
            5:
                begin
                    TestUseCase5.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase5.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase5.GetNumbers(NoOfRecords, NoOfFields);
                end;
            6:
                begin
                    TestUseCase6.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase6.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase6.GetNumbers(NoOfRecords, NoOfFields);
                end;
            7:
                begin
                    TestUseCase7.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase7.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase7.GetNumbers(NoOfRecords, NoOfFields);
                end;
            8:
                begin
                    TestUseCase8.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase8.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase8.GetNumbers(NoOfRecords, NoOfFields);
                end;
            9:
                begin
                    TestUseCase9.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase9.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase9.GetNumbers(NoOfRecords, NoOfFields);
                end;
            10:
                begin
                    TestUseCase10.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase10.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase10.GetNumbers(NoOfRecords, NoOfFields);
                end;
            11:
                begin
                    TestUseCase11.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase11.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase11.GetNumbers(NoOfRecords, NoOfFields);
                end;
            15:
                begin
                    TestUseCase15.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase15.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase15.GetNumbers(NoOfRecords, NoOfFields);
                end;
            16:
                begin
                    TestUseCase16.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase16.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase16.GetNumbers(NoOfRecords, NoOfFields);
                end;
            17:
                begin
                    TestUseCase17.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase17.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase17.GetNumbers(NoOfRecords, NoOfFields);
                end;
            18:
                begin
                    TestUseCase18.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase18.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase18.GetNumbers(NoOfRecords, NoOfFields);
                end;
            19:
                begin
                    TestUseCase19.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase19.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase19.GetNumbers(NoOfRecords, NoOfFields);
                end;
            20:
                begin
                    TestUseCase20.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase20.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase20.GetNumbers(NoOfRecords, NoOfFields);
                end;
            21:
                begin
                    TestUseCase21.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase21.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase21.GetNumbers(NoOfRecords, NoOfFields);
                end;
            22:
                begin
                    TestUseCase22.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase22.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase22.GetNumbers(NoOfRecords, NoOfFields);
                end;
            23:
                begin
                    TestUseCase23.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase23.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase23.GetNumbers(NoOfRecords, NoOfFields);
                end;
            25:
                begin
                    TestUseCase25.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase25.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase25.GetNumbers(NoOfRecords, NoOfFields);
                end;
            26:
                begin
                    TestUseCase26.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase26.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase26.GetNumbers(NoOfRecords, NoOfFields);
                end;
            27:
                begin
                    TestUseCase27.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase27.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase27.GetNumbers(NoOfRecords, NoOfFields);
                end;
            28:
                begin
                    TestUseCase28.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase28.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase28.GetNumbers(NoOfRecords, NoOfFields);
                end;
        end;

        if ContinueProcessing and ShowAlsoPassTests then begin
            WMSTestscriptMgmt.InitializeOutput(ObjectNo, '');
            TestscriptResult.SetRange("Codeunit ID", ObjectNo);
            TestscriptResult.SetRange("Is Equal", false);
            if TestscriptResult.IsEmpty() then
                WMSTestscriptMgmt.InsertTestResult(
                  'No errors found.', '', '', false, UseCaseNo, 0, 0, 0, 0);
            TestscriptResult.SetRange("Codeunit ID");
            TestscriptResult.SetRange("Is Equal");
        end;

        exit(ContinueProcessing);
    end;

    [Scope('OnPrem')]
    procedure SetLastIteration(NewLastUseCaseNo: Integer; NewLastTestCaseNo: Integer; NewLastIterationNo: Integer; NewLastStepNo: Integer; NewProjectCode: Code[10])
    begin
        LastUseCaseNo := NewLastUseCaseNo;
        LastTestCaseNo := NewLastTestCaseNo;
        LastProjectCode := NewProjectCode;
        LastIteration := Format(LastUseCaseNo) + '-' + Format(LastTestCaseNo) + '-' +
          Format(NewLastIterationNo) + '-' + Format(NewLastStepNo);
    end;

    [Scope('OnPrem')]
    procedure SetKeepUseCases(NewKeepUseCases: Boolean)
    begin
        KeepUseCases := NewKeepUseCases;
    end;

    [Scope('OnPrem')]
    procedure SetShowTestResults(NewShowScriptResults: Boolean)
    begin
        ShowScriptResults := NewShowScriptResults;
    end;
}

