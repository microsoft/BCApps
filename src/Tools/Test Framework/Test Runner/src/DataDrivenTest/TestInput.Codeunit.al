namespace System.TestTools.TestRunner;

codeunit 130460 "Test Input"
{
    procedure test()
    var
        TestInput: Codeunit "Test Input";
        AccountNameText: Text;
        HarmsInputText: Text;
    begin
        AccountNameText := TestInput.GetTestInput('AccountName');
        HarmsInputText := TestInput.GetTestInput('HarmsInput');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", 'OnBeforeCodeunitRun', '', false, false)]
    local procedure InitializeTestInputsBeforeTestRun(var TestMethodLine: Record "Test Method Line")
    var
        CurrentTestMethodLine: Record "Test Method Line";
        CurrentTestMethodTestInput: Record "Test Input";
    begin
        if not TestMethodLine."Data Input".HasValue() then
            exit;

        CurrentTestMethodLine.Copy(TestMethodLine);
        CurrentTestMethodTestInput.Get(TestMethodLine."Data Input");

        CurrentTestInput.ReadFrom(CurrentTestMethodTestInput.GetInput(CurrentTestMethodTestInput));
    end;

    procedure GetTestInput(TestInputName: Text): Variant
    var
        TestInputValueJsonToken: JsonToken;
        TestInputValue: Variant;
    begin
        CurrentTestInput.Get(TestInputName, TestInputValueJsonToken);
        TestInputValue := TestInputValueJsonToken.AsValue();
        exit(TestInputValue);
    end;

    procedure GetTestInputJsonObject(TestInputName: Text): JsonObject
    var
        TestInputJsonbOject: JsonObject;
        TestInputValueJsonToken: JsonToken;
    begin
        CurrentTestInput.Get(TestInputName, TestInputValueJsonToken);
        exit(TestInputValueJsonToken.AsObject());
    end;

    procedure GetTestInputJsonArray(TestInputName: Text): JsonArray
    var
        TestInputJsonbOject: JsonObject;
        TestInputValueJsonToken: JsonToken;
    begin
        CurrentTestInput.Get(TestInputName, TestInputValueJsonToken);
        exit(TestInputValueJsonToken.AsArray());
    end;

    var
        CurrentTestInput: JsonObject;
}