codeunit 103491 Testscript
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

        TestscriptMgmt.DeleteTestscriptResult();
        Commit();

        if not QASetup.Get() then
            QASetup.Init();
        if QASetup."Run Test Log" then
            CoverageLine.DeleteAll();

        Offset := 103001;
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
                        TestCase.SetRange("Use Case No.", UseCase."Use Case No.");
                        TestCase.SetRange("Testscript Completed", true);
                        if not TestCase.IsEmpty() then begin
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
        if ShowTestResults then begin
            TestscriptMgmt.ShowTestscriptResult();
            TestscriptMgmt.SetNumbers(NoOfRecords, NoOfFields);
            TestscriptMgmt.WriteQuantities();
            Commit();

            if QASetup."Run Test Log" then
                TestLog.SaveAsPdf(TestscriptMgmt.GetTestResultsPath() + 'TestLog.pdf');
        end;
    end;

    var
        UseCase: Record "Use Case";
        TestCase: Record "Test Case";
        QASetup: Record "QA Setup";
        CoverageLine: Record "Code Coverage";
        SelectionForm: Page "Test Selection";
        TestLog: Report "Test Log";
        TestscriptMgmt: Codeunit _TestscriptManagement;
        TestSetupMgmt: Codeunit TestSetupManagement;
        ObjectNo: Integer;
        Selection: array[50] of Boolean;
        SelectionText: array[50] of Text[100];
        i: Integer;
        ShowAlsoPassTests: Boolean;
        TestLevel: Option All,Selected;
        ContinueProcessing: Boolean;
        LastUseCaseNo: Integer;
        LastTestCaseNo: Integer;
        LastIteration: Text[30];
        KeepUseCases: Boolean;
        Offset: Integer;
        NoOfRecords: array[20] of Integer;
        NoOfFields: array[20] of Integer;
        ShowTestResults: Boolean;

    [Scope('OnPrem')]
    procedure CallTestScript(Offset: Integer; UseCaseNo: Integer; TestUseCase: Boolean): Boolean
    var
        TestUseCase1: Codeunit "Test Use Case 1";
        TestUseCase2: Codeunit "Test Use Case 2";
        TestUseCase3: Codeunit "Test Use Case 3";
        TestUseCase4: Codeunit "Test Use Case 4";
        TestUseCase5: Codeunit "Test Use Case 5";
        TestUseCase6: Codeunit "Test Use Case 6";
        TestUseCase7: Codeunit "Test Use Case 7";
        TestUseCase13: Codeunit "Test Use Case 13";
        TestUseCase14: Codeunit "Test Use Case 14";
        TestUseCase15: Codeunit "Test Use Case 15";
        TestUseCase16: Codeunit "Test Use Case 16";
        TestUseCase18: Codeunit "Test Use Case 18";
        TestUseCase19: Codeunit "Test Use Case 19";
    begin
        if TestLevel = TestLevel::Selected then
            if not TestUseCase then
                exit(true);

        ObjectNo := Offset + UseCaseNo;

        case UseCaseNo of
            1:
                begin
                    TestUseCase1.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase1.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase1.GetNumbers(NoOfRecords, NoOfFields);
                end;
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
            13:
                begin
                    TestUseCase13.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase13.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase13.GetNumbers(NoOfRecords, NoOfFields);
                end;
            14:
                begin
                    TestUseCase14.SetNumbers(NoOfRecords, NoOfFields);
                    ContinueProcessing :=
                      TestUseCase14.Test(ObjectNo, UseCaseNo, TestLevel, LastIteration, LastTestCaseNo);
                    TestUseCase14.GetNumbers(NoOfRecords, NoOfFields);
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
        end;

        exit(ContinueProcessing);
    end;

    [Scope('OnPrem')]
    procedure SetLastIteration(NewLastUseCaseNo: Integer; NewLastTestCaseNo: Integer; NewLastIterationNo: Integer; NewLastStepNo: Integer)
    begin
        LastUseCaseNo := NewLastUseCaseNo;
        LastTestCaseNo := NewLastTestCaseNo;
        LastIteration := Format(LastUseCaseNo) + '-' + Format(LastTestCaseNo) + '-' +
          Format(NewLastIterationNo) + '-' + Format(NewLastStepNo);
    end;

    [Scope('OnPrem')]
    procedure SetKeepUseCases(NewKeepUseCases: Boolean)
    begin
        KeepUseCases := NewKeepUseCases;
    end;

    [Scope('OnPrem')]
    procedure SetShowScriptResults(NewShowScriptResults: Boolean)
    begin
        ShowTestResults := NewShowScriptResults;
    end;
}

