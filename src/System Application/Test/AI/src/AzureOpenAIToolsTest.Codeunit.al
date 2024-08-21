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

        Tools := AOAIChatMessages.GetTools();
#pragma warning restore AL0432

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
#pragma warning disable AL0432
        Tools := AOAIChatMessages.GetTools();
#pragma warning restore AL0432
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
        LibraryAssert.IsTrue(AOAIChatMessages.GetFunctionTool(FunctionNames.Get(1), Function), 'Function does not exist.');
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

    [Test]
    procedure TestJsonModeInParameters()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        Payload: JsonObject;
        ResponseFormatJTok: JsonToken;
        TypeJTok: JsonToken;
    begin
        AOAIChatCompletionParams.SetJsonMode(true);
        AzureOpenAITestLibrary.GetAOAIChatCompletionParametersPayload(AOAIChatCompletionParams, Payload);

        Payload.Get('response_format', ResponseFormatJtok);
        ResponseFormatJTok.AsObject().Get('type', TypeJTok);

        LibraryAssert.AreEqual(TypeJTok.AsValue().AsText(), 'json_object', 'Response format should be json_object');
    end;

    [Test]
    procedure TestNoJsonModeInParameters()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        Payload: JsonObject;
    begin
        AOAIChatCompletionParams.SetJsonMode(false);
        AzureOpenAITestLibrary.GetAOAIChatCompletionParametersPayload(AOAIChatCompletionParams, Payload);

        LibraryAssert.IsFalse(Payload.Contains('response_format'), 'Response format should not exist');
    end;

    [Test]
    procedure TestNoJsonModeInParametersByDefault()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        Payload: JsonObject;
    begin
        AzureOpenAITestLibrary.GetAOAIChatCompletionParametersPayload(AOAIChatCompletionParams, Payload);

        LibraryAssert.IsFalse(Payload.Contains('response_format'), 'Response format should not exist');
    end;

    [Test]
    procedure TestToolRegistrationAndVerification()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);

        AOAIChatMessages.AddSystemMessage('test system message');
        AOAIChatMessages.AddUserMessage('test user message');

        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool should exist');
    end;

    [Test]
    procedure TestToolSelection()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
        ToolCallId: Text;
        ToolCalls: JsonArray;
        ToolCall: JsonToken;
        TestProperty: JsonToken;
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);

        AOAIChatMessages.AddSystemMessage('test system message');
        AOAIChatMessages.AddUserMessage('test user message');

        // LLM responds with tool calls
        ToolCallId := 'call_of7GnOMuBT4H95XkuN14qfai';
        AzureOpenAITestLibrary.SetToolCalls(AOAIChatMessages, ToolCallId, TestFunction1.GetName());

        ToolCalls := AOAIChatMessages.GetLastToolCalls();
        LibraryAssert.AreEqual(1, ToolCalls.Count(), 'Tool calls should contain one tool call');
        LibraryAssert.IsTrue(ToolCalls.Get(0, ToolCall), 'Could not get the tool call');

        LibraryAssert.IsTrue(ToolCall.SelectToken('$.type', TestProperty), 'Could not find type parameter');
        LibraryAssert.AreEqual('function', TestProperty.AsValue().AsText(), 'Type was not set to function');

        LibraryAssert.IsTrue(ToolCall.SelectToken('$.id', TestProperty), 'Could not find id parameter');
        LibraryAssert.AreEqual(ToolCallId, TestProperty.AsValue().AsText(), 'Tool call id was not set correctly');

        LibraryAssert.IsTrue(ToolCall.SelectToken('$.function.name', TestProperty), 'Could not find function name');
        LibraryAssert.AreEqual(TestFunction1.GetName(), TestProperty.AsValue().AsText(), 'Function name was not set correctly');
    end;

    [Test]
    procedure TestFunctionCallResult()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
        ToolCallId: Text;
        FunctionExecutionResult: Text;
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);

        AOAIChatMessages.AddSystemMessage('test system message');
        AOAIChatMessages.AddUserMessage('test user message');

        // LLM responds with tool calls
        ToolCallId := 'call_of7GnOMuBT4H95XkuN14qfai';
        AzureOpenAITestLibrary.SetToolCalls(AOAIChatMessages, ToolCallId, TestFunction1.GetName());

        // Selected function was executed by system
        FunctionExecutionResult := 'test function execution result';
        AzureOpenAITestLibrary.AddAOAIFunctionResponse(AOAIOperationResponse, AOAIFunctionResponse, true, Enum::"AOAI Function Response Status"::"Invoke Success", TestFunction1.GetName(), ToolCallId, '', FunctionExecutionResult, '', '');

        LibraryAssert.IsTrue(AOAIOperationResponse.IsFunctionCall(), 'Function call should be true.');
        LibraryAssert.AreEqual(AOAIFunctionResponse.GetFunctionName(), TestFunction1.GetName(), 'Function name should be the same as the value set.');
        LibraryAssert.AreEqual(AOAIFunctionResponse.GetFunctionId(), ToolCallId, 'Function id should be the same as the value set.');
        LibraryAssert.AreEqual(AOAIFunctionResponse.GetResult(), FunctionExecutionResult, 'Function response should be the same as the value set.');
    end;

    [Test]
    procedure TestAddFunctionResultToChatMessages()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
        ToolCallId: Text;
        FunctionExecutionResult: Text;
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);

        AOAIChatMessages.AddSystemMessage('test system message');
        AOAIChatMessages.AddUserMessage('test user message');

        // LLM responds with tool calls
        ToolCallId := 'call_of7GnOMuBT4H95XkuN14qfai';
        AzureOpenAITestLibrary.SetToolCalls(AOAIChatMessages, ToolCallId, TestFunction1.GetName());

        // Selected function was executed by system
        FunctionExecutionResult := 'test function execution result';
        AzureOpenAITestLibrary.SetAOAIFunctionResponse(AOAIFunctionResponse, true, Enum::"AOAI Function Response Status"::"Invoke Success", TestFunction1.GetName(), ToolCallId, '', FunctionExecutionResult, '', '');

        // Save the function execution result to the chat messages
        AOAIChatMessages.AddToolMessage(AOAIFunctionResponse.GetFunctionId(), AOAIFunctionResponse.GetFunctionName(), AOAIFunctionResponse.GetResult());

        LibraryAssert.AreEqual(Enum::"AOAI Chat Roles"::Tool, AOAIChatMessages.GetLastRole(), 'The message should be a tool message');
        LibraryAssert.AreEqual(AOAIChatMessages.GetLastMessage(), FunctionExecutionResult, 'Last message should be the function execution result.');
    end;

    [Test]
    procedure TestToolCleanup()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        ToolCallId: Text;
        FunctionExecutionResult: Text;
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);

        AOAIChatMessages.AddSystemMessage('test system message');
        AOAIChatMessages.AddUserMessage('test user message');

        // LLM responds with tool calls
        ToolCallId := 'call_of7GnOMuBT4H95XkuN14qfai';
        AzureOpenAITestLibrary.SetToolCalls(AOAIChatMessages, ToolCallId, TestFunction1.GetName());

        // Selected function was executed by system
        FunctionExecutionResult := 'test function execution result';
        AzureOpenAITestLibrary.SetAOAIFunctionResponse(AOAIFunctionResponse, true, Enum::"AOAI Function Response Status"::"Invoke Success", TestFunction1.GetName(), ToolCallId, '', FunctionExecutionResult, '', '');

        // Save the function execution result to the chat messages
        AOAIChatMessages.AddToolMessage(AOAIFunctionResponse.GetFunctionId(), AOAIFunctionResponse.GetFunctionName(), AOAIFunctionResponse.GetResult());

        // Remove the functions from the tool list
        AOAIChatMessages.ClearTools();

        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
    end;

    [Test]
    procedure TestJsonRepresentationOfChatMessagesHistory()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        ToolCallId: Text;
        ToolSelectionResponseLbl: Label '[{"id":"%1","type":"function","function":{"name":"%2","arguments":"{}"}}]', Locked = true;
        FunctionExecutionResult: Text;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        JsonTok: JsonToken;
        TextValue: Text;
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);

        AOAIChatMessages.AddSystemMessage('test system message');
        AOAIChatMessages.AddUserMessage('test user message');

        // LLM responds with tool calls
        ToolCallId := 'call_of7GnOMuBT4H95XkuN14qfai';
        AzureOpenAITestLibrary.SetToolCalls(AOAIChatMessages, ToolCallId, TestFunction1.GetName());

        // Selected function was executed by system
        FunctionExecutionResult := 'test function execution result';
        AzureOpenAITestLibrary.SetAOAIFunctionResponse(AOAIFunctionResponse, true, Enum::"AOAI Function Response Status"::"Invoke Success", TestFunction1.GetName(), ToolCallId, '', FunctionExecutionResult, '', '');

        // Save the function execution result to the chat messages
        AOAIChatMessages.AddToolMessage(AOAIFunctionResponse.GetFunctionId(), AOAIFunctionResponse.GetFunctionName(), AOAIFunctionResponse.GetResult());

        // Remove the functions from the tool list
        AOAIChatMessages.ClearTools();

        // Check Json representation of the chat messages history
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(5, AOAIChatMessages);
        LibraryAssert.AreEqual(4, HistoryJsonArray.Count, 'History should have 4 items.');

        // Check system message
        HistoryJsonArray.Get(0, MessageJsonTok);
        MessageJsonTok.AsObject().Get('role', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), 'system', 'Role should be system');

        MessageJsonTok.AsObject().Get('content', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), 'test system message', 'Content should be test system message');

        // Check user message
        HistoryJsonArray.Get(1, MessageJsonTok);
        MessageJsonTok.AsObject().Get('role', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), 'user', 'Role should be user');

        MessageJsonTok.AsObject().Get('content', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), 'test user message', 'Content should be test user message');

        // Check assistant message
        HistoryJsonArray.Get(2, MessageJsonTok);
        MessageJsonTok.AsObject().Get('role', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), 'assistant', 'Role should be assistant');

        MessageJsonTok.AsObject().Get('tool_calls', JsonTok);
        JsonTok.WriteTo(TextValue);
        LibraryAssert.AreEqual(TextValue, StrSubstNo(ToolSelectionResponseLbl, ToolCallId, TestFunction1.GetName()), 'Tool call should be the same as the value set.');

        // Check tool message
        HistoryJsonArray.Get(3, MessageJsonTok);
        MessageJsonTok.AsObject().Get('role', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), 'tool', 'Role should be tool');

        MessageJsonTok.AsObject().Get('content', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), FunctionExecutionResult, 'Content should be the function execution result');

        MessageJsonTok.AsObject().Get('name', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), TestFunction1.GetName(), 'Function name should be the same as the value set.');

        MessageJsonTok.AsObject().Get('tool_call_id', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), ToolCallId, 'Tool call id should be the same as the value set.');
    end;

    [Test]
    procedure TestAppendToolResultFailIfNoToolCalls()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        ToolCallId: Text;
        FunctionExecutionResult: Text;
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);

        AOAIChatMessages.AddSystemMessage('test system message');
        AOAIChatMessages.AddUserMessage('test user message');

        AOAIChatMessages.AddAssistantMessage('an assistant message instead of a tool calls result');

        // Create some operation and function response for a tool call that did not happen
        ToolCallId := 'call_of7GnOMuBT4H95XkuN14qfai';
        FunctionExecutionResult := 'test function execution result';
        AzureOpenAITestLibrary.AddAOAIFunctionResponse(AOAIOperationResponse, AOAIFunctionResponse, true, Enum::"AOAI Function Response Status"::"Invoke Success", TestFunction1.GetName(), ToolCallId, '', FunctionExecutionResult, '', '');

        // Append the incorrect function response
        asserterror AOAIOperationResponse.AppendFunctionResponsesToChatMessages(AOAIChatMessages);

        LibraryAssert.ExpectedError('does not contain any tool calls');
    end;

    [Test]
    procedure TestAppendToolResultFailIfNoToolCallsWithIncorrectRole()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        ToolCallId: Text;
        FunctionExecutionResult: Text;
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);

        AOAIChatMessages.AddSystemMessage('test system message');
        AOAIChatMessages.AddUserMessage('test user message');

        // LLM responds with tool calls
        ToolCallId := 'call_of7GnOMuBT4H95XkuN14qfai';
        AzureOpenAITestLibrary.SetToolCalls(AOAIChatMessages, ToolCallId, TestFunction1.GetName());

        AOAIChatMessages.AddSystemMessage('another system message that was placed after the tool calls response');

        // Create some operation and function response for a tool call that did not happen
        FunctionExecutionResult := 'test function execution result';
        AzureOpenAITestLibrary.AddAOAIFunctionResponse(AOAIOperationResponse, AOAIFunctionResponse, true, Enum::"AOAI Function Response Status"::"Invoke Success", TestFunction1.GetName(), ToolCallId, '', FunctionExecutionResult, '', '');

        // Append the incorrect function response
        asserterror AOAIOperationResponse.AppendFunctionResponsesToChatMessages(AOAIChatMessages);

        LibraryAssert.ExpectedError('must have a role of assistant');
    end;

    [Test]
    procedure TestAppendToolResultFailIfNoMatchingToolCalls()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        ToolCallId: Text;
        FunctionExecutionResult: Text;
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);

        AOAIChatMessages.AddSystemMessage('test system message');
        AOAIChatMessages.AddUserMessage('test user message');

        // LLM responds with tool calls
        ToolCallId := 'call_of7GnOMuBT4H95XkuN14qfai';
        AzureOpenAITestLibrary.SetToolCalls(AOAIChatMessages, ToolCallId, TestFunction1.GetName());

        // Create some operation and function response for a tool call that did not happen
        ToolCallId := 'call_anothertoolcallid';
        FunctionExecutionResult := 'test function execution result';
        AzureOpenAITestLibrary.AddAOAIFunctionResponse(AOAIOperationResponse, AOAIFunctionResponse, true, Enum::"AOAI Function Response Status"::"Invoke Success", TestFunction2.GetName(), ToolCallId, '', FunctionExecutionResult, '', '');

        // Append the incorrect function response
        asserterror AOAIOperationResponse.AppendFunctionResponsesToChatMessages(AOAIChatMessages);

        LibraryAssert.ExpectedError('does not exist in the tool calls');
    end;

    [Test]
    procedure TestAppendToolResultFromToolCalls()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        TestFunction2: Codeunit "Test Function 2";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        ToolCallId: Text;
        ToolSelectionResponseLbl: Label '[{"id":"%1","type":"function","function":{"name":"%2","arguments":"{}"}}]', Locked = true;
        FunctionExecutionResult: Text;
        HistoryJsonArray: JsonArray;
        MessageJsonTok: JsonToken;
        JsonTok: JsonToken;
        TextValue: Text;
    begin
        AOAIChatMessages.AddTool(TestFunction1);
        AOAIChatMessages.AddTool(TestFunction2);

        AOAIChatMessages.AddSystemMessage('test system message');
        AOAIChatMessages.AddUserMessage('test user message');

        // LLM responds with tool calls
        ToolCallId := 'call_of7GnOMuBT4H95XkuN14qfai';
        AzureOpenAITestLibrary.SetToolCalls(AOAIChatMessages, ToolCallId, TestFunction1.GetName());

        // Create an operation and function response for the tool call
        FunctionExecutionResult := 'test function execution result';
        AzureOpenAITestLibrary.AddAOAIFunctionResponse(AOAIOperationResponse, AOAIFunctionResponse, true, Enum::"AOAI Function Response Status"::"Invoke Success", TestFunction1.GetName(), ToolCallId, '', FunctionExecutionResult, '', '');

        // Append the function response
        AOAIOperationResponse.AppendFunctionResponsesToChatMessages(AOAIChatMessages);

        // Check Json representation of the chat messages history
        HistoryJsonArray := AzureOpenAITestLibrary.GetAOAIHistory(5, AOAIChatMessages);
        LibraryAssert.AreEqual(4, HistoryJsonArray.Count, 'History should have 4 items.');

        HistoryJsonArray.Get(2, MessageJsonTok);
        MessageJsonTok.AsObject().Get('tool_calls', JsonTok);
        JsonTok.WriteTo(TextValue);
        LibraryAssert.AreEqual(TextValue, StrSubstNo(ToolSelectionResponseLbl, ToolCallId, TestFunction1.GetName()), 'Tool call should be the same as the value set.');

        // Check tool message
        HistoryJsonArray.Get(3, MessageJsonTok);
        MessageJsonTok.AsObject().Get('role', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), 'tool', 'Role should be tool');

        MessageJsonTok.AsObject().Get('content', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), FunctionExecutionResult, 'Content should be the function execution result');

        MessageJsonTok.AsObject().Get('name', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), TestFunction1.GetName(), 'Function name should be the same as the value set.');

        MessageJsonTok.AsObject().Get('tool_call_id', JsonTok);
        LibraryAssert.AreEqual(JsonTok.AsValue().AsText(), ToolCallId, 'Tool call id should be the same as the value set.');
    end;

    [Test]
    procedure TestFunctionCallIsSuccessProcedure()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        AOAIFunctionResponseStatus: Enum "AOAI Function Response Status";
        AOAIFunctionRepsonseStatusCode: Integer;
        ToolCallId: Text;
        FunctionExecutionResult: Text;
    begin
        AOAIChatMessages.AddTool(TestFunction1);

        AOAIChatMessages.AddSystemMessage('test system message');
        AOAIChatMessages.AddUserMessage('test user message');

        // LLM responds with tool calls
        ToolCallId := 'call_of7GnOMuBT4H95XkuN14qfai';
        AzureOpenAITestLibrary.SetToolCalls(AOAIChatMessages, ToolCallId, TestFunction1.GetName());

        // Create an operation and function response for the tool call
        FunctionExecutionResult := 'test function execution result';

        // Enumerate the function response statuses
        foreach AOAIFunctionRepsonseStatusCode in Enum::"AOAI Function Response Status".Ordinals() do begin
            AOAIFunctionResponseStatus := Enum::"AOAI Function Response Status".FromInteger(AOAIFunctionRepsonseStatusCode);
            AzureOpenAITestLibrary.SetAOAIFunctionResponse(AOAIFunctionResponse, true, AOAIFunctionResponseStatus, TestFunction1.GetName(), ToolCallId, '', FunctionExecutionResult, '', '');

            LibraryAssert.AreEqual(AOAIFunctionResponseStatus in [Enum::"AOAI Function Response Status"::"Invoke Success"], AOAIFunctionResponse.IsSuccess(), 'IsSuccess did not return the expected result for the given response status');
        end;
    end;

    [Test]
    procedure TestTryGetFunctionReponsesByName()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        AOAIFunctionResponses: List of [Codeunit "AOAI Function Response"];
        ToolCallId: Text;
        FunctionExecutionResult: Text;
        Counter: Integer;
        FunctionCount: Integer;
    begin
        for FunctionCount := 1 to 5 do begin
            FunctionExecutionResult := 'test function execution result';
            for Counter := 1 to FunctionCount do begin
                Clear(AOAIFunctionResponse);
                AzureOpenAITestLibrary.AddAOAIFunctionResponse(AOAIOperationResponse, AOAIFunctionResponse, true, Enum::"AOAI Function Response Status"::"Invoke Success", 'TestFunction' + Format(FunctionCount), ToolCallId, '', FunctionExecutionResult, '', '');
            end;
        end;

        LibraryAssert.IsFalse(AOAIOperationResponse.HasFunctionResponsesByName(''), 'A function was found for an empty function name');
        LibraryAssert.IsFalse(AOAIOperationResponse.HasFunctionResponsesByName('TestFunctionThatDoesNotExist'), 'A function was found for a function name that does not exist');
        for FunctionCount := 1 to 5 do begin
            LibraryAssert.IsTrue(AOAIOperationResponse.HasFunctionResponsesByName('TestFunction' + Format(FunctionCount)), 'Could not find the expected function');
            LibraryAssert.IsTrue(AOAIOperationResponse.TryGetFunctionReponsesByName('TestFunction' + Format(FunctionCount), AOAIFunctionResponses), 'Could get the list of expected functions');
            LibraryAssert.AreEqual(FunctionCount, AOAIFunctionResponses.Count(), 'Incorrect number of function responses returned');
            foreach AOAIFunctionResponse in AOAIFunctionResponses do
                LibraryAssert.AreEqual('TestFunction' + Format(FunctionCount), AOAIFunctionResponse.GetFunctionName(), 'Function name did not match');
        end;
    end;

    [Test]
    procedure TestFunctionCallInvokedManually()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        ToolCallId: Text;
        FunctionExecutionResult: Text;
        ToolCall: JsonToken;
        ArgumentToken: JsonToken;
        ParsedArguments: JsonObject;
    begin
        AOAIChatMessages.AddTool(TestFunction1);

        AOAIChatMessages.AddSystemMessage('test system message');
        AOAIChatMessages.AddUserMessage('test user message');

        AOAIChatMessages.SetToolInvokePreference(Enum::"AOAI Tool Invoke Preference"::Manual);

        // Function is been selected by LLM
        ToolCallId := 'call_of7GnOMuBT4H95XkuN14qfai';
        AzureOpenAITestLibrary.SetToolCalls(AOAIChatMessages, ToolCallId, TestFunction1.GetName(), '{\"TestParameter\": \"TestValue\"}');

        // Create an operation and function response for the tool call
        AOAIChatMessages.GetLastToolCalls().Get(0, ToolCall);
        ToolCall.SelectToken('$.function.arguments', ArgumentToken);
        FunctionExecutionResult := ''; // the function is not invoked

        AzureOpenAITestLibrary.AddAOAIFunctionResponse(AOAIOperationResponse, AOAIFunctionResponse, true, Enum::"AOAI Function Response Status"::"Not Invoked", TestFunction1.GetName(), ToolCallId, ArgumentToken.AsValue().AsText(), FunctionExecutionResult, '', '');

        // Assert the operation and result
        LibraryAssert.AreEqual(true, AOAIOperationResponse.IsFunctionCall(), 'Expected function call');
        LibraryAssert.AreEqual(true, AOAIOperationResponse.IsSuccess(), 'The operation did not succeed');
        LibraryAssert.AreEqual(1, AOAIOperationResponse.GetFunctionResponses().Count(), 'There was not exactly one function response');

        AOAIFunctionResponse := AOAIOperationResponse.GetFunctionResponses().Get(1);

        LibraryAssert.AreEqual(false, AOAIFunctionResponse.IsSuccess(), 'The function was invoked successfully when the invoke preference was manual');
        LibraryAssert.AreEqual(Enum::"AOAI Function Response Status"::"Not Invoked", AOAIFunctionResponse.GetStatus(), 'The function is not in the expected status');
        LibraryAssert.AreEqual(TestFunction1.GetName(), AOAIFunctionResponse.GetFunctionName(), 'The function returned was not the expected name');

        ParsedArguments := AOAIFunctionResponse.GetArguments();
        LibraryAssert.IsTrue(ParsedArguments.Get('TestParameter', ArgumentToken), 'Could not find argument parameter');
        LibraryAssert.AreEqual('TestValue', ArgumentToken.AsValue().AsText(), 'Could not read argument parameter');

        FunctionExecutionResult := TestFunction1.Execute(ParsedArguments);
        LibraryAssert.AreNotEqual('', FunctionExecutionResult, 'The function was not invoked successfully');
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