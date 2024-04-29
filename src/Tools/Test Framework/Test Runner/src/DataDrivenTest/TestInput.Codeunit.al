codeunit 130460 "Test Input"
{
    SingleInstance = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeCodeunitRun', '', false, false)]
    local procedure InitializeTestInputsBeforeSuiteRun(var TestMethodLine: Record "Test Method Line")
    begin
        ClearGlobals();
        if TestMethodLine."Data Input" = '' then
            exit;

        DataPerSuite.Get(TestMethodLine."Test Suite", TestMethodLine."Data Input");

        DataPerSuiteTestInput.ReadFrom(DataPerSuite.GetInput(DataPerSuite));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeTestMethodRun', '', false, false)]
    local procedure InitializeTestInputsBeforeTestMethodRun(CodeunitID: Integer; CodeunitName: Text[30]; FunctionName: Text[128]; FunctionTestPermissions: TestPermissions; var CurrentTestMethodLine: Record "Test Method Line")
    begin
        if CurrentTestMethodLine."Data Input" = '' then
            exit;

        if CurrentTestMethodLine."Data Input" = DataPerTest.Name then
            exit;

        DataPerTest.Get(CurrentTestMethodLine."Test Suite", CurrentTestMethodLine."Data Input");

        DataPerTestTestInput.ReadFrom(DataPerTest.GetInput(DataPerTest));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnAfterRunTestSuite', '', false, false)]
    local procedure AfterTestSuite()
    begin
        ClearGlobals();
    end;

    local procedure ClearGlobals()
    begin
        Clear(DataPerSuite);
        Clear(DataPerSuiteTestInput);
        Clear(DataPerTest);
        Clear(DataPerTestTestInput);
    end;

    procedure GetTestInput(TestInputName: Text): Variant
    var
        TestInputValueJsonToken: JsonToken;
        TestInputValue: Variant;
    begin
        DataPerSuiteTestInput.Get(TestInputName, TestInputValueJsonToken);
        TestInputValue := TestInputValueJsonToken.AsValue();
        exit(TestInputValue);
    end;

    procedure GetTestInputJsonObject(TestInputName: Text): JsonObject
    var
        TestInputJsonbOject: JsonObject;
        TestInputValueJsonToken: JsonToken;
    begin
        DataPerSuiteTestInput.Get(TestInputName, TestInputValueJsonToken);
        exit(TestInputValueJsonToken.AsObject());
    end;

    procedure GetTestInputJsonArray(TestInputName: Text): JsonArray
    var
        TestInputJsonbOject: JsonObject;
        TestInputValueJsonToken: JsonToken;
    begin
        DataPerSuiteTestInput.Get(TestInputName, TestInputValueJsonToken);
        exit(TestInputValueJsonToken.AsArray());
    end;

    procedure GetTestDataDescription(): Text
    begin
        if DataPerTest.Name <> '' then
            exit(DataPerTest.Name);

        exit(DataPerSuite.Name);
    end;

    var
        DataPerSuite: Record "Test Input";
        DataPerSuiteTestInput: JsonObject;

        DataPerTest: Record "Test Input";
        DataPerTestTestInput: JsonObject;
}