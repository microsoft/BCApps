codeunit 103306 "BW Testscript"
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

        Offset := 103350;
        if LastIteration <> '' then begin
            TestLevel := TestLevel::All;
            CallTestScript(Offset, LastUseCaseNo, true);
        end else
            while not ContinueProcessing do begin
                i := 0;
                Clear(Selection);
                Clear(SelectionText);

                UseCase.Reset();
                UseCase.SetRange("Project Code", 'BW');
                if UseCase.Find('-') then
                    repeat
                        TestCase.Reset();
                        TestCase.SetRange("Project Code", UseCase."Project Code");
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
        if ShowScriptResult then begin
            if QASetup."Use Hardcoded Reference" then
                TestscriptMgmt.ShowTestscriptResult()
            else begin
                TestscriptMgmt.ShowTestscriptResult();
                TestscriptMgmt.SetNumbers(NoOfRecords, NoOfFields);
                TestscriptMgmt.WriteQuantities();
            end;
            Commit();

            if QASetup."Run Test Log" then
                TestLog.SaveAsPdf(TestscriptMgmt.GetTestResultsPath() + 'TestLog.pdf');
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
        TestscriptMgmt: Codeunit "BW TestscriptManagement";
        TestSetupMgmt: Codeunit "BW TestSetupManagement";
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
        ShowScriptResult: Boolean;

    [Scope('OnPrem')]
    procedure CallTestScript(Offset: Integer; UseCaseNo: Integer; TestUseCase: Boolean): Boolean
    var
        TestUseCase1: Codeunit "BW Test Use Case 1";
        TestUseCase2: Codeunit "BW Test Use Case 2";
        TestUseCase3: Codeunit "BW Test Use Case 3";
        TestUseCase6: Codeunit "BW Test Use Case 6";
        TestUseCase5: Codeunit "BW Test Use Case 5";
        TestUseCase7: Codeunit "BW Test Use Case 7";
        TestUseCase8: Codeunit "BW Test Use Case 8";
        TestUseCase9: Codeunit "BW Test Use Case 9";
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
        end;

        if ContinueProcessing and ShowAlsoPassTests then begin
            TestscriptMgmt.InitializeOutput(ObjectNo, '');
            TestscriptResult.SetRange("Codeunit ID", ObjectNo);
            TestscriptResult.SetRange("Is Equal", false);
            if TestscriptResult.IsEmpty() then
                TestscriptMgmt.InsertTestResult(
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
    procedure SetShowScriptResult(NewShowScriptResult: Boolean)
    begin
        ShowScriptResult := NewShowScriptResult
    end;
}

