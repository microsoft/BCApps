codeunit 130461 "Test Output"
{
    SingleInstance = true;
    Permissions = tabledata "Test Output" = RMID;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    local procedure UpdateTestDataBeforeTestMethodRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var CurrentTestMethodLine: Record "Test Method Line")
    var
        TestInput: Codeunit "Test Input";
    begin
        Clear(CurrentTestJson);
        InitializeBeforeTestRun(CodeunitID, FunctionName, TestInput.GetTestDataDescription());
    end;

    local procedure InitializeBeforeTestRun(CodeunitID: Integer; TestName: Text; Description: Text)
    var
        TestJsonCodeunit: Codeunit "Test Output Json";
        CurrentTestOutputJson: Codeunit "Test Output Json";
    begin
        if not TestJsonInitialized then begin
            GlobalTestJson := TestJsonCodeunit;
            GlobalTestJson.Initialize();
            TestJsonInitialized := true;
        end;

        CurrentTestOutputJson := GlobalTestJson.ReplaceElement(GetUniqueTestName(CodeunitID, TestName, Description), '{}');
        CurrentTestOutputJson.Add(TestNameLbl, TestName);
        if Description <> '' then
            CurrentTestOutputJson.Add(DescriptionLbl, Description);
        CurrentTestJson := CurrentTestOutputJson.Add(TestOutputLbl, '');
    end;

    procedure TestData(): Codeunit "Test Output Json"
    begin
        exit(CurrentTestJson);
    end;

    procedure GetAllTestOutput(): Codeunit "Test Output Json"
    begin
        exit(GlobalTestJson);
    end;

    procedure ResetOutput()
    begin
        Clear(GlobalTestJson);
        Clear(CurrentTestJson);
        TestJsonInitialized := false;
    end;


    local procedure GetUniqueTestName(CodeunitID: Integer; TestName: Text): Text;
    begin
        exit(GetUniqueTestName(CodeunitID, TestName, ''));
    end;

    local procedure GetUniqueTestName(CodeunitID: Integer; TestName: Text; DataInput: Text): Text
    begin
        if DataInput = '' then
            exit(Format(CodeunitID) + '-' + TestName);

        exit(Format(CodeunitID) + '-' + TestName + '-' + DataInput);
    end;

    var
        TestJsonInitialized: Boolean;
        CurrentTestJson: Codeunit "Test Output Json";
        GlobalTestJson: Codeunit "Test Output Json";
        TestNameLbl: Label 'testName';
        DescriptionLbl: Label 'description', Locked = true;
        TestOutputLbl: Label 'testOutput', Locked = true;
}