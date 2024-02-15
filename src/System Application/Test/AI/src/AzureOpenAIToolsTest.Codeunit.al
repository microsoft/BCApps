namespace System.Test.AI;

using System.AI;
using System.TestLibraries.AI;
using System.TestLibraries.Utilities;

codeunit 132686 "Azure OpenAI Tools Test"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";
        ToolObjectInvalidErr: Label '%1 object does not contain %2 property.', Comment = '%1 is the object name and %2 is the property that is missing.';

    [Test]
    procedure TestAddingToolsInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
    begin
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
        AOAIChatMessages.AddTool(GetTestFunction1Tool());
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool should exist');
    end;

    [Test]
    procedure TestModifyToolsInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        Tools: List of [JsonObject];
        Function1Tool: JsonObject;
        Function2Tool: JsonObject;
    begin
        Function1Tool := GetTestFunction1Tool();
        Function2Tool := GetTestFunction2Tool();

        AOAIChatMessages.AddTool(Function1Tool);

        Tools := AOAIChatMessages.GetTools();

        LibraryAssert.AreEqual(1, Tools.Count, 'Tool should exist');
        LibraryAssert.AreEqual(Format(Function1Tool), Format(Tools.Get(1)), 'Tool should have same value.');

        AOAIChatMessages.ModifyTool(1, Function2Tool);
        LibraryAssert.AreEqual(Format(Function2Tool), Format(Tools.Get(1)), 'Tool should have same value.');

        AOAIChatMessages.DeleteTool(1);
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
    end;

    [Test]
    procedure TestSetAddToolsToChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
    begin
        AOAIChatMessages.AddTool(GetTestFunction1Tool());
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool should exist');
        AOAIChatMessages.SetAddToolsToPayload(false);
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
    end;

    [Test]
    procedure TestToolFormatInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        Function1Tool: JsonObject;
    begin
        Function1Tool := GetTestFunction1Tool();
        Function1Tool.Remove('type');
        asserterror AOAIChatMessages.AddTool(Function1Tool);
        LibraryAssert.ExpectedError(StrSubstNo(ToolObjectInvalidErr, 'Tool', 'type'));

        Function1Tool := GetTestFunction1Tool();
        Function1Tool.Remove('function');
        asserterror AOAIChatMessages.AddTool(Function1Tool);
        LibraryAssert.ExpectedError(StrSubstNo(ToolObjectInvalidErr, 'Tool', 'function'));
    end;

    [Test]
    procedure TestToolCoiceInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        Function1Tool: JsonObject;
        ToolChoice: Text;
    begin
        Function1Tool := GetTestFunction1Tool();
        AOAIChatMessages.AddTool(GetTestFunction1Tool());
        LibraryAssert.AreEqual('auto', AOAIChatMessages.GetToolChoice(), 'Tool choice should be auto by default.');

        ToolChoice := GetToolChoice();
        AOAIChatMessages.SetToolChoice(ToolChoice);
        LibraryAssert.AreEqual(ToolChoice, AOAIChatMessages.GetToolChoice(), 'Tool choice should be equal to what was set.');
    end;

    [Test]
    procedure TestAssembleToolsInChatMessages()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        Function1Tool: JsonObject;
        Function2Tool: JsonObject;
        Tool1: JsonToken;
        Tool2: JsonToken;
        Tools: JsonArray;
    begin
        Function1Tool := GetTestFunction1Tool();
        AOAIChatMessages.AddTool(GetTestFunction1Tool());

        Function2Tool := GetTestFunction2Tool();
        AOAIChatMessages.AddTool(GetTestFunction2Tool());

        Tools := AzureOpenAITestLibrary.GetAOAIAssembleTools(AOAIChatMessages);

        Tools.Get(0, Tool1);
        Tools.Get(1, Tool2);

        LibraryAssert.AreEqual(2, Tools.Count, 'Tools should have 2 items.');
        LibraryAssert.AreEqual(Format(Function1Tool), Format(Tool1), 'Tool should have same value.');
        LibraryAssert.AreEqual(Format(Function2Tool), Format(Tool2), 'Tool should have same value.');
    end;

    local procedure GetTestFunction1Tool(): JsonObject
    var
        TestTool: Text;
        ToolJsonObject: JsonObject;
    begin
        TestTool := '{"type": "function", "function": {"name": "test_function_1", "parameters": {"type": "object", "properties": {"message": {"type": "string", "description": "The input from user."}}}}}';
        ToolJsonObject.ReadFrom(TestTool);
        exit(ToolJsonObject);
    end;

    local procedure GetTestFunction2Tool(): JsonObject
    var
        TestTool: Text;
        ToolJsonObject: JsonObject;
    begin
        TestTool := '{"type": "function", "function": {"name": "test_function_2", "parameters": {"type": "object", "properties": {"message": {"type": "string", "description": "The input from user."}}}}}';
        ToolJsonObject.ReadFrom(TestTool);
        exit(ToolJsonObject);
    end;

    local procedure GetToolChoice(): Text
    begin
        exit('{"type": "function","function": {"name": "test_function_1"}');
    end;
}