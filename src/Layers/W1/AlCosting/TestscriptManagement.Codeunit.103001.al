#pragma warning disable AA0215
codeunit 103001 TestscriptManagement
#pragma warning restore AA0215
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        RunCodeunits('103509..103542', true);
    end;

    var
        TestscriptSetup: Record "Testscript Setup";
        TestscriptResult: Record "Testscript Result";
        CodeunitID: Integer;
        OutputFilePath: Text[1000];

    [Scope('OnPrem')]
    procedure InitializeOutput(NewCodeunitID: Integer)
    begin
        if TestscriptSetup.Get() then;
        if TestscriptSetup."Postpone Show Test Result" then begin
            TestscriptResult.LockTable();
            if TestscriptResult.Find('+') then;
        end else
            TestscriptResult.DeleteAll();

        CodeunitID := NewCodeunitID;
    end;

    [Scope('OnPrem')]
    procedure ShowTestscriptResult()
    begin
        if TestscriptSetup."Postpone Show Test Result" then
            exit;
        if OutputFilePath > '' then
            WriteTestscriptResult();
        TestscriptResult.SetRange("Is Equal", false);

        if not TestscriptResult.Find('-') then
            Message('No errors found.');
        PAGE.Run(0, TestscriptResult);
    end;

    [Scope('OnPrem')]
    procedure SetPathToWrite(OutputPath: Text[1000])
    begin
        OutputFilePath := OutputPath;
    end;

    [Scope('OnPrem')]
    procedure WriteTestscriptResult()
    var
        WriteTextFile: File;
        OutStreamText: OutStream;
    begin
        WriteTextFile.Create(OutputFilePath);
        WriteTextFile.TextMode := true;
        WriteTextFile.CreateOutStream(OutStreamText);
        TestscriptResult.SetRange("Is Equal", false);
        if TestscriptResult.Find('-') then
            repeat
                OutStreamText.WriteText(
                  StrSubstNo('Entry = %1 Name = %2 Value = %3 Expected Value = %4 Codeunit = %5',
                    TestscriptResult."Entry No.",
                    TestscriptResult.Name,
                    TestscriptResult.Value,
                    TestscriptResult."Expected Value",
                    TestscriptResult."Codeunit ID"));
                OutStreamText.WriteText();
            until TestscriptResult.Next() = 0;
        WriteTextFile.Close();
    end;

    [Scope('OnPrem')]
    procedure TestTextValue(Name: Text[250]; Value: Text[250]; ExpectedValue: Text[250])
    begin
        InsertTestResult(Name, Value, ExpectedValue, Value = ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure TestNumberValue(Name: Text[250]; Value: Decimal; ExpectedValue: Decimal)
    begin
        InsertTestResult(Name, Format(Value), Format(ExpectedValue), Value = ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure TestBooleanValue(Name: Text[250]; Value: Boolean; ExpectedValue: Boolean)
    begin
        InsertTestResult(Name, Format(Value), Format(ExpectedValue), Value = ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure TestDateValue(Name: Text[250]; Value: Date; ExpectedValue: Date)
    begin
        InsertTestResult(Name, Format(Value), Format(ExpectedValue), Value = ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure TestTimeValue(Name: Text[250]; Value: Time; ExpectedValue: Time)
    begin
        InsertTestResult(Name, Format(Value), Format(ExpectedValue), Value = ExpectedValue);
    end;

    [Scope('OnPrem')]
    procedure InsertTestResult(Name: Text[250]; Value: Text[250]; ExpectedValue: Text[250]; IsEqual: Boolean)
    var
        TestscriptResult2: Record "Testscript Result";
        LastEntryNo: Integer;
    begin
        if IsEqual then
            exit;

        LastEntryNo := 0;
        TestscriptResult2.Reset();

        if TestscriptResult2.FindLast() then
            LastEntryNo := TestscriptResult2."Entry No.";

        TestscriptResult."Entry No." := LastEntryNo + 1;
        TestscriptResult.Name := Name;
        TestscriptResult.Value := Value;
        TestscriptResult."Expected Value" := ExpectedValue;
        TestscriptResult."Is Equal" := IsEqual;
        TestscriptResult."Codeunit ID" := CodeunitID;
        TestscriptResult.Insert();
    end;

    [Scope('OnPrem')]
    procedure RunCodeunits(CodeunitIDFilter: Text[250]; ShowScriptResults: Boolean)
    var
        AllObj: Record AllObj;
        OK: Boolean;
    begin
        SetPostponeShowTestResult(true);

        TestscriptResult.DeleteAll();

        AllObj.SetRange("Object Type", AllObj."Object Type"::Codeunit);
        AllObj.SetFilter("Object ID", CodeunitIDFilter);
        if AllObj.Find('-') then
            repeat
                Commit();
                OK := CODEUNIT.Run(AllObj."Object ID");
                Commit();
                InitializeOutput(AllObj."Object ID");
                TestBooleanValue(
                  StrSubstNo('%1 %2 %3 has been executed.', AllObj."Object Type", AllObj."Object ID", AllObj."Object Name"), OK, true);
            until AllObj.Next() = 0;
        SetPostponeShowTestResult(false);

        if ShowScriptResults then
            ShowTestscriptResult();
    end;

    local procedure SetPostponeShowTestResult(PostponeShowTestResult: Boolean)
    begin
        if not TestscriptSetup.Get() then
            TestscriptSetup.Insert();
        TestscriptSetup."Postpone Show Test Result" := PostponeShowTestResult;
        TestscriptSetup.Modify();
    end;
}

