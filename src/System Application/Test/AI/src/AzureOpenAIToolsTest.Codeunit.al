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
}