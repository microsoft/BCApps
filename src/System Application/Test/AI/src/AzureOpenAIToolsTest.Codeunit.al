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
    procedure TestAddingFunctionsInChatMessages()
    var
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        TestFunction1: Codeunit "Test Function 1";
    begin
        LibraryAssert.IsFalse(AOAIChatMessages.ToolsExists(), 'Tool should not exist');
        AOAIChatMessages.AddTool(TestFunction1);
        LibraryAssert.IsTrue(AOAIChatMessages.ToolsExists(), 'Tool via interface should exist');
    end;


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


    local procedure GetToolChoice(): Text
    begin
        exit('{"type": "function","function": {"name": "test_function_1"}');
    end;
    [Test]
    procedure TestChatCompletionParamsDefaultPayloadHasStandardFields()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        Payload: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Default chat completion params produce a standard (non-reasoning) payload

        // [GIVEN] Default AOAIChatCompletionParams (no reasoning effort set)
        // [WHEN] Parameters are added to the payload
        AzureOpenAITestLibrary.GetAOAIChatCompletionParametersPayload(AOAIChatCompletionParams, Payload);

        // [THEN] Standard parameters are present
        LibraryAssert.IsTrue(Payload.Get('temperature', Token), 'Payload should contain temperature.');
        LibraryAssert.IsTrue(Payload.Get('presence_penalty', Token), 'Payload should contain presence_penalty.');
        LibraryAssert.IsTrue(Payload.Get('frequency_penalty', Token), 'Payload should contain frequency_penalty.');

        // [THEN] Reasoning model parameters are absent
        LibraryAssert.IsFalse(Payload.Get('reasoning_effort', Token), 'Payload should not contain reasoning_effort.');
        LibraryAssert.IsFalse(Payload.Get('max_completion_tokens', Token), 'Payload should not contain max_completion_tokens.');
    end;

    [Test]
    procedure TestChatCompletionParamsReasoningEffortLowPayload()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        Payload: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Setting reasoning effort Low produces a reasoning model payload

        // [GIVEN] ReasoningEffort set to Low
        AOAIChatCompletionParams.SetReasoningEffort(Enum::"AOAI Reasoning Effort"::Low);

        // [WHEN] Parameters are added to the payload
        AzureOpenAITestLibrary.GetAOAIChatCompletionParametersPayload(AOAIChatCompletionParams, Payload);

        // [THEN] reasoning_effort is 'low'
        LibraryAssert.IsTrue(Payload.Get('reasoning_effort', Token), 'Payload should contain reasoning_effort.');
        LibraryAssert.AreEqual('low', Token.AsValue().AsText(), 'reasoning_effort should be low.');

        // [THEN] Standard non-reasoning parameters are absent
        LibraryAssert.IsFalse(Payload.Get('temperature', Token), 'Payload should not contain temperature for reasoning models.');
        LibraryAssert.IsFalse(Payload.Get('presence_penalty', Token), 'Payload should not contain presence_penalty for reasoning models.');
        LibraryAssert.IsFalse(Payload.Get('frequency_penalty', Token), 'Payload should not contain frequency_penalty for reasoning models.');
    end;

    [Test]
    procedure TestChatCompletionParamsReasoningEffortMediumPayload()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        Payload: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Setting reasoning effort Medium produces correct payload value

        // [GIVEN] ReasoningEffort set to Medium
        AOAIChatCompletionParams.SetReasoningEffort(Enum::"AOAI Reasoning Effort"::Medium);

        // [WHEN] Parameters are added to the payload
        AzureOpenAITestLibrary.GetAOAIChatCompletionParametersPayload(AOAIChatCompletionParams, Payload);

        // [THEN] reasoning_effort is 'medium'
        LibraryAssert.IsTrue(Payload.Get('reasoning_effort', Token), 'Payload should contain reasoning_effort.');
        LibraryAssert.AreEqual('medium', Token.AsValue().AsText(), 'reasoning_effort should be medium.');
    end;

    [Test]
    procedure TestChatCompletionParamsReasoningEffortHighPayload()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        Payload: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Setting reasoning effort High produces correct payload value

        // [GIVEN] ReasoningEffort set to High
        AOAIChatCompletionParams.SetReasoningEffort(Enum::"AOAI Reasoning Effort"::High);

        // [WHEN] Parameters are added to the payload
        AzureOpenAITestLibrary.GetAOAIChatCompletionParametersPayload(AOAIChatCompletionParams, Payload);

        // [THEN] reasoning_effort is 'high'
        LibraryAssert.IsTrue(Payload.Get('reasoning_effort', Token), 'Payload should contain reasoning_effort.');
        LibraryAssert.AreEqual('high', Token.AsValue().AsText(), 'reasoning_effort should be high.');
    end;

    [Test]
    procedure TestChatCompletionParamsReasoningEffortUsesMaxCompletionTokens()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        Payload: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Reasoning models use max_completion_tokens instead of max_tokens

        // [GIVEN] ReasoningEffort set and MaxTokens configured
        AOAIChatCompletionParams.SetReasoningEffort(Enum::"AOAI Reasoning Effort"::Medium);
        AOAIChatCompletionParams.SetMaxTokens(1000);

        // [WHEN] Parameters are added to the payload
        AzureOpenAITestLibrary.GetAOAIChatCompletionParametersPayload(AOAIChatCompletionParams, Payload);

        // [THEN] max_completion_tokens is used, not max_tokens
        LibraryAssert.IsTrue(Payload.Get('max_completion_tokens', Token), 'Payload should contain max_completion_tokens for reasoning models.');
        LibraryAssert.AreEqual(1000, Token.AsValue().AsInteger(), 'max_completion_tokens should be 1000.');
        LibraryAssert.IsFalse(Payload.Get('max_tokens', Token), 'Payload should not contain max_tokens for reasoning models.');
    end;

    [Test]
    procedure TestChatCompletionParamsStandardModelUsesMaxTokens()
    var
        AzureOpenAITestLibrary: Codeunit "Azure OpenAI Test Library";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        Payload: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] Standard models use max_tokens

        // [GIVEN] No reasoning effort, MaxTokens configured
        AOAIChatCompletionParams.SetMaxTokens(500);

        // [WHEN] Parameters are added to the payload
        AzureOpenAITestLibrary.GetAOAIChatCompletionParametersPayload(AOAIChatCompletionParams, Payload);

        // [THEN] max_tokens is used, not max_completion_tokens
        LibraryAssert.IsTrue(Payload.Get('max_tokens', Token), 'Payload should contain max_tokens for standard models.');
        LibraryAssert.AreEqual(500, Token.AsValue().AsInteger(), 'max_tokens should be 500.');
        LibraryAssert.IsFalse(Payload.Get('max_completion_tokens', Token), 'Payload should not contain max_completion_tokens for standard models.');
    end;

    [Test]
    procedure TestChatCompletionParamsGetSetReasoningEffort()
    var
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
    begin
        // [SCENARIO] GetReasoningEffort returns what was set

        // [GIVEN] Default params - reasoning effort not set (ordinal 0)
        LibraryAssert.AreEqual(0, AOAIChatCompletionParams.GetReasoningEffort().AsInteger(), 'Default reasoning effort should be unset (ordinal 0).');

        // [WHEN] ReasoningEffort is set to High
        AOAIChatCompletionParams.SetReasoningEffort(Enum::"AOAI Reasoning Effort"::High);

        // [THEN] GetReasoningEffort returns High
        LibraryAssert.AreEqual(Enum::"AOAI Reasoning Effort"::High, AOAIChatCompletionParams.GetReasoningEffort(), 'GetReasoningEffort should return High.');
    end;
}