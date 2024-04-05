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
#if not CLEAN25
    [Test]
    procedure TestAddingToolsInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
    begin
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
#pragma warning disable AL0432
        AOAIChatMessages.AddTool(GetTestFunction1Tool());
#pragma warning restore AL0432
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool via JsonObject should exist');
    end;
#endif

    [Test]
    procedure TestAddingFunctionsInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
    begin
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
        AOAIChatMessages.AddTool(TestFunction1);
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool via interface should exist');
    end;

#if not CLEAN25
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
#pragma warning disable AL0432
        AOAIChatMessages.AddTool(Function1Tool);
#pragma warning restore AL0432

        Tools := AOAIChatMessages.GetTools();

        LibraryAssert.AreEqual(1, Tools.Count, 'Tool should exist');
        LibraryAssert.AreEqual(Format(Function1Tool), Format(Tools.Get(1)), 'Tool should have same value.');
#pragma warning disable AL0432
        AOAIChatMessages.ModifyTool(1, Function2Tool);
#pragma warning restore AL0432
        LibraryAssert.AreEqual(Format(Function2Tool), Format(Tools.Get(1)), 'Tool should have same value.');
#pragma warning disable AL0432
        AOAIChatMessages.DeleteTool(1);
#pragma warning restore AL0432
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
    end;

    [Test]
    procedure TestDeleteToolInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        Tools: List of [JsonObject];
        ToolObject: JsonObject;
        Payload: Text;
    begin
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
#pragma warning disable AL0432
        AOAIChatMessages.AddTool(GetTestFunction1Tool());
        AOAIChatMessages.AddTool(GetTestFunction2Tool());
#pragma warning restore AL0432
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool should exist');
#pragma warning disable AL0432
        AOAIChatMessages.DeleteTool(1);
#pragma warning restore AL0432
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool should exist');
        Tools := AOAIChatMessages.GetTools();
        Tools.Get(1, ToolObject);
        ToolObject.WriteTo(Payload);
        LibraryAssert.AreEqual(Format(GetTestFunction2Tool()), Payload, 'Tool should have same value.');
    end;
#endif

    [Test]
    procedure TestDeleteFunctionToolInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
        Function: Interface "AOAI Function";
        FunctionNames: List of [Text];
        Payload: Text;
    begin
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool should exist');
        AOAIChatMessages.DeleteFunctionTool(TestFunction1.GetName());
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool should exist');

        FunctionNames := AOAIChatMessages.GetFunctionTools();
        Function := AOAIChatMessages.GetFunctionTool(FunctionNames.Get(1));
        Function.GetPrompt().WriteTo(Payload);
        LibraryAssert.AreEqual(Format(TestFunction2.GetPrompt()), Payload, 'Tool should have same value.');
    end;

#if not CLEAN25
    [Test]
    procedure TestClearToolsInChatMessagesObsoleted()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
    begin
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
#pragma warning disable AL0432
        AOAIChatMessages.AddTool(GetTestFunction1Tool());
        AOAIChatMessages.AddTool(GetTestFunction2Tool());
#pragma warning restore AL0432
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool should exist');
        AOAIChatMessages.ClearTools();
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'No tool should exist');
    end;
#endif

    [Test]
    procedure TestClearToolsInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
    begin
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool should exist');
        AOAIChatMessages.ClearTools();
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'No tool should exist');
    end;

#if not CLEAN25
    [Test]
    procedure TestSetAddToolsToChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
    begin
#pragma warning disable AL0432
        AOAIChatMessages.AddTool(GetTestFunction1Tool());
#pragma warning restore AL0432
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool should exist');
        AOAIChatMessages.SetAddToolsToPayload(false);
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
    end;
#endif

    [Test]
    procedure TestSetAddFunctionToolsToChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool should exist');
        AOAIChatMessages.SetAddToolsToPayload(false);
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
    end;
#if not CLEAN25
    [Test]
    procedure TestToolFormatInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        Function1Tool: JsonObject;
    begin
        Function1Tool := GetTestFunction1Tool();
        Function1Tool.Remove('type');
#pragma warning disable AL0432
        asserterror AOAIChatMessages.AddTool(Function1Tool);
#pragma warning restore AL0432
        LibraryAssert.ExpectedError(StrSubstNo(ToolObjectInvalidErr, 'Tool', 'type'));

        Function1Tool := GetTestFunction1Tool();
        Function1Tool.Remove('function');
#pragma warning disable AL0432
        asserterror AOAIChatMessages.AddTool(Function1Tool);
#pragma warning restore AL0432
        LibraryAssert.ExpectedError(StrSubstNo(ToolObjectInvalidErr, 'Tool', 'function'));
    end;
#endif

    [Test]
    procedure TestFunctionToolFormatInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        BadTestFunction1: Codeunit "Bad Test Function 1";
        BadTestFunction2: Codeunit "Bad Test Function 2";
    begin
        asserterror AOAIChatMessages.AddTool(BadTestFunction1);
        LibraryAssert.ExpectedError(StrSubstNo(ToolObjectInvalidErr, 'Tool', 'type'));

        asserterror AOAIChatMessages.AddTool(BadTestFunction2);
        LibraryAssert.ExpectedError(StrSubstNo(ToolObjectInvalidErr, 'Tool', 'function'));
    end;

#if not CLEAN25
    [Test]
    procedure TestToolCoiceInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        Function1Tool: JsonObject;
        ToolChoice: Text;
    begin
        Function1Tool := GetTestFunction1Tool();
#pragma warning disable AL0432
        AOAIChatMessages.AddTool(GetTestFunction1Tool());
#pragma warning restore AL0432
        LibraryAssert.AreEqual('auto', AOAIChatMessages.GetToolChoice(), 'Tool choice should be auto by default.');

        ToolChoice := GetToolChoice();
        AOAIChatMessages.SetToolChoice(ToolChoice);
        LibraryAssert.AreEqual(ToolChoice, AOAIChatMessages.GetToolChoice(), 'Tool choice should be equal to what was set.');
    end;
#endif

    [Test]
    procedure TestToolChoiceInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        ToolChoice: Text;
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        LibraryAssert.AreEqual('auto', AOAIChatMessages.GetToolChoice(), 'Tool choice should be auto by default.');

        ToolChoice := GetToolChoice();
        AOAIChatMessages.SetToolChoice(ToolChoice);
        LibraryAssert.AreEqual(ToolChoice, AOAIChatMessages.GetToolChoice(), 'Tool choice should be equal to what was set.');
    end;

    [Test]
    procedure TestAssembleFunctionToolsInChatMessages()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
        FunctionNames: List of [Text];
        Tool1: JsonToken;
        Tool2: JsonToken;
        Tools: JsonArray;
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);

        FunctionNames := AOAIChatMessages.GetFunctionTools();
        Tools := AzureOpenAITestLibrary.GetAOAIAssembleTools(AOAIChatMessages);

        Tools.Get(0, Tool1);
        Tools.Get(1, Tool2);

        LibraryAssert.AreEqual(2, Tools.Count, 'Tools should have 2 items.');
        LibraryAssert.AreEqual(Format(TestFunction1.GetPrompt()), Format(Tool1), 'Tool should have same value.');
        LibraryAssert.AreEqual(Format(TestFunction2.GetPrompt()), Format(Tool2), 'Tool should have same value.');
    end;

#if not CLEAN25
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
#pragma warning disable AL0432
        AOAIChatMessages.AddTool(GetTestFunction1Tool());
#pragma warning restore AL0432

        Function2Tool := GetTestFunction2Tool();
#pragma warning disable AL0432
        AOAIChatMessages.AddTool(GetTestFunction2Tool());
#pragma warning restore AL0432

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
#endif

    local procedure GetToolChoice(): Text
    begin
        exit('{"type": "function","function": {"name": "test_function_1"}');
    end;
}