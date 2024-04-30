namespace System.TestTools.TestRunner;

codeunit 130461 "Test Output"
{
    SingleInstance = true;

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
        TestJsonCodeunit: Codeunit "Test Json";
        CurrentTestOutputJson: Interface "Test Json";
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

    procedure TestData(): Interface "Test Json"
    begin
        exit(CurrentTestJson);
    end;

    procedure GetAllTestOutput(): Interface "Test Json"
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
        CurrentTestJson: Interface "Test Json";
        GlobalTestJson: Interface "Test Json";
        TestNameLbl: Label 'testName';
        DescriptionLbl: Label 'description', Locked = true;
        TestOutputLbl: Label 'testOutput', Locked = true;
}